module branch_jump_target_adder (
    input logic [31:0] immediate,
    input logic [31:0] pc_out,
    output logic [31:0] pc_plus_immediate
);
    
    assign pc_plus_immediate = pc_out + immediate;

endmodule