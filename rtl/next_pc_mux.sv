module next_pc_mux (
    input logic [31:0] pc_plus4_inst_address,
    input logic [31:0] branch_inst_address,
    input logic [31:0] jump_inst_address,
    input logic [1:0] next_pc_select,
    output logic [31:0] next_pc_out
);

    always_comb begin 
        
        case(next_pc_select)
            2'b00: next_pc_out = pc_plus4_inst_address;
            2'b01: next_pc_out = branch_inst_address;
            2'b10: next_pc_out = jump_inst_address;

            default: next_pc_out = pc_plus4_inst_address;
        endcase 
    end
endmodule