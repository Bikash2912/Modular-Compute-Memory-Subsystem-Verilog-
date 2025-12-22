`timescale 1ns / 1ps
`include"internal_dual_port_ram.v"
module tb_true_dual_port_ram;

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 8;

    reg clk;

    // Port A
    reg we_a;
    reg [ADDR_WIDTH-1:0] addr_a;
    reg [DATA_WIDTH-1:0] din_a;
    wire [DATA_WIDTH-1:0] dout_a;

    // Port B
    reg we_b;
    reg [ADDR_WIDTH-1:0] addr_b;
    reg [DATA_WIDTH-1:0] din_b;
    wire [DATA_WIDTH-1:0] dout_b;

    wire collision;

    // DUT
    true_dual_port_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .we_a(we_a),
        .addr_a(addr_a),
        .din_a(din_a),
        .dout_a(dout_a),
        .we_b(we_b),
        .addr_b(addr_b),
        .din_b(din_b),
        .dout_b(dout_b),
        .collision(collision)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("\n=================================");
        $display(" TRUE DUAL PORT RAM TESTBENCH");
        $display("=================================\n");

        // INIT
        we_a = 0; we_b = 0;
        addr_a = 0; addr_b = 0;
        din_a = 0; din_b = 0;

        // -------------------------------
        // TEST A1: Single write/read
        // -------------------------------
        $display("[A1] Write 0x55 to addr 0x10 via Port A");
        @(posedge clk);
        we_a = 1;
        addr_a = 8'h10;
        din_a = 8'h55;

        @(posedge clk);
        we_a = 0;

        // READ (wait 1 cycle!)
        @(posedge clk);
        addr_a = 8'h10;

        @(posedge clk);
        $display("Read = %02h (expected 55)", dout_a);

        // -------------------------------
        // TEST A2: Multiple writes
        // -------------------------------
        $display("\n[A2] Multiple writes");
        @(posedge clk);
        we_a = 1; addr_a = 8'h01; din_a = 8'h11;
        @(posedge clk);
        addr_a = 8'h02; din_a = 8'h22;
        @(posedge clk);
        addr_a = 8'h03; din_a = 8'h33;
        @(posedge clk);
        we_a = 0;

        // READ BACK
        @(posedge clk) addr_a = 8'h01;
        @(posedge clk) $display("[01] = %02h (expected 11)", dout_a);

        @(posedge clk) addr_a = 8'h02;
        @(posedge clk) $display("[02] = %02h (expected 22)", dout_a);

        @(posedge clk) addr_a = 8'h03;
        @(posedge clk) $display("[03] = %02h (expected 33)", dout_a);

        // -------------------------------
        // TEST B1: Simultaneous read
        // -------------------------------
        $display("\n[B1] Simultaneous read A & B");
        @(posedge clk);
        addr_a = 8'h10;
        addr_b = 8'h10;

        @(posedge clk);
        $display("A=%02h B=%02h (expected 55,55)", dout_a, dout_b);

        // -------------------------------
        // TEST B2: Simultaneous write different addr
        // -------------------------------
        $display("\n[B2] Simultaneous write diff addr");
        @(posedge clk);
        we_a = 1; addr_a = 8'h20; din_a = 8'hAA;
        we_b = 1; addr_b = 8'h21; din_b = 8'hBB;

        @(posedge clk);
        we_a = 0; we_b = 0;

        @(posedge clk) addr_a = 8'h20;
        @(posedge clk) $display("[20] = %02h (expected AA)", dout_a);

        @(posedge clk) addr_b = 8'h21;
        @(posedge clk) $display("[21] = %02h (expected BB)", dout_b);

        // -------------------------------
        // TEST B3: Collision
        // -------------------------------
        $display("\n[B3] Collision test");
        @(posedge clk);
        we_a = 1; addr_a = 8'h30; din_a = 8'hCC;
        we_b = 1; addr_b = 8'h30; din_b = 8'hDD;

        @(posedge clk);
        we_a = 0; we_b = 0;

        @(posedge clk);
        $display("Collision = %b (expected 1)", collision);

        @(posedge clk) addr_a = 8'h30;
        @(posedge clk) $display("[30] = %02h (last writer wins)", dout_a);

        $display("\n=================================");
        $display(" RAM TEST COMPLETE");
        $display("=================================\n");

        $finish;
    end

endmodule


//Done