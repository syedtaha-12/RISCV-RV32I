// alu_input_b_mux_tb.sv
// Testbench for alu_input_b_mux.sv
// Purely combinational DUT - no clock needed.

module alu_input_b_mux_tb;

    logic [31:0] rs2;
    logic [31:0] imm;
    logic        alu_src;
    logic [31:0] out;

    int errors = 0;

    alu_input_b_mux dut (
        .rs2(rs2),
        .imm(imm),
        .alu_src(alu_src),
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

        rs2 = 32'hCAFE_BABE;
        imm = 32'h0000_0F00;

        alu_src = 1'b0; check("select rs2", rs2);
        alu_src = 1'b1; check("select imm", imm);

        // Re-check with different operand values to ensure no stale state
        rs2 = 32'h1111_2222;
        imm = 32'hFFFF_FFFF;

        alu_src = 1'b0; check("select rs2 (2)", rs2);
        alu_src = 1'b1; check("select imm (2)", imm);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
