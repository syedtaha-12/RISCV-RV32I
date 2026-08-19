module wb_mux (
    input logic [31:0] alu_result,
    input logic [31:0] mem_data,
    input logic [31:0] pc_plus4,
    input logic [1:0] wb_sel,
    output logic [31:0] out
);

    always_comb begin
        case (wb_sel)
            2'b00: out = alu_result;
            2'b01: out = mem_data;
            2'b10: out = pc_plus4;

            default: out = alu_result;
        endcase
    end

endmodule
