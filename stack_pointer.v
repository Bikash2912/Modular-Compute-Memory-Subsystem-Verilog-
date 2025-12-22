`timescale 1ns / 1ps
//===================================================================
// STACK POINTER MODULE
//===================================================================
// Description:
//  - Acts as an auto-increment counter for external memory writes
//  - Used when ALU results are pushed sequentially into external SPI memory
//  - Provides a "stack-like" result storage system
//===================================================================

module stack_pointer #(
    parameter ADDR_WIDTH = 20,         // Matches external memory address width
    parameter STACK_BASE = 20'h00000   // Starting address of external result stack
)(
    input  wire clk,                   // System clock
    input  wire reset,                 // Asynchronous reset
    input  wire push,                  // Increment trigger (on ALU write)
    input  wire pop,                   // (Optional) Decrement trigger (for future use)
    output reg [ADDR_WIDTH-1:0] addr_out // Current top-of-stack address
);

    // Internal counter register
    reg [ADDR_WIDTH-1:0] sp_reg;

    // Sequential logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sp_reg <= STACK_BASE;      // Reset to base stack address
        end 
        else begin
            if (push) begin
                sp_reg <= sp_reg + 1'b1; // Increment stack pointer
            end
            else if (pop) begin
                sp_reg <= sp_reg - 1'b1; // Optional (for later expansion)
            end
        end
    end

    // Output assignment
    always @(*) begin
        addr_out = sp_reg;
    end

endmodule
