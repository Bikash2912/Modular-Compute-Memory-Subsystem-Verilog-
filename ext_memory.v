`timescale 1ns / 1ps
`include "revised_slave_spi.v"

module external_memory_interface #(
    parameter ADDR_WIDTH_EXT = 17,          // 128 KB = 2^17
    parameter DATA_WIDTH     = 8,
    parameter MEM_DEPTH      = 1 << 17
)(
    input  wire clk,
    input  wire reset,

    // SPI signals
    input  wire CS,
    input  wire SCLK,
    input  wire MOSI,
    output wire MISO,

    // Debug
    output reg [ADDR_WIDTH_EXT-1:0] current_addr,
    output reg [DATA_WIDTH-1:0]     current_data
);

    // External memory
    reg [DATA_WIDTH-1:0] ext_mem [0:MEM_DEPTH-1];

    // SPI slave wires
    wire [7:0] spi_rx_data;
    wire       rx_ready;

    reg  [7:0] tx_buffer;

    // Address register
    reg [ADDR_WIDTH_EXT-1:0] addr_reg;
    reg                      addr_received;

    // SPI Slave Instance
    spi_slave u_spi_slave (
        .clk(clk),
        .reset(reset),
        .CS(CS),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .data_out(spi_rx_data),
        .data_in(tx_buffer),
        .rx_ready(rx_ready)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            addr_reg      <= 0;
            addr_received <= 0;
            tx_buffer     <= 8'h00;
            current_addr  <= 0;
            current_data  <= 0;
        end else begin
            if (!CS) begin
                if (rx_ready) begin
                    if (!addr_received) begin
                        addr_reg      <= spi_rx_data;
                        current_addr  <= spi_rx_data;
                        addr_received <= 1'b1;

                        tx_buffer     <= ext_mem[spi_rx_data];
                    end else begin
                        ext_mem[addr_reg] <= spi_rx_data;
                        current_data      <= spi_rx_data;
                        addr_received     <= 1'b0;
                    end
                end
            end else begin
                addr_received <= 1'b0;
            end
        end
    end

endmodule

