`timescale 1ns / 1ps

module true_dual_port_ram #(
    parameter DATA_WIDTH = 8,    
    parameter ADDR_WIDTH = 8       // => 256 locations
)(
    input                      clk,        
    // Port A
    input                      we_a,       
    input  [ADDR_WIDTH-1:0]    addr_a,    
    input  [DATA_WIDTH-1:0]    din_a,     
    output reg [DATA_WIDTH-1:0] dout_a,    
    // Port B
    input                      we_b,     
    input  [ADDR_WIDTH-1:0]    addr_b,    
    input  [DATA_WIDTH-1:0]    din_b,      
    output reg [DATA_WIDTH-1:0] dout_b,    
    // Collision flag
    output reg                 collision  
);

    reg [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];

always @(posedge clk) begin
    collision <= 0;

    // Port A
    if (we_a) begin
        mem[addr_a] <= din_a;
        dout_a <= din_a;         
    end else begin
        dout_a <= mem[addr_a];
    end

    // Port B
    if (we_b) begin
        mem[addr_b] <= din_b;
        dout_b <= din_b;          
    end else begin
        dout_b <= mem[addr_b];
    end

    // Collision Detection
    if (we_a && we_b && (addr_a == addr_b)) begin
        collision <= 1'b1;
    end
end


endmodule



//Done
