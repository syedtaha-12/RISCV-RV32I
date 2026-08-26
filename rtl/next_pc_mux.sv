module next_pc_mux (
    input logic [31:0] pc_plus4_inst_address,
    input logic [31:0] branch_jal_inst_address,
    input logic [31:0] jalr_inst_address,
    input logic [1:0] next_pc_select,
    output logic [31:0] next_pc_out
);

    always_comb begin 
        
        case(next_pc_select)
            2'b00: next_pc_out = pc_plus4_inst_address;
            2'b01: next_pc_out = branch_jal_inst_address;
            2'b10: next_pc_out = {jalr_inst_address[31:1], 1'b0}; // JALR must clear bit 0 per spec

            default: next_pc_out = pc_plus4_inst_address;
        endcase 
    end
endmodule