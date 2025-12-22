`timescale 1ns / 1ps

module flag_register (
    input  wire clk,          
    input  wire reset,        
    input  wire update,      

    input  wire cy_in,         
    input  wire acy_in,       
    input  wire zero_in,      
    input  wire sgn_in,       
    input  wire parity_in,   

    output reg cy,             
    output reg acy,          
    output reg zero,           
    output reg sgn,           
    output reg parity          
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cy      <= 1'b0;
            acy     <= 1'b0;
            zero    <= 1'b0;
            sgn     <= 1'b0;
            parity  <= 1'b0;
        end 
        else if (update) begin
            cy      <= cy_in;
            acy     <= acy_in;
            zero    <= zero_in;
            sgn     <= sgn_in;
            parity  <= parity_in;
        end
    end

endmodule

