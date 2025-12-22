`timescale 1ns / 1ps

module memory_controller #(
    parameter ADDR_WIDTH_INT = 8,
    parameter ADDR_WIDTH_EXT = 20,
    parameter DATA_WIDTH     = 8
)(
    input  clk,
    input  reset,

    // CPU / top-level interface
    input  we,
    input  re,
    input  alu_start,
    input  [3:0] alu_op,
    input  alu_to_external,
    input  [ADDR_WIDTH_EXT-1:0] addr,
    input  [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg busy,
    output reg done,

    // Internal RAM
    output reg we_int,
    output reg re_int,
    output reg [ADDR_WIDTH_INT-1:0] addr_int,
    output reg [DATA_WIDTH-1:0] din_int,
    input      [DATA_WIDTH-1:0] dout_int,

    // SPI
    output reg spi_we,
    output reg spi_re,
    output reg [ADDR_WIDTH_EXT-1:0] spi_addr,
    output reg [DATA_WIDTH-1:0] spi_din,
    input      [DATA_WIDTH-1:0] spi_dout,
    input      spi_busy,
    input      spi_done,

    // ALU
    output reg alu_enable,
    output reg [3:0] alu_opcode,
    output reg [DATA_WIDTH-1:0] alu_in_a,
    output reg [DATA_WIDTH-1:0] alu_in_b,
    input      [DATA_WIDTH-1:0] alu_out,
    input      alu_done,

    // Flags (not used internally)
    input alu_cy,
    input alu_zero,
    input alu_sgn,
    input alu_parity,

    // Stack pointer
    input [ADDR_WIDTH_EXT-1:0] sp_addr
);

    // =========================================================
    // REQUEST LATCHES (STABLE FOR ENTIRE TRANSACTION)
    // =========================================================
    reg req_we, req_re;
    reg req_alu;
    reg [ADDR_WIDTH_EXT-1:0] req_addr;
    reg [DATA_WIDTH-1:0] req_data;
    reg [3:0] req_alu_op;
    reg req_alu_to_ext;

    localparam INT_MAX = 8'hFF;
    localparam INT_READ_WAIT = 5'd20;


    // ADD THESE STATES
    localparam ALU_FETCH_A_WAIT = 5'd14;
    localparam ALU_FETCH_B_WAIT = 5'd15;

    // =========================================================
    // FSM STATES
    // =========================================================
    localparam [4:0]
        IDLE            = 5'd0,

        INT_WRITE       = 5'd1,
        INT_READ_REQ    = 5'd2,
        INT_READ_CAP    = 5'd3,

        SPI_WRITE_REQ   = 5'd4,
        SPI_READ_REQ    = 5'd5,
        SPI_WAIT        = 5'd6,

        ALU_FETCH_A_REQ = 5'd7,
        ALU_FETCH_A_CAP = 5'd8,
        ALU_FETCH_B_REQ = 5'd9,
        ALU_FETCH_B_CAP = 5'd10,
        ALU_EXEC        = 5'd11,
        ALU_WRITEBACK   = 5'd12,

        COMPLETE        = 5'd31;

    reg [4:0] state;

    // =========================================================
    // FSM
    // =========================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            busy  <= 0;
            done  <= 0;

            we_int <= 0;
            re_int <= 0;
            spi_we <= 0;
            spi_re <= 0;
            alu_enable <= 0;

            data_out <= 0;

            req_we <= 0;
            req_re <= 0;
            req_alu <= 0;
        end else begin
            // defaults (safe deassert)
            we_int <= 0;
            re_int <= 0;
            spi_we <= 0;
            spi_re <= 0;
            alu_enable <= 0;
            done <= 0;

            case (state)

            // =====================================================
            IDLE: begin
                busy <= 0;

                if (alu_start) begin
                    req_alu        <= 1'b1;
                    req_alu_op     <= alu_op;
                    req_alu_to_ext <= alu_to_external;
                    busy <= 1;
                    state <= ALU_FETCH_A_REQ;
                end
                else if (we || re) begin
                    req_we   <= we;
                    req_re   <= re;
                    req_addr <= addr;
                    req_data <= data_in;
                    busy <= 1;

                    if (addr <= INT_MAX)
                        state <= we ? INT_WRITE : INT_READ_REQ;
                    else
                        state <= we ? SPI_WRITE_REQ : SPI_READ_REQ;
                end
            end

            // =====================================================
            // INTERNAL RAM
            // =====================================================
            INT_WRITE: begin
                addr_int <= req_addr[ADDR_WIDTH_INT-1:0];
                din_int  <= req_data;
                we_int   <= 1;
                state    <= COMPLETE;
            end

            INT_READ_REQ: begin
                addr_int <= req_addr[ADDR_WIDTH_INT-1:0];
                re_int   <= 1;
                state    <= INT_READ_WAIT;
            end

            INT_READ_WAIT: begin
                // wait 1 cycle for synchronous RAM
                state <= INT_READ_CAP;
            end

            INT_READ_CAP: begin
                data_out <= dout_int;
                state    <= COMPLETE;
            end


            // =====================================================
            // SPI
            // =====================================================
            SPI_WRITE_REQ: begin
                spi_addr <= req_addr;
                spi_din  <= req_data;
                spi_we   <= 1;
                state    <= SPI_WAIT;
            end

            SPI_READ_REQ: begin
                spi_addr <= req_addr;
                spi_re   <= 1;
                state    <= SPI_WAIT;
            end

            SPI_WAIT: begin
                if (spi_done) begin
                    if (req_re)
                        data_out <= spi_dout;
                    state <= COMPLETE;
                end
            end

            // =====================================================
            // ALU SEQUENCE (TIMING SAFE)
            // =====================================================
            ALU_FETCH_A_REQ: begin
                addr_int <= 8'h00;
                re_int   <= 1;
                state    <= ALU_FETCH_A_WAIT;
            end

            ALU_FETCH_A_WAIT: begin
                re_int <= 0;
                state  <= ALU_FETCH_A_CAP;
            end

            ALU_FETCH_A_CAP: begin
                alu_in_a <= dout_int;
                state    <= ALU_FETCH_B_REQ;
            end


            ALU_FETCH_B_REQ: begin
                addr_int <= 8'h01;
                re_int   <= 1;
                state    <= ALU_FETCH_B_WAIT;
            end

            ALU_FETCH_B_WAIT: begin
                re_int <= 0;
                state  <= ALU_FETCH_B_CAP;
            end

            ALU_FETCH_B_CAP: begin
                alu_in_b   <= dout_int;
                alu_opcode <= req_alu_op;
                alu_enable <= 1;
                state      <= ALU_EXEC;
            end


            ALU_EXEC: begin
                if (alu_done)
                    state <= ALU_WRITEBACK;
            end

            ALU_WRITEBACK: begin
                addr_int <= 8'h02;
                din_int  <= alu_out;
                we_int   <= 1;

                if (req_alu_to_ext) begin
                    spi_addr <= sp_addr;
                    spi_din  <= alu_out;
                    spi_we   <= 1;
                    state    <= SPI_WAIT;
                end else begin
                    state <= COMPLETE;
                end
            end

            // =====================================================
            COMPLETE: begin
                busy <= 0;
                done <= 1;

                // clear latched requests
                req_we  <= 0;
                req_re  <= 0;
                req_alu <= 0;

                state <= IDLE;
            end

            default: state <= IDLE;
            endcase
        end
    end

endmodule


////DONE