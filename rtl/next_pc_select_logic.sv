module next_pc_select_logic (
    input logic branch_inst_bool,
    input logic jump_inst_bool,
    input logic branch_taken,
    output logic [1:0] next_pc_select
);

    /* 2-bit select values:
    00 = outputs pc_plus4 instruction address
    01 = outputs branch_target instruction address
    10 = outputs jump_target instruction address
    */

    localparam logic [1:0] pc_plus4   = 2'b00;
    localparam logic [1:0] branch     = 2'b01;
    localparam logic [1:0] jump       = 2'b10;
    
    always_comb begin
        if (jump_inst_bool) begin
            next_pc_select = jump;
        end else if (branch_inst_bool && branch_taken) begin
            next_pc_select = branch;
        end else begin
            next_pc_select = pc_plus4;
        end  
    end
endmodule
