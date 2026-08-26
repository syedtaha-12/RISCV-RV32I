module next_pc_select_logic (
    input logic branch_inst_bool,
    input logic jal_inst_bool,
    input logic jalr_inst_bool,
    input logic branch_taken,
    output logic [1:0] next_pc_select
);
    
    always_comb begin
        if (jalr_inst_bool) begin
            next_pc_select = 2'b10;
        end else if (jal_inst_bool || (branch_inst_bool && branch_taken)) begin
            next_pc_select = 2'b01;
        end else begin 
            next_pc_select = 2'b00;
        end
    end 

endmodule
