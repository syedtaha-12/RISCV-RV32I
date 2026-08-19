// alu_input_a_mux_tb.sv
// Testbench for alu_input_a_mux.sv
// Purely combinational DUT - no clock needed.

module alu_input_a_mux_tb;

    logic [31:0] rs1;
    logic [31:0] pc;
    logic [1:0]  alu_a_sel;
    logic [31:0] out;

    int errors = 0;

    alu_input_a_mux dut (
        .rs1(rs1),
        .pc(pc),
        .alu_a_sel(alu_a_sel),
        .out(out)
    );

    task check(string name, logic [31:0] expected);
        #1;
        if (out !== expected) begin
            $display("FAIL [%s]: got out=%h, expected=%h", name, out, expected);
            errors++;
        end else begin
            $display("PASS [%s]", name);
        end
    endtask

    initial begin

        rs1 = 32'hDEAD_BEEF;
        pc  = 32'h0000_1000;

        alu_a_sel = 2'b00; check("select rs1", rs1);
        alu_a_sel = 2'b01; check("select pc", pc);
        alu_a_sel = 2'b10; check("select zero", 32'd0);
        alu_a_sel = 2'b11; check("unused select -> default rs1", rs1);

        // Re-check with different operand values to ensure no stale state
        rs1 = 32'h1234_5678;
        pc  = 32'h8765_4321;

        alu_a_sel = 2'b00; check("select rs1 (2)", rs1);
        alu_a_sel = 2'b01; check("select pc (2)", pc);
        alu_a_sel = 2'b10; check("select zero (2)", 32'd0);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
