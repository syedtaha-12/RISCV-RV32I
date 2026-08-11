module pc (
    input logic reset,
    input logic clk,
    input logic [31:0] pc_in,
    output logic [31:0] pc_out
);
    always_ff @ (posedge clk or posedge reset) begin 
        if (reset) begin
            pc_out <= 32'h0;
        end else begin
            pc_out <= pc_in;
        end
    end
endmodule