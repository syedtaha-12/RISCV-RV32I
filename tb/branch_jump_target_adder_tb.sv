module branch_jump_target_adder_tb;

    logic [31:0] immediate;
    logic [31:0] pc_out;
    logic [31:0] pc_plus_immediate;
    int errors = 0;

    branch_jump_target_adder dut (
        .immediate(immediate),
        .pc_out(pc_out),
        .pc_plus_immediate(pc_plus_immediate)
    );

    task check(string test_name, logic [31:0] pc_val, logic [31:0] imm_val, logic [31:0] expected);
        pc_out = pc_val;
        immediate = imm_val;

        #1;

        if (pc_plus_immediate != expected) begin
            errors++;
            $display("FAIL [%s]: expected %h got %h", test_name, expected, pc_plus_immediate);
        end else begin
            $display("PASS [%s]", test_name);
        end
    endtask

    initial begin

        // Basic positive offset
        check("Simple forward branch", 32'h0000_1000, 32'd16, 32'h0000_1010);

        // Zero immediate (branch to self / same address)
        check("Zero immediate", 32'h0000_2000, 32'd0, 32'h0000_2000);

        // Negative immediate (backward branch) - imm is sign-extended, e.g. -4
        check("Negative offset (backward branch)", 32'h0000_3000, 32'hFFFF_FFFC, 32'h0000_2FFC);

        // Large negative immediate (loop back further)
        check("Large negative offset", 32'h0000_5000, 32'hFFFF_F000, 32'h0000_4000);

        // PC near max value, wraparound behavior
        check("PC overflow wraparound", 32'hFFFF_FFF0, 32'd32, 32'h0000_0010);

        // Jump-style large positive immediate
        check("Large positive jump offset", 32'h0000_0000, 32'h0007_FFFE, 32'h0007_FFFE);

        if (errors == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;

    end

endmodule