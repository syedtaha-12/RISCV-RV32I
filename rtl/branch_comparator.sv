module branch_comparator (
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,
    input logic [2:0] funct3,
    output logic branch_taken
);

/*funct3 tells which branch type is being executed
000 = BEQ → taken if rs1 == rs2
001 = BNE → taken if rs1 != rs2
100 = BLT → taken if rs1 < rs2 (signed)
101 = BGE → taken if rs1 >= rs2 (signed)
110 = BLTU → taken if rs1 < rs2 (unsigned)
111 = BGEU → taken if rs1 >= rs2 (unsigned) 
*/

always_comb begin 
    case (funct3)
        3'b000: branch_taken = (rs1_data == rs2_data) ? 1:0;
        3'b001: branch_taken = (rs1_data != rs2_data) ? 1:0;
        3'b100: branch_taken = ($signed(rs1_data) < $signed(rs2_data)) ? 1:0;
        3'b101: branch_taken = ($signed(rs1_data) >= $signed(rs2_data)) ? 1:0;
        3'b110: branch_taken = (rs1_data < rs2_data) ? 1:0;
        3'b111: branch_taken = (rs1_data >= rs2_data) ? 1:0;

        default: branch_taken = 1'b0;
    endcase
end

endmodule 