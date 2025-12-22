`timescale 1ns / 1ps
//===================================================================
// FLAG REGISTER
//===================================================================
// Description:
//  - Stores ALU-generated flags (CY, ACY, ZERO, SIGN, PARITY)
//  - Updates only when triggered (update = 1)
//  - Provides stable flag outputs to controller for decision-making
//===================================================================

module flag_register (
    input  wire clk,           // System clock
    input  wire reset,         // Active high reset
    input  wire update,        // Pulse high to latch new ALU flags

    // ---- Flags from ALU ----
    input  wire cy_in,         // Carry flag
    input  wire acy_in,        // Auxiliary carry flag
    input  wire zero_in,       // Zero flag
    input  wire sgn_in,        // Sign flag
    input  wire parity_in,     // Parity flag

    // ---- Latched outputs to controller ----
    output reg cy,             // Carry flag output
    output reg acy,            // Auxiliary carry flag output
    output reg zero,           // Zero flag output
    output reg sgn,            // Sign flag output
    output reg parity          // Parity flag output
);

    // Sequential logic for flag latching
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
