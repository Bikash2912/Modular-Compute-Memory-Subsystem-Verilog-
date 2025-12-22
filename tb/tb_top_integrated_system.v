`timescale 1ns / 1ps
`include "top_integrated_system.v"

module tb_top_integrated_system;

    localparam DATA_WIDTH     = 8;
    localparam ADDR_WIDTH_EXT = 20;

    reg clk = 0;
    reg reset;
    always #5 clk = ~clk;

    // CPU interface
    reg we, re;
    reg alu_start;
    reg [3:0] alu_op;
    reg alu_to_external;
    reg [ADDR_WIDTH_EXT-1:0] addr;
    reg [DATA_WIDTH-1:0] data_in;

    wire [DATA_WIDTH-1:0] data_out;
    wire busy, done;

    top_integrated_system dut (
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
        .current_addr_wire(),
        .current_data_wire()
    );

    initial begin
        $dumpfile("top_system.vcd");
        $dumpvars(0, tb_top_integrated_system);
    end

    task wait_done;
        begin
            @(posedge clk);
            while (!done) @(posedge clk);
            @(posedge clk);
        end
    endtask

    initial begin
        we = 0; re = 0;
        alu_start = 0;
        alu_op = 0;
        alu_to_external = 0;
        addr = 0;
        data_in = 0;

        reset = 1;
        #40 reset = 0;

        // TEST A: Internal RAM
        addr = 8'h10;
        data_in = 8'h55;
        we = 1; #10 we = 0;
        wait_done();

        addr = 8'h10;
        re = 1; #10 re = 0;
        wait_done();

        $display("INT READ = %02h (expected 55)", data_out);

        // TEST B: External memory (stub)
        addr = 20'h00100;
        data_in = 8'hAA;
        we = 1; #10 we = 0;
        wait_done();

        addr = 20'h00100;
        re = 1; #10 re = 0;
        wait_done();

        $display("SPI READ = %02h (expected AA)", data_out);

        // TEST C: ALU internal
        dut.internal_ram.mem[8'h00] = 8'h05;
        dut.internal_ram.mem[8'h01] = 8'h0A;

        alu_op = 4'h0;
        alu_to_external = 0;
        alu_start = 1; #10 alu_start = 0;
        wait_done();

        $display("ALU RESULT = %02h (expected 0F)",
                 dut.internal_ram.mem[8'h02]);

        // TEST D: ALU → External (stub)
        dut.internal_ram.mem[8'h00] = 8'h03;
        dut.internal_ram.mem[8'h01] = 8'h04;

        alu_to_external = 1;
        alu_start = 1; #10 alu_start = 0;
        wait_done();

        $display("EXT DATA = 07 (expected 07)",
                 dut.ext_mem[dut.sp_inst.addr_out[7:0]]);

        $display("\nALL TESTS COMPLETED");
        #50 $finish;
    end
    // Safety timeout

    initial begin
        #3_000_000;
        $display(">>> SIMULATION TIMEOUT");
        $finish;
    end

endmodule

