`timescale 1ns / 1ps

module stack_pointer #(
    parameter ADDR_WIDTH = 20,       
    parameter STACK_BASE = 20'h00000 
)(
    input  wire clk,                 
    input  wire reset,                 
    input  wire push,                 
    input  wire pop,                 
    output reg [ADDR_WIDTH-1:0] addr_out 
);

    reg [ADDR_WIDTH-1:0] sp_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sp_reg <= STACK_BASE;  
        end 
        else begin
            if (push) begin
                sp_reg <= sp_reg + 1'b1; 
            end
            else if (pop) begin
                sp_reg <= sp_reg - 1'b1; 
            end
        end
    end

    always @(*) begin
        addr_out = sp_reg;
    end

endmodule

