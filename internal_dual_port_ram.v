`timescale 1ns / 1ps

module true_dual_port_ram #(
    parameter DATA_WIDTH = 8,      // Data bits per word
    parameter ADDR_WIDTH = 8       // Address bits (=> 256 locations)
)(
    input                      clk,        // Common clock
    // Port A
    input                      we_a,       // Write enable for port A
    input  [ADDR_WIDTH-1:0]    addr_a,     // Address for port A
    input  [DATA_WIDTH-1:0]    din_a,      // Input data for port A
    output reg [DATA_WIDTH-1:0] dout_a,    // Output data for port A
    // Port B
    input                      we_b,       // Write enable for port B
    input  [ADDR_WIDTH-1:0]    addr_b,     // Address for port B
    input  [DATA_WIDTH-1:0]    din_b,      // Input data for port B
    output reg [DATA_WIDTH-1:0] dout_b,    // Output data for port B
    // Collision flag
    output reg                 collision   // High if both ports write same address
);

    // Internal memory array (shared by both ports)
    reg [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];

always @(posedge clk) begin
    collision <= 0;

    // --------------------------
    // Port A
    // --------------------------
    if (we_a) begin
        mem[addr_a] <= din_a;
        dout_a <= din_a;          // WRITE-FIRST behavior
    end else begin
        dout_a <= mem[addr_a];
    end

    // --------------------------
    // Port B
    // --------------------------
    if (we_b) begin
        mem[addr_b] <= din_b;
        dout_b <= din_b;          // WRITE-FIRST behavior
    end else begin
        dout_b <= mem[addr_b];
    end

    // --------------------------
    // Collision Detection
    // --------------------------
    if (we_a && we_b && (addr_a == addr_b)) begin
        collision <= 1'b1;
    end
end


endmodule


//Done