// imm_gen.sv
// RV32I Immediate Generator
// Takes the full 32-bit instruction and produces the sign-extended
// 32-bit immediate value, along with a code identifying which
// instruction format it came from (I, S, B, U, J).

module imm_gen (
    input  logic [31:0] instr,
    output logic [31:0] imm_out,
    output logic [2:0]  imm_type   // 0=I, 1=S, 2=B, 3=U, 4=J
);

    logic [6:0] opcode;
    assign opcode = instr[6:0];

    always_comb begin
        // Default values
        imm_out  = 32'b0;
        imm_type = 3'b0;

        case (opcode)
            // ---------- I-type ----------
            // Used by: loads, ADDI/SLTI/etc, JALR
            7'b0000011, // LOAD
            7'b0010011, // OP-IMM
            7'b1100111: begin // JALR
                imm_out  = {{20{instr[31]}}, instr[31:20]};
                imm_type = 3'd0;
            end

            // ---------- S-type ----------
            // Used by: stores
            7'b0100011: begin // STORE
                imm_out  = {{20{instr[31]}}, instr[31:25], instr[11:7]};
                imm_type = 3'd1;
            end

            // ---------- B-type ----------
            // Used by: branches
            // Bits are scrambled and imm[0] is always 0
            7'b1100011: begin // BRANCH
                imm_out  = {{19{instr[31]}}, instr[31], instr[7],
                            instr[30:25], instr[11:8], 1'b0};
                imm_type = 3'd2;
            end

            // ---------- U-type ----------
            // Used by: LUI, AUIPC
            7'b0110111, // LUI
            7'b0010111: begin // AUIPC
                imm_out  = {instr[31:12], 12'b0};
                imm_type = 3'd3;
            end

            // ---------- J-type ----------
            // Used by: JAL
            // Bits are scrambled and imm[0] is always 0
            7'b1101111: begin // JAL
                imm_out  = {{11{instr[31]}}, instr[31], instr[19:12],
                            instr[20], instr[30:21], 1'b0};
                imm_type = 3'd4;
            end

            default: begin
                imm_out  = 32'b0;
                imm_type = 3'b0;
            end
        endcase
    end

endmodule
