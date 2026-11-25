

.text
p62_main:
    addi sp, sp, -32
    sw ra, 28(sp)
    sw s0, 24(sp)
    sw s1, 20(sp)
    sw s2, 16(sp)
    sw s3, 12(sp)
    sw s4, 8(sp)


    # Read L
    call rcv_read_dec
    mv s0, a0

    # Read C
    call rcv_read_dec
    mv s1, a0

        # Save the previous interrupt handler
    csrr t0, mtvec
    sw t0, 0(sp)

    # Install the P62 interrupt handler
    la t0, p62_handler
    csrw mtvec, t0
        # Enable timer interrupt in IRQ mask
    li t0, IRQ_MASK
    li t1, 1
    sw t1, 0(t0)

    # Clear interrupt latency meter
    li t0, IRQLAT_CLEAR
    sw t1, 0(t0)

    # Enable machine interrupts
    csrsi mstatus, 8
        # Initialize round number and comparison value
    li s2, 1
    mv s3, s1

p62_round:
    # Reset interrupt counter
    la t0, p62_irq_count
    sw zero, 0(t0)

    # Stop and reset timer
    li t0, TIMER_CTRL
    sw zero, 0(t0)

    li t0, TIMER_COUNT
    sw zero, 0(t0)

    # Set timer comparison value
    li t0, TIMER_CMP
    sw s3, 0(t0)

    # Configure DMA source
    li t0, DMA_SRC
    la t1, p62_src
    sw t1, 0(t0)

    # Configure DMA destination
    li t0, DMA_DST
    la t1, p62_dst
    sw t1, 0(t0)

    # Set DMA length
    li t0, DMA_LEN
    sw s0, 0(t0)
        # Prepare timer and DMA control registers
    li t0, TIMER_CTRL
    li t1, 3
    li t2, DMA_CTRL
    li t3, 1

    # Start timer and DMA together
    sw t1, 0(t0)
    sw t3, 0(t2)

    # Wait for timer interrupt
p62_wait:
    la t0, p62_irq_count
    lw t1, 0(t0)
    beqz t1, p62_wait

    # Clear DMA status
    li t0, DMA_STATUS
    li t1, 1
    sw t1, 0(t0)

    # Read measured interrupt latency
    li t0, IRQLAT_LAST
    lw s4, 0(t0)
    
    # Print round number
    la a0, p62_round_msg
    call rcv_puts

    mv a0, s2
    call rcv_print_dec

    # Print comparison value
    la a0, p62_cmp_msg
    call rcv_puts

    mv a0, s3
    call rcv_print_dec

    # Print measured latency
    la a0, p62_latency_msg
    call rcv_puts

    mv a0, s4
    call rcv_print_dec

    call rcv_newline

    # Move to the next round
    addi s2, s2, 1
    add s3, s3, s1

    # Repeat for five rounds
    li t0, 6
    blt s2, t0, p62_round
    
    # Disable machine interrupts
    csrci mstatus, 8

    # Stop the timer
    li t0, TIMER_CTRL
    sw zero, 0(t0)

    # Disable timer interrupt
    li t0, IRQ_MASK
    sw zero, 0(t0)

    # Restore original interrupt handler
    lw t0, 0(sp)
    csrw mtvec, t0

    # Print maximum latency
    la a0, p62_max_msg
    call rcv_puts

    li t0, IRQLAT_MAX
    lw a0, 0(t0)
    call rcv_print_dec

    call rcv_newline



    # Initialize interrupt counter
    la t0, p62_irq_count
    sw zero, 0(t0)

        # Restore saved registers
    lw s4, 8(sp)
    lw s3, 12(sp)
    lw s2, 16(sp)
    lw s1, 20(sp)
    lw s0, 24(sp)
    lw ra, 28(sp)
    addi sp, sp, 32
    ret
    
    # Timer interrupt handler
    .align 2
p62_handler:
    addi sp, sp, -16
    sw t0, 12(sp)
    sw t1, 8(sp)

    # Stop the timer
    li t0, TIMER_CTRL
    sw zero, 0(t0)

    # Record the interrupt
    la t0, p62_irq_count
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)

    # Restore temporary registers
    lw t1, 8(sp)
    lw t0, 12(sp)
    addi sp, sp, 16

    # Return from interrupt
    mret
    
    
.rodata

p62_round_msg:
    .asciz "round "

p62_cmp_msg:
    .asciz ": cmp="

p62_latency_msg:
    .asciz " latency="

p62_max_msg:
    .asciz "max latency: "

.align 2

.data
.align 2

p62_irq_count:
    .word 0

p62_src:
    .space 400

p62_dst:
    .space 400

  
