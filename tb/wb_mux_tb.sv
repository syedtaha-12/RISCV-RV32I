// wb_mux_tb.sv
// Testbench for wb_mux.sv
// Purely combinational DUT - no clock needed.

module wb_mux_tb;

    logic [31:0] alu_result;
    logic [31:0] mem_data;
    logic [31:0] pc_plus4;
    logic [1:0]  wb_sel;
    logic [31:0] out;

    int errors = 0;

    wb_mux dut (
        .alu_result(alu_result),
        .mem_data(mem_data),
        .pc_plus4(pc_plus4),
        .wb_sel(wb_sel),
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

        alu_result = 32'hAAAA_AAAA;
        mem_data   = 32'hBBBB_BBBB;
        pc_plus4   = 32'hCCCC_CCCC;

        wb_sel = 2'b00; check("select alu_result", alu_result);
        wb_sel = 2'b01; check("select mem_data", mem_data);
        wb_sel = 2'b10; check("select pc_plus4", pc_plus4);
        wb_sel = 2'b11; check("unused select -> default alu_result", alu_result);

        // Re-check with different operand values to ensure no stale state
        alu_result = 32'h1234_5678;
        mem_data   = 32'h8765_4321;
        pc_plus4   = 32'h0000_1004;

        wb_sel = 2'b00; check("select alu_result (2)", alu_result);
        wb_sel = 2'b01; check("select mem_data (2)", mem_data);
        wb_sel = 2'b10; check("select pc_plus4 (2)", pc_plus4);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
