module data_mem #(
    parameter MEM_SIZE = 256
) (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [1:0]  size,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);

    logic [7:0] mem [0:MEM_SIZE-1];
    
    // ---------- WRITE (clocked) ----------
    always_ff @(posedge clk) begin
        if (we) begin
            case (size)
                2'b00: begin
                    mem[addr] <= write_data[7:0];
                end
                2'b01: begin
                    mem[addr]     <= write_data[7:0];
                    mem[addr + 1] <= write_data[15:8];
                end
                2'b10: begin
                    mem[addr]     <= write_data[7:0];
                    mem[addr + 1] <= write_data[15:8];
                    mem[addr + 2] <= write_data[23:16];
                    mem[addr + 3] <= write_data[31:24];
                end
                default: ;
            endcase
        end
    end

    // ---------- READ (combinational) ----------
    always_comb begin
        case (size)
            2'b00: read_data = {24'b0, mem[addr]};
            2'b01: read_data = {16'b0, mem[addr + 1], mem[addr]};
            2'b10: read_data = {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]};
            default: read_data = 32'b0;
        endcase
    end

endmodule