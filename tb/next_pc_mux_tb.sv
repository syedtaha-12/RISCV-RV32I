module next_pc_mux_tb;

    logic [31:0] pc_plus4_inst_address;
    logic [31:0] branch_jal_inst_address;
    logic [31:0] jalr_inst_address;
    logic [1:0] next_pc_select;
    logic [31:0] next_pc_out;
    int errors;

    next_pc_mux dut (
        .pc_plus4_inst_address(pc_plus4_inst_address),
        .branch_jal_inst_address(branch_jal_inst_address),
        .jalr_inst_address(jalr_inst_address),
        .next_pc_select(next_pc_select),
        .next_pc_out(next_pc_out)
    );

    task check (
        string test_name,
        logic [31:0] pc_plus4,
        logic [31:0] branch_jal,
        logic [31:0] jalr,
        logic [1:0] pc_select1,
        logic [31:0] expected
    );
        pc_plus4_inst_address = pc_plus4;
        branch_jal_inst_address = branch_jal;
        jalr_inst_address = jalr;
        next_pc_select = pc_select1;

        #1;

        if (next_pc_out != expected) begin
            errors++;
            $display("FAIL [%s]: expected %h got %h", test_name, expected, next_pc_out);
        end else begin
            $display ("PASS [%s]", test_name);
        end
    endtask

    initial begin
        check("Output PC plus 4", 32'hDEADBEEF, 32'hCAFEF00D, 32'hABCDABCD, 2'b00, 32'hDEADBEEF);

        check("Output branch/JAL target", 32'hDEADBEEF, 32'hCAFEF00D, 32'hABCDABCD, 2'b01, 32'hCAFEF00D);

        check("Output JALR target", 32'hDEADBEEF, 32'hCAFEF00D, 32'hABCDABCD, 2'b10, 32'hABCDABCD);

        check("Default case (unused select 11)", 32'hDEADBEEF, 32'hCAFEF00D, 32'hABCDABCD, 2'b11, 32'hDEADBEEF);

        if (errors == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("%0d TESTS FAILED!", errors);
        end

        $finish;
    end

endmodule
