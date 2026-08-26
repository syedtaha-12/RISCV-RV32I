module next_pc_select_logic_tb;

    logic branch_inst_bool;
    logic jal_inst_bool;
    logic jalr_inst_bool;
    logic branch_taken;
    logic [1:0] next_pc_select;
    int errors = 0;

    next_pc_select_logic dut (
        .branch_inst_bool(branch_inst_bool),
        .jal_inst_bool(jal_inst_bool),
        .jalr_inst_bool(jalr_inst_bool),
        .branch_taken(branch_taken),
        .next_pc_select(next_pc_select)
    );

    task check (string test_name, logic branch_inst1, logic branch_taken1, logic jal_inst1, logic jalr_inst1, logic [1:0] expected);
        branch_inst_bool = branch_inst1;
        branch_taken = branch_taken1;
        jal_inst_bool = jal_inst1;
        jalr_inst_bool = jalr_inst1;
        #2;

        if (next_pc_select != expected) begin
            errors++;
            $display("FAIL [%s]: expected %b, got %b", test_name, expected, next_pc_select);
        end else begin
            $display ("PASS [%s]", test_name);
        end
    endtask


    initial begin

        check ("JALR select expected", 1'b0, 1'b0, 1'b0, 1'b1, 2'b10);

        check ("JALR wins over JAL and taken branch", 1'b1, 1'b1, 1'b1, 1'b1, 2'b10);

        check ("JAL select expected", 1'b0, 1'b0, 1'b1, 1'b0, 2'b01);

        check ("Taken branch select expected", 1'b1, 1'b1, 1'b0, 1'b0, 2'b01);

        check ("Untaken branch falls through to pc plus 4", 1'b1, 1'b0, 1'b0, 1'b0, 2'b00);

        check ("pc plus 4 expected test", 1'b0, 1'b0, 1'b0, 1'b0, 2'b00);

        check ("pc plus 4 expected test (branch_taken with no branch_inst)", 1'b0, 1'b1, 1'b0, 1'b0, 2'b00);

        if (errors == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display ("%d TESTS FAILED!", errors);
        end

        $finish;
    end
endmodule
