// alu_control.sv
// Takes the rough category from control.sv (alu_op) plus funct3/funct7
// from the instruction, and outputs the exact 4-bit code alu.sv needs.

module alu_control (
    input  logic [2:0] alu_op,   // rough category from control.sv
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [3:0] alu_ctrl  // exact operation for alu.sv
);

    // Must match alu.sv's localparams exactly
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

            3'b000: alu_ctrl = ALU_ADD; // loads, stores, JALR, AUIPC
            3'b001: alu_ctrl = ALU_SUB; // branch comparison
            3'b100: alu_ctrl = ALU_ADD; // LUI (input A forced to 0 in datapath)

            3'b010: begin // R-type - funct3 (+funct7 bit 5 for ADD/SUB, SRL/SRA)
                case (funct3)
                    3'b000: alu_ctrl = funct7[5] ? ALU_SUB : ALU_ADD; // ADD vs SUB
                    3'b001: alu_ctrl = ALU_SLL;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b101: alu_ctrl = funct7[5] ? ALU_SRA : ALU_SRL; // SRL vs SRA
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            3'b011: begin // I-type ALU-immediate - funct3 (+funct7 bit 5 only for SRLI/SRAI)
                case (funct3)
                    3'b000: alu_ctrl = ALU_ADD;  // ADDI (no SUBI exists)
                    3'b001: alu_ctrl = ALU_SLL;  // SLLI
                    3'b010: alu_ctrl = ALU_SLT;  // SLTI
                    3'b011: alu_ctrl = ALU_SLTU; // SLTIU
                    3'b100: alu_ctrl = ALU_XOR;  // XORI
                    3'b101: alu_ctrl = funct7[5] ? ALU_SRA : ALU_SRL; // SRLI vs SRAI
                    3'b110: alu_ctrl = ALU_OR;   // ORI
                    3'b111: alu_ctrl = ALU_AND;  // ANDI
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            default: alu_ctrl = ALU_ADD;

        endcase
    end

endmodule