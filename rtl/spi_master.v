
`timescale 1ns / 1ps
module spi_master #(
    parameter CLK_FREQ = 50_000_000,
    parameter SPI_FREQ = 1_000_000
)(
    input        clk,
    input        reset,
    input  [7:0] data_in,
    input        start,

    output reg   CS,
    output reg   SCLK,
    output reg   MOSI,
    input        MISO,

    output reg [7:0] data_out,
    output reg   busy,
    output reg   done
);

    localparam integer DIV = CLK_FREQ / (2*SPI_FREQ);

    reg [15:0] div_cnt;
    reg        tick;

    reg [7:0]  tx_shift;
    reg [7:0]  rx_shift;
    reg [2:0]  bit_cnt;
    reg        phase;   // 0 = rising edge, 1 = falling edge

    localparam IDLE=0, TRANSFER=1, FINISH=2;
    reg [1:0] state;

    // Clock divider
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            div_cnt <= 0;
            tick <= 0;
        end else begin
            if (div_cnt == DIV-1) begin
                div_cnt <= 0;
                tick <= 1;
            end else begin
                div_cnt <= div_cnt + 1;
                tick <= 0;
            end
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            CS <= 1;
            SCLK <= 0;
            MOSI <= 0;
            busy <= 0;
            done <= 0;
            state <= IDLE;
            bit_cnt <= 0;
            phase <= 0;
            rx_shift <= 0;
        end else begin
            case (state)

                IDLE: begin
                    CS <= 1;
                    SCLK <= 0;
                    busy <= 0;
                    done <= 0;
                    phase <= 0;
                    if (start) begin
                        CS <= 0;
                        busy <= 1;
                        tx_shift <= data_in;
                        MOSI <= data_in[7];
                        bit_cnt <= 3'd7;
                        state <= TRANSFER;
                    end
                end

                TRANSFER: begin
                    if (tick) begin
                        SCLK <= ~SCLK;
                        phase <= ~phase;

                        if (phase == 0) begin
                            // Rising edge: sample MISO
                            rx_shift[bit_cnt] <= MISO;
                        end else begin
                            // Falling edge: drive MOSI
                            if (bit_cnt != 0) begin
                                bit_cnt <= bit_cnt - 1;
                                MOSI <= tx_shift[bit_cnt-1];
                            end else begin
                                state <= FINISH;
                            end
                        end
                    end
                end

                FINISH: begin
                    CS <= 1;
                    busy <= 0;
                    done <= 1;
                    data_out <= {rx_shift[6:0], 1'b0};
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule




////Done
