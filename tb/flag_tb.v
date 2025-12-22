`include"stack_pointer.v"
`timescale 1ns / 1ps

module stack_pointer_tb;

    reg clk, reset;
    reg push, pop;
    wire [19:0] addr_out;

    stack_pointer #(
        .ADDR_WIDTH(20),
        .STACK_BASE(20'h00000)
    ) dut (
        .clk(clk),
        .reset(reset),
        .push(push),
        .pop(pop),
        .addr_out(addr_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        push = 0;
        pop = 0;

        #20 reset = 0;

        // -------------------------------
        $display("\n[TEST 1] After reset");
        #10;
        $display("SP = %05h (expected 00000)", addr_out);

        // -------------------------------
        $display("\n[TEST 2] Push 1");
        push = 1; #10 push = 0;
        #10;
        $display("SP = %05h (expected 00001)", addr_out);

        // -------------------------------
        $display("\n[TEST 3] Push 2");
        push = 1; #10 push = 0;
        #10;
        $display("SP = %05h (expected 00002)", addr_out);

        // -------------------------------
        $display("\n[TEST 4] Pop");
        pop = 1; #10 pop = 0;
        #10;
        $display("SP = %05h (expected 00001)", addr_out);

        $display("\nSTACK POINTER TEST COMPLETED");
        #20 $finish;
    end

endmodule

