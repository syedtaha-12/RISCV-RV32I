module next_pc_select_logic_tb;
    
    logic branch_inst_bool;
    logic jump_inst_bool;
    logic branch_taken;
    logic [1:0] next_pc_select;
    int errors = 0; 

    next_pc_select_logic dut (
        .branch_inst_bool(branch_inst_bool),
        .jump_inst_bool(jump_inst_bool),
        .branch_taken(branch_taken),
        .next_pc_select(next_pc_select)
    );

    task check (string test_name, logic branch_inst1,  logic branch_taken1, logic jump_inst1, logic [1:0] expected);
        branch_inst_bool = branch_inst1;
        branch_taken = branch_taken1;
        jump_inst_bool = jump_inst1;
        #2;

        if (next_pc_select != expected) begin
            errors++;
            $display("FAIL [%s]: expected %b, got %b", test_name, expected, next_pc_select);
        end else begin 
            $display ("PASS [%s]", test_name);
        end
    endtask

    
    initial begin

        check ("Output jump select expected", 1'b0, 1'b0, 1'b1, 2'b10);
        
        check ("Output jump select bits expected", 1'b0, 1'b1, 1'b1, 2'b10);
        
        check ("Output jump select bits expected", 1'b1, 1'b0, 1'b1, 2'b10);
        
        check ("Output jump select bits expected", 1'b1, 1'b1, 1'b1, 2'b10);

        check ("Output branch select bits expected", 1'b1, 1'b1, 1'b0, 2'b01);

        check ("pc plus 4 expected test", 1'b0, 1'b1, 1'b0, 2'b00);

        check ("pc plus 4 expected test", 1'b0, 1'b0, 1'b0, 2'b00);

        check ("pc plus 4 expected test", 1'b1, 1'b0, 1'b0, 2'b00);

        if (errors == 0) begin 
            $display("ALL TESTS PASSED!");
        end else begin
            $display ("%d TESTS FAILED!", errors);
        end 

        $finish;
    end 
endmodule
