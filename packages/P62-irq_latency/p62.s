
.text
p62_main:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)

    # Read L
    call rcv_read_dec
    mv s0, a0

    # Read C
    call rcv_read_dec
    mv s1, a0

    # More program instructions will go here

    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

.rodata
p62_msg:
    .asciz "TODO\n"
    .align 2
  
