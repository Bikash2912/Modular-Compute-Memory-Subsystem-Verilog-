// `timescale 1ns / 1ps
`include"stack_pointer.v"
// module flag_register_tb;

//     reg clk, reset, update;
//     reg cy_in, acy_in, zero_in, sgn_in, parity_in;
//     wire cy, acy, zero, sgn, parity;

//     // DUT
//     flag_register dut (
//         .clk(clk),
//         .reset(reset),
//         .update(update),
//         .cy_in(cy_in),
//         .acy_in(acy_in),
//         .zero_in(zero_in),
//         .sgn_in(sgn_in),
//         .parity_in(parity_in),
//         .cy(cy),
//         .acy(acy),
//         .zero(zero),
//         .sgn(sgn),
//         .parity(parity)
//     );

//     always #5 clk = ~clk;

//     initial begin
//         clk = 0;
//         reset = 1;
//         update = 0;
//         {cy_in, acy_in, zero_in, sgn_in, parity_in} = 0;

//         #20 reset = 0;

//         // -------------------------------
//         $display("\n[TEST 1] Reset behavior");
//         #10;
//         $display("Flags = %b%b%b%b%b (expected 00000)",
//                  cy, acy, zero, sgn, parity);

//         // -------------------------------
//         $display("\n[TEST 2] Update flags");
//         {cy_in, acy_in, zero_in, sgn_in, parity_in} = 5'b10110;
//         update = 1;
//         #10 update = 0;
//         #10;
//         $display("Flags = %b%b%b%b%b (expected 10110)",
//                  cy, acy, zero, sgn, parity);

//         // -------------------------------
//         $display("\n[TEST 3] Hold without update");
//         {cy_in, acy_in, zero_in, sgn_in, parity_in} = 5'b01001;
//         #20;
//         $display("Flags = %b%b%b%b%b (expected 10110)",
//                  cy, acy, zero, sgn, parity);

//         // -------------------------------
//         $display("\n[TEST 4] Update again");
//         update = 1;
//         #10 update = 0;
//         #10;
//         $display("Flags = %b%b%b%b%b (expected 01001)",
//                  cy, acy, zero, sgn, parity);

//         $display("\nFLAG REGISTER TEST COMPLETED");
//         #20 $finish;
//     end

// endmodule

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
