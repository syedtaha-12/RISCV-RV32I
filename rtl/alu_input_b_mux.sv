module alu_input_b_mux (
    input logic [31:0] rs2,
    input logic [31:0] imm,
    input logic alu_src,
    output logic [31:0] out
);

    always_comb begin
        case (alu_src)
            1'b0: out = rs2;
            1'b1: out = imm;

            default: out = rs2;
        endcase
    end

endmodule
