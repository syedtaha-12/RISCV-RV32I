module adder_pc (
    input  logic [31:0] a,
    output logic [31:0] sum
);

    assign sum = a + 32'd4;

endmodule