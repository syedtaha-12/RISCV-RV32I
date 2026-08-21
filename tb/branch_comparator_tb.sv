// branch_comparator_tb.sv
// Testbench for branch_comparator.sv
// Purely combinational DUT - no clock needed.

module branch_comparator_tb;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [2:0] funct3;
    logic branch_taken;

    int errors = 0;

    branch_comparator dut (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .funct3(funct3),
        .branch_taken(branch_taken)
    );

    // ---- Functional coverage ----
    // Tracks whether every branch type (funct3) and every outcome
    // (branch_taken = 0/1) has actually been hit by our directed tests.
    // This doesn't check correctness (assert/check() already do that) -
    // it checks that our test list didn't forget a case.
    covergroup branch_cg @(posedge dummy_clk);
        // dummy_clk is a manual trigger (see sample() call below) since
        // this DUT is combinational and has no real clock.

        cp_funct3: coverpoint funct3 {
            bins beq  = {3'b000};
            bins bne  = {3'b001};
            bins blt  = {3'b100};
            bins bge  = {3'b101};
            bins bltu = {3'b110};
            bins bgeu = {3'b111};
        }

        cp_taken: coverpoint branch_taken {
            bins not_taken = {1'b0};
            bins taken     = {1'b1};
        }

        // Cross: make sure we've seen both taken and not-taken
        // for each branch type, not just each independently.
        cross_funct3_taken: cross cp_funct3, cp_taken;
    endgroup

    logic dummy_clk; // never toggled - covergroup sampled manually via .sample()
    branch_cg cg = new();

    task check(string test_name, logic [31:0] a, logic [31:0] b, logic [2:0] f3, logic expected);
        rs1_data = a;
        rs2_data = b;
        funct3 = f3;
        #1;

        assert (!$isunknown(branch_taken))
        else $error("branch_taken is unknown/X!");

        if (branch_taken !== expected) begin
            $display("FAIL [%s]: got branch_taken=%b, expected=%b", test_name, branch_taken, expected);
            errors++;
        end else begin
            $display("PASS [%s]", test_name);
        end

        cg.sample(); // manually sample coverage after each check
    endtask

    initial begin

        // ---- BEQ (funct3 = 000): taken if rs1 == rs2 ----
        check("BEQ taken",     32'd5,        32'd5, 3'b000, 1'b1);
        check("BEQ not taken", 32'd5,        32'd6, 3'b000, 1'b0);

        // ---- BNE (funct3 = 001): taken if rs1 != rs2 ----
        check("BNE taken",     32'd5,        32'd6, 3'b001, 1'b1);
        check("BNE not taken", 32'd5,        32'd5, 3'b001, 1'b0);

        // ---- BLT (funct3 = 100): taken if rs1 < rs2 (signed) ----
        check("BLT taken",       32'd1,        32'd2, 3'b100, 1'b1);
        check("BLT not taken",   32'd2,        32'd1, 3'b100, 1'b0);
        check("BLT signed edge", 32'hFFFFFFFF, 32'd1, 3'b100, 1'b1); // -1 < 1

        // ---- BGE (funct3 = 101): taken if rs1 >= rs2 (signed) ----
        check("BGE taken",     32'd2, 32'd1, 3'b101, 1'b1);
        check("BGE equal",     32'd2, 32'd2, 3'b101, 1'b1);
        check("BGE not taken", 32'd1, 32'd2, 3'b101, 1'b0);

        // ---- BLTU (funct3 = 110): taken if rs1 < rs2 (unsigned) ----
        check("BLTU taken",         32'd1,        32'd2, 3'b110, 1'b1);
        check("BLTU unsigned edge", 32'hFFFFFFFF, 32'd1, 3'b110, 1'b0); // huge unsigned, not < 1

        // ---- BGEU (funct3 = 111): taken if rs1 >= rs2 (unsigned) ----
        check("BGEU taken",     32'hFFFFFFFF, 32'd1, 3'b111, 1'b1);
        check("BGEU not taken", 32'd1,        32'd2, 3'b111, 1'b0);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $display("Coverage = %0.2f%%", cg.get_coverage());

        $finish;
    end

endmodule