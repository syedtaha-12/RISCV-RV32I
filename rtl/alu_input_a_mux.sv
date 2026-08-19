module alu_input_a_mux (
    input logic [31:0] rs1,
    input logic [31:0] pc,
    input logic [1:0] alu_a_sel,
    output logic [31:0] out
);

    always_comb begin
        case (alu_a_sel) 
            2'b00: out = rs1;
            2'b01: out = pc;
            2'b10: out = 32'd0;
            
            default: out = rs1;
        endcase 
    end

endmodule