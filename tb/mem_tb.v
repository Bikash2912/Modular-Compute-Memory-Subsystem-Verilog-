`timescale 1ns / 1ps
`include "mem_control_dualport.v"
`include "internal_dual_port_ram.v"

module mem_controller_tb;

    localparam DATA_WIDTH = 8;
    localparam ADDR_INT   = 8;
    localparam ADDR_EXT   = 20;

    reg clk = 0;
    reg reset;

    always #5 clk = ~clk;

    // CPU INTERFACE
    reg  we, re;
    reg  alu_start;
    reg  [3:0] alu_op;
    reg  alu_to_external;
    reg  [ADDR_EXT-1:0] addr;
    reg  [DATA_WIDTH-1:0] data_in;

    wire [DATA_WIDTH-1:0] data_out;
    wire busy, done;

    // INTERNAL RAM WIRES
    wire        we_int;
    wire        re_int;
    wire [7:0]  addr_int;
    wire [7:0]  din_int;
    wire [7:0]  dout_int;

    // SPI STUB WIRES
    wire spi_we, spi_re;
    wire [ADDR_EXT-1:0] spi_addr;
    wire [DATA_WIDTH-1:0] spi_din;
    reg  [DATA_WIDTH-1:0] spi_dout;
    reg  spi_done;
    reg  spi_busy;

    // ALU STUB WIRES
    wire alu_enable;
    wire [3:0] alu_opcode;
    wire [DATA_WIDTH-1:0] alu_in_a, alu_in_b;
    reg  [DATA_WIDTH-1:0] alu_out;
    reg  alu_done;

    // STACK POINTER
    reg [ADDR_EXT-1:0] sp_addr;


task wait_for_op;
begin
    // wait until operation starts
    @(posedge clk);
    while (busy == 0)
        @(posedge clk);

    // wait until operation finishes
    while (busy == 1)
        @(posedge clk);

    // one extra cycle for safety
    @(posedge clk);
end
endtask

    // RAM
    true_dual_port_ram ram_inst (
        .clk(clk),
        .we_a(we_int),
        .addr_a(addr_int),
        .din_a(din_int),
        .dout_a(dout_int),
        .we_b(1'b0),
        .addr_b(8'd0),
        .din_b(8'd0),
        .dout_b(),
        .collision()
    );

    // DUT
    memory_controller dut (
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
        .spi_addr(spi_addr),
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

        .alu_cy(0),
        .alu_zero(0),
        .alu_sgn(0),
        .alu_parity(0),

        .sp_addr(sp_addr)
    );

    // SPI STUB (TIMING-CORRECT)
reg spi_pending;

always @(posedge clk) begin
    spi_done <= 0;

    if (reset) begin
        spi_pending <= 0;
        spi_busy    <= 0;
    end else begin
        if (spi_re && !spi_pending) begin
            spi_pending <= 1;
            spi_busy    <= 1;
        end
        else if (spi_pending) begin
            spi_dout    <= 8'hAA;
            spi_done    <= 1;
            spi_busy    <= 0;
            spi_pending <= 0;
        end
    end
end


    // ALU STUB (1-CYCLE LATENCY)
reg alu_pending;

always @(posedge clk) begin
    alu_done <= 0;

    if (reset) begin
        alu_pending <= 0;
    end else begin
        if (alu_enable && !alu_pending) begin
            alu_pending <= 1;
        end
        else if (alu_pending) begin
            alu_out  <= alu_in_a + alu_in_b;
            alu_done <= 1;
            alu_pending <= 0;
        end
    end
end


    // TEST SEQUENCE
    initial begin
        reset = 1;
        we = 0; re = 0; alu_start = 0;
        alu_op = 0; alu_to_external = 0;
        addr = 0; data_in = 0;
        spi_busy = 0; spi_done = 0;
        sp_addr = 20'h100;

        #20 reset = 0;

        // ===============================
        // TEST A: INTERNAL RAM
        // ===============================
        addr = 8'h10; data_in = 8'h55; we = 1;
        #10 we = 0;
        wait_for_op;

        addr = 8'h10; re = 1;
        #10 re = 0;
        wait_for_op;

        $display("INT READ = %02h (expected 55)", data_out);

        // ===============================
        // TEST B: SPI MEMORY
        // ===============================
        addr = 20'h1000; re = 1;
        #10 re = 0;
        wait_for_op;

        $display("SPI READ = %02h (expected AA)", data_out);

        // ===============================
        // TEST C: ALU ADD
        // ===============================
        ram_inst.mem[8'h00] = 8'h05;
        ram_inst.mem[8'h01] = 8'h0A;

        alu_op = 4'h0;
        alu_start = 1;
        #10 alu_start = 0;
        wait_for_op;

        $display("ALU RESULT = %02h (expected 0F)", ram_inst.mem[8'h02]);

        $display("\nALL TESTS COMPLETED");
        #20 $finish;
    end

endmodule


////DONE
