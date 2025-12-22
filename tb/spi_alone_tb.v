`timescale 1ns / 1ps
`include"spi_master.v"
`include"revised_slave_spi.v"
module spi_alone_tb;

    reg clk;
    reg reset;
    reg start;
    reg [7:0] master_tx;
    wire [7:0] master_rx;
    wire busy, done;

    wire CS, SCLK, MOSI, MISO;
    reg  [7:0] slave_tx;
    wire [7:0] slave_rx;
    wire rx_ready;

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // DUTs
    spi_master dut_master (
        .clk(clk),
        .reset(reset),
        .data_in(master_tx),
        .start(start),
        .CS(CS),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .data_out(master_rx),
        .busy(busy),
        .done(done)
    );

    spi_slave dut_slave (
        .clk(clk),
        .reset(reset),
        .CS(CS),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .data_out(slave_rx),
        .data_in(slave_tx),
        .rx_ready(rx_ready)
    );

    initial begin
        $display("======================================");
        $display("   SPI MASTER + SLAVE STANDALONE TEST");
        $display("======================================");

        reset = 1;
        start = 0;
        master_tx = 8'h00;
        slave_tx  = 8'h00;

        #50;
        reset = 0;

        // TEST
        master_tx = 8'hA5;
        slave_tx  = 8'h3C;

        $display("\n[TEST 1] Master TX = A5, Slave TX = 3C");

        // ---- CRITICAL FIX ----
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // ---- WAIT FOR DONE CLEANLY ----
        @(posedge done);

        $display("Slave RX = %02h", slave_rx);
        $display("Master RX = %02h", master_rx);

        if (slave_rx == 8'hA5 && master_rx == 8'h3C)
            $display(">>> TEST PASSED");
        else
            $display(">>> TEST FAILED");

        #50;
        $finish;
    end

endmodule
