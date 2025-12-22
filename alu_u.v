module alu #(
    parameter size = 8
) (
    input wire [size-1:0] dataInA,
    input wire [size-1:0] dataInB,
    input wire [3:0] op,
    input wire cin,
    input wire inVisCin,
    output reg CY,
    output reg ACY,
    output reg SGN,
    output reg PARITY,
    output reg ZERO,
    output reg [size-1:0] dataOut
);

    wire [size:0] cout;
    reg [size-1:0] dataInA_temp;
    reg [size-1:0] dataInB_temp;
    reg cin_temp;
    wire [size-1:0] sum;
    reg [size-1:0] dataOut_temp;
    
    // Ripple-carry adder
    assign cout[0] = cin_temp;
    genvar i;
    generate
        for (i = 0; i < size; i = i + 1) begin : adder_loop
            assign sum[i] = dataInA_temp[i] ^ dataInB_temp[i] ^ cout[i];
            assign cout[i+1] = (dataInA_temp[i] & dataInB_temp[i]) | (dataInA_temp[i] & cout[i]) | (dataInB_temp[i] & cout[i]);
        end
    endgenerate

    integer j;

    // Main logic for operations
    always @(*) begin
        // Default assignments to avoid latches
        dataInA_temp = {size{1'b0}};
        dataInB_temp = {size{1'b0}};
        cin_temp = 1'b0;
        dataOut_temp = {size{1'b0}};
        ACY = 1'b0;
        CY = 1'b0;

        case (op)
            4'b0000: begin // ADD: A + B
                dataInA_temp = dataInA;
                dataInB_temp = dataInB;
                cin_temp = 1'b0;
                dataOut_temp = sum;
                ACY = cout[size/2];
                CY = cout[size];
            end
            4'b0001: begin // ADDC: A + B + cin
                dataInA_temp = dataInA;
                dataInB_temp = dataInB;
                cin_temp = cin;
                dataOut_temp = sum;
                ACY = cout[size/2];
                CY = cout[size];
            end
            4'b0010: begin // SUB: A - B
                dataInA_temp = dataInA;
                dataInB_temp = ~dataInB;
                cin_temp = 1'b1;
                dataOut_temp = sum;
                ACY = cout[size/2];
                CY = cout[size];
            end
            4'b0011: begin // SBB: A - B - cin
                dataInA_temp = dataInA;
                dataInB_temp = ~dataInB;
                cin_temp = ~cin;
                dataOut_temp = sum;
                ACY = cout[size/2];
                CY = cout[size];
            end
            4'b0100: begin // INC: B + 1
                dataInA_temp = {size{1'b0}};
                dataInB_temp = dataInB;
                cin_temp = 1'b1;
                dataOut_temp = sum;
                ACY = cout[size/2];
                CY = cout[size];
            end
            4'b0101: begin // DEC: B - 1
                dataInA_temp = dataInB;
                dataInB_temp = {size{1'b1}};
                cin_temp = 1'b1;
                dataOut_temp = sum;
                ACY = cout[size/2];
                CY = cout[size];
            end
            4'b0110: begin // AND: A and B
                dataOut_temp = dataInA & dataInB;
                ACY = 1'b0;
                CY = 1'b0;
            end
            4'b0111: begin // OR: A or B
                dataOut_temp = dataInA | dataInB;
                ACY = 1'b0;
                CY = 1'b0;
            end
            4'b1000: begin // XOR: A xor B
                dataOut_temp = dataInA ^ dataInB;
                ACY = 1'b0;
                CY = 1'b0;
            end
            4'b1001: begin // RLC: Rotate Left with Carry
                dataOut_temp = {dataInA[size-2:0], dataInA[size-1]};
                CY = dataInA[size-1];
                ACY = 1'b0;
            end
            4'b1010: begin // RRC: Rotate Right with Carry
                dataOut_temp = {dataInA[0], dataInA[size-1:1]};
                CY = dataInA[0];
                ACY = 1'b0;
            end
            4'b1011: begin // NOT A
                dataOut_temp = ~dataInA;
                ACY = 1'b0;
                CY = 1'b0;
            end
            4'b1100: begin // NOT CY
                dataOut_temp = {size{1'b0}};
                ACY = 1'b0;
                CY = ~cin;
            end
            4'b1101: begin // SET CY
                dataOut_temp = {size{1'b0}};
                ACY = 1'b0;
                CY = 1'b1;
            end
            4'b1110: begin // INX
                dataInA_temp = {size{1'b0}};
                dataInB_temp = dataInB;
                cin_temp = inVisCin;
                dataOut_temp = sum;
                ACY = 1'b0;
                CY = 1'b0;
            end
            4'b1111: begin // DCX
                dataInA_temp = dataInB;
                dataInB_temp = {size{1'b1}};
                cin_temp = inVisCin;
                dataOut_temp = sum;
                ACY = 1'b0;
                CY = 1'b0;
            end
            default: begin
                dataInA_temp = {size{1'b0}};
                dataInB_temp = {size{1'b0}};
                cin_temp = 1'b0;
                dataOut_temp = {size{1'b0}};
                ACY = 1'b0;
                CY = 1'b0;
            end
        endcase
    end

    // Assign final outputs
    always @(*) begin
        dataOut = dataOut_temp;
        SGN = dataOut_temp[size-1];
        PARITY = 1'b0;
        for (j = 0; j < size; j = j + 1) begin
            PARITY = PARITY ^ dataOut_temp[j];
        end

        // Calculate ZERO flag
        if (dataOut_temp == {size{1'b0}}) begin
            ZERO = 1'b1;
        end else begin
            ZERO = 1'b0;
        end
    end

endmodule 


/////Done