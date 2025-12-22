`timescale 1ns / 1ps
module spi_slave (
    input        clk,        
    input        reset,      
    input        CS,         
    input        SCLK,       
    input        MOSI,       
    output reg   MISO,       
    output reg [7:0] data_out,
    input  [7:0] data_in,    
    output reg   rx_ready   
);

    reg [7:0] shift_in;      
    reg [7:0] shift_out;     
    reg [2:0] bit_cnt;       

    always @(negedge CS or posedge reset) begin
        if (reset) begin
            shift_in  <= 8'd0;
            shift_out <= 8'd0;
            bit_cnt   <= 3'd0;
            MISO      <= 1'b0;
            rx_ready  <= 1'b0;
        end else begin
            shift_out <= data_in;
            MISO      <= data_in[7]; 
            bit_cnt   <= 3'd0;
            rx_ready  <= 1'b0;
        end
    end

    // SPI Mode-0: sample MOSI on rising edge, update MISO on falling edge
    always @(posedge SCLK) begin
        if (!CS) begin
            shift_in <= {shift_in[6:0], MOSI};
            bit_cnt  <= bit_cnt + 1'b1;
            if (bit_cnt == 3'd7) begin
                data_out <= {shift_in[6:0], MOSI};
                rx_ready <= 1'b1;  // flag for controller
            end
        end
    end

    always @(negedge SCLK) begin
        if (!CS) begin
            MISO      <= shift_out[7];
            shift_out <= {shift_out[6:0], 1'b0};
        end
    end

endmodule


/////Done
