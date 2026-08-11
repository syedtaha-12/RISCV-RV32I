module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_op,
    output logic [31:0] alu_out,
    output logic        zero
);

    localparam logic [3:0] ALU_ADD  = 4'b0000;
    localparam logic [3:0] ALU_SUB  = 4'b0001;
    localparam logic [3:0] ALU_AND  = 4'b0010;
    localparam logic [3:0] ALU_OR   = 4'b0011;
    localparam logic [3:0] ALU_XOR  = 4'b0100;
    localparam logic [3:0] ALU_SLL  = 4'b0101;
    localparam logic [3:0] ALU_SRL  = 4'b0110;
    localparam logic [3:0] ALU_SRA  = 4'b0111;
    localparam logic [3:0] ALU_SLT  = 4'b1000;
    localparam logic [3:0] ALU_SLTU = 4'b1001;

    always_comb begin
        case (alu_op)

            ALU_ADD: begin
                alu_out = a + b;
            end

            ALU_SUB: begin
                alu_out = a - b;
            end

            ALU_AND: begin
                alu_out = a & b;
            end

            ALU_OR: begin
                alu_out = a | b;
            end

            ALU_XOR: begin
                alu_out = a ^ b;
            end

            ALU_SLL: begin
                alu_out = a << b[4:0];
            end

            ALU_SRL: begin
                alu_out = a >> b[4:0];
            end

            ALU_SRA: begin
                alu_out = $signed(a) >>> b[4:0];
            end

            ALU_SLT: begin
                alu_out = {
                    31'b0,
                    $signed(a) < $signed(b)
                };
            end

            ALU_SLTU: begin
                alu_out = {
                    31'b0,
                    a < b
                };
            end

            default: begin
                alu_out = 32'b0;
            end

        endcase
    end

    assign zero = (alu_out == 32'b0);

endmodule