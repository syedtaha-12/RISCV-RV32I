module instr_mem #(
    parameter MEM_SIZE = 256
) (
    input  logic [31:0] addr,
    output logic [31:0] instr_out
);

    logic [7:0] mem [0:MEM_SIZE-1];

    assign instr_out = {
        mem[addr + 3],
        mem[addr + 2],
        mem[addr + 1],
        mem[addr]
    };

    initial begin
        $readmemh("instr_mem_init.hex", mem);
    end

endmodule