// load_extend.sv
// Takes data_mem's zero-extended read_data (byte/half already isolated
// in the low bits, upper bits 0) plus funct3, and produces the final
// sign- or zero-extended 32-bit load value.
//
// funct3 meaning for loads:
//   000 -> LB  (signed byte)
//   001 -> LH  (signed half)
//   010 -> LW  (word, no extension needed)
//   100 -> LBU (unsigned byte)
//   101 -> LHU (unsigned half)

module load_extend (
    input logic [31:0] mem_data,
    input logic [2:0] funct3,
    output logic [31:0] out
);

    always_comb begin
        case (funct3)
            3'b000: out = {{24{mem_data[7]}}, mem_data[7:0]};   // LB
            3'b001: out = {{16{mem_data[15]}}, mem_data[15:0]}; // LH
            3'b010: out = mem_data;                              // LW
            3'b100: out = {24'b0, mem_data[7:0]};                // LBU
            3'b101: out = {16'b0, mem_data[15:0]};               // LHU

            default: out = mem_data;
        endcase
    end

endmodule
