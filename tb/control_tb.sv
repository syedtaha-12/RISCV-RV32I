// control_tb.sv
// Testbench for the main control unit.
// Purely combinational DUT, so no clock is needed -
// we just drive an opcode and check outputs settle correctly.

module control_tb;

    logic [6:0] opcode;
    logic       reg_write, mem_read, mem_write;
    logic [1:0] wb_sel;
    logic       alu_src;
    logic [1:0] alu_a_sel;
    logic       branch, jump;
    logic [2:0] alu_op;

    int errors = 0;

    control dut (
        .opcode(opcode),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .wb_sel(wb_sel),
        .alu_src(alu_src),
        .alu_a_sel(alu_a_sel),
        .branch(branch),
        .jump(jump),
        .alu_op(alu_op)
    );

    task check(
        string      name,
        logic       exp_reg_write,
        logic       exp_mem_read,
        logic       exp_mem_write,
        logic [1:0] exp_wb_sel,
        logic       exp_alu_src,
        logic [1:0] exp_alu_a_sel,
        logic       exp_branch,
        logic       exp_jump,
        logic [2:0] exp_alu_op
    );
        #1; // let always_comb settle
        if (reg_write !== exp_reg_write ||
            mem_read   !== exp_mem_read ||
            mem_write  !== exp_mem_write ||
            wb_sel     !== exp_wb_sel ||
            alu_src    !== exp_alu_src ||
            alu_a_sel  !== exp_alu_a_sel ||
            branch     !== exp_branch ||
            jump       !== exp_jump ||
            alu_op     !== exp_alu_op) begin
            $display("FAIL [%s]: got reg_write=%b mem_read=%b mem_write=%b wb_sel=%b alu_src=%b alu_a_sel=%b branch=%b jump=%b alu_op=%b",
                      name, reg_write, mem_read, mem_write, wb_sel, alu_src, alu_a_sel, branch, jump, alu_op);
            $display("          exp reg_write=%b mem_read=%b mem_write=%b wb_sel=%b alu_src=%b alu_a_sel=%b branch=%b jump=%b alu_op=%b",
                      exp_reg_write, exp_mem_read, exp_mem_write, exp_wb_sel, exp_alu_src, exp_alu_a_sel, exp_branch, exp_jump, exp_alu_op);
            errors++;
        end else begin
            $display("PASS [%s]", name);
        end
    endtask

    initial begin

        // R-type
        opcode = 7'b0110011;
        check("R-type", 1'b1, 1'b0, 1'b0, 2'b00, 1'b0, 2'b00, 1'b0, 1'b0, 3'b010);

        // I-type ALU-immediate
        opcode = 7'b0010011;
        check("I-type", 1'b1, 1'b0, 1'b0, 2'b00, 1'b1, 2'b00, 1'b0, 1'b0, 3'b011);

        // LOAD
        opcode = 7'b0000011;
        check("LOAD", 1'b1, 1'b1, 1'b0, 2'b01, 1'b1, 2'b00, 1'b0, 1'b0, 3'b000);

        // STORE
        opcode = 7'b0100011;
        check("STORE", 1'b0, 1'b0, 1'b1, 2'b00, 1'b1, 2'b00, 1'b0, 1'b0, 3'b000);

        // BRANCH
        opcode = 7'b1100011;
        check("BRANCH", 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 2'b00, 1'b1, 1'b0, 3'b001);

        // JAL
        opcode = 7'b1101111;
        check("JAL", 1'b1, 1'b0, 1'b0, 2'b10, 1'b0, 2'b00, 1'b0, 1'b1, 3'b000);

        // JALR
        opcode = 7'b1100111;
        check("JALR", 1'b1, 1'b0, 1'b0, 2'b10, 1'b1, 2'b00, 1'b0, 1'b1, 3'b000);

        // LUI
        opcode = 7'b0110111;
        check("LUI", 1'b1, 1'b0, 1'b0, 2'b00, 1'b1, 2'b10, 1'b0, 1'b0, 3'b100);

        // AUIPC
        opcode = 7'b0010111;
        check("AUIPC", 1'b1, 1'b0, 1'b0, 2'b00, 1'b1, 2'b01, 1'b0, 1'b0, 3'b000);

        // Unrecognized opcode -> safe defaults
        opcode = 7'b1111111;
        check("UNKNOWN", 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 2'b00, 1'b0, 1'b0, 3'b000);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule