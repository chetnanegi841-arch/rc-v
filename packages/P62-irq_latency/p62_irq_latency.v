 
module p62_irq_latency (
    input wire clk,
    input wire rst,
    input wire sel,
    input wire we,
    input wire re,
    input wire [3:0] ridx,
    input wire [31:0] wdata,
    output reg [31:0] rdata,
    input wire irq_line,
    input wire trap_irq
);

    reg [31:0] last_latency;
    reg [31:0] max_latency;
    reg [31:0] count;
    reg [31:0] wait_cycles;

    // Update measurements on each rising clock edge.
    always @(posedge clk) begin
        if (rst) begin
            last_latency <= 0;
            max_latency <= 0;
            count <= 0;
            wait_cycles <= 0;
        end
        else if (sel && we && ridx == 4'd2) begin
            // CLEAR register resets measurements.
            last_latency <= 0;
            max_latency <= 0;
            count <= 0;
            wait_cycles <= 0;
        end
        else if (trap_irq) begin
            // The CPU has accepted an interrupt.
            if (irq_line) begin
                last_latency <= wait_cycles + 1;
                if (wait_cycles + 1 > max_latency)
                    max_latency <= wait_cycles + 1;
                count <= count + 1;
            end
            wait_cycles <= 0;
        end
        else if (irq_line) begin
            wait_cycles <= wait_cycles + 1;
        end
        else begin
            wait_cycles <= 0;
        end
    end

    // Read the device registers.
    always @(*) begin
        case (ridx)
            4'd0: rdata = last_latency;
            4'd1: rdata = max_latency;
            4'd2: rdata = 32'd0;
            4'd3: rdata = count;
            4'd15: rdata = 32'd62;
            default: rdata = 32'd0;
        endcase
    end

endmodule
