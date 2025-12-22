`timescale 1ns / 1ps

`include "internal_dual_port_ram.v"
`include "mem_control_dualport.v"
`include "alu_u.v"
`include "flag_dual.v"
`include "stack_pointer.v"

module top_integrated_system #(
    parameter DATA_WIDTH     = 8,
    parameter ADDR_WIDTH_INT = 8,
    parameter ADDR_WIDTH_EXT = 20
)(
    input  wire clk,
    input  wire reset,

    // CPU Interface
    input  wire we,
    input  wire re,
    input  wire alu_start,
    input  wire [3:0] alu_op,
    input  wire alu_to_external,
    input  wire [ADDR_WIDTH_EXT-1:0] addr,
    input  wire [DATA_WIDTH-1:0] data_in,

    output wire [DATA_WIDTH-1:0] data_out,
    output wire busy,
    output wire done,

    // Debug
    output wire [ADDR_WIDTH_EXT-1:0] current_addr_wire,
    output wire [DATA_WIDTH-1:0]     current_data_wire
);

    // =====================================================
    // Internal RAM signals
    // =====================================================
    wire we_int, re_int;
    wire [ADDR_WIDTH_INT-1:0] addr_int;
    wire [DATA_WIDTH-1:0] din_int, dout_int;

    // =====================================================
    // SPI (stubbed)
    // =====================================================
    wire [ADDR_WIDTH_EXT-1:0] spi_addr;   // FIX: must exist
    wire [DATA_WIDTH-1:0] spi_din, spi_dout;
    wire spi_we, spi_re;
    wire spi_busy, spi_done;

    // =====================================================
    // ALU
    // =====================================================
    wire alu_enable;
    wire [3:0] alu_opcode;
    wire [DATA_WIDTH-1:0] alu_in_a, alu_in_b;
    wire [DATA_WIDTH-1:0] alu_out;
    wire alu_done;

    // =====================================================
    // Flags
    // =====================================================
    wire CY, ACY, ZERO, SGN, PARITY;
    wire latched_cy, latched_acy, latched_zero, latched_sgn, latched_parity;

    // =====================================================
    // Stack Pointer
    // =====================================================
    wire [ADDR_WIDTH_EXT-1:0] sp_addr;

    // =====================================================
    // Internal RAM
    // =====================================================
    true_dual_port_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH_INT)
    ) internal_ram (
        .clk(clk),
        .we_a(we_int),
        .addr_a(addr_int),
        .din_a(din_int),
        .dout_a(dout_int),
        .we_b(1'b0),
        .addr_b({ADDR_WIDTH_INT{1'b0}}),
        .din_b({DATA_WIDTH{1'b0}}),
        .dout_b(),
        .collision()
    );

    // =====================================================
    // ALU
    // =====================================================
    alu #(.size(DATA_WIDTH)) alu_core (
        .dataInA(alu_in_a),
        .dataInB(alu_in_b),
        .op(alu_opcode),
        .cin(latched_cy),
        .inVisCin(1'b0),
        .CY(CY),
        .ACY(ACY),
        .ZERO(ZERO),
        .SGN(SGN),
        .PARITY(PARITY),
        .dataOut(alu_out)
    );

    // =====================================================
    // Flag Register
    // =====================================================
    flag_register flag_reg (
        .clk(clk),
        .reset(reset),
        .update(alu_done),
        .cy_in(CY),
        .acy_in(ACY),
        .zero_in(ZERO),
        .sgn_in(SGN),
        .parity_in(PARITY),
        .cy(latched_cy),
        .acy(latched_acy),
        .zero(latched_zero),
        .sgn(latched_sgn),
        .parity(latched_parity)
    );

    // =====================================================
    // Stack Pointer
    // =====================================================
    stack_pointer #(
        .ADDR_WIDTH(ADDR_WIDTH_EXT),
        .STACK_BASE(20'h00000)
    ) sp_inst (
        .clk(clk),
        .reset(reset),
        .push(alu_to_external),
        .pop(1'b0),
        .addr_out(sp_addr)
    );

    // =====================================================
    // MEMORY CONTROLLER
    // =====================================================
    memory_controller mem_ctrl (
        .clk(clk),
        .reset(reset),
        .we(we),
        .re(re),
        .alu_start(alu_start),
        .alu_op(alu_op),
        .alu_to_external(alu_to_external),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out),
        .busy(busy),
        .done(done),

        .we_int(we_int),
        .re_int(re_int),
        .addr_int(addr_int),
        .din_int(din_int),
        .dout_int(dout_int),

        .spi_we(spi_we),
        .spi_re(spi_re),
        .spi_addr(spi_addr),     // FIX: connected
        .spi_din(spi_din),
        .spi_dout(spi_dout),
        .spi_busy(spi_busy),
        .spi_done(spi_done),

        .alu_enable(alu_enable),
        .alu_opcode(alu_opcode),
        .alu_in_a(alu_in_a),
        .alu_in_b(alu_in_b),
        .alu_out(alu_out),
        .alu_done(alu_done),

        .alu_cy(latched_cy),
        .alu_zero(latched_zero),
        .alu_sgn(latched_sgn),
        .alu_parity(latched_parity),

        .sp_addr(sp_addr)
    );
        // wire [ADDR_WIDTH_EXT-1:0] spi_addr;

    // =====================================================
    // SPI STUB (TRANSACTION-LEVEL)
    // =====================================================
    reg [DATA_WIDTH-1:0] ext_mem [0:255];
    reg spi_done_r;
    reg [DATA_WIDTH-1:0] spi_dout_r;

    assign spi_done = spi_done_r;
    assign spi_dout = spi_dout_r;
    assign spi_busy = 1'b0;

    assign current_addr_wire = spi_addr;      // FIX: debug
    assign current_data_wire = spi_dout_r;    // FIX: debug
    assign alu_done = alu_enable;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            spi_done_r <= 0;
        end else begin
            spi_done_r <= 0;

            if (spi_we) begin
                ext_mem[spi_addr[7:0]] <= spi_din;
                spi_done_r <= 1;
            end

            if (spi_re) begin
                spi_dout_r <= ext_mem[spi_addr[7:0]];
                spi_done_r <= 1;
            end
        end
    end

endmodule
