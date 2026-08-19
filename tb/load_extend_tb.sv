// load_extend_tb.sv
// Testbench for load_extend.sv
// Purely combinational DUT - no clock needed.

module load_extend_tb;

    logic [31:0] mem_data;
    logic [2:0]  funct3;
    logic [31:0] out;

    int errors = 0;

    load_extend dut (
        .mem_data(mem_data),
        .funct3(funct3),
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

        // ---- LB: positive byte, MSB clear -> zero-extend ----
        mem_data = 32'h0000_007F; // byte = 0x7F
        funct3   = 3'b000;
        check("LB positive", 32'h0000_007F);

        // ---- LB: negative byte, MSB set -> sign-extend to all 1s ----
        mem_data = 32'h0000_0080; // byte = 0x80
        funct3   = 3'b000;
        check("LB negative", 32'hFFFF_FF80);

        // ---- LH: positive half ----
        mem_data = 32'h0000_7FFF;
        funct3   = 3'b001;
        check("LH positive", 32'h0000_7FFF);

        // ---- LH: negative half ----
        mem_data = 32'h0000_8001;
        funct3   = 3'b001;
        check("LH negative", 32'hFFFF_8001);

        // ---- LW: pass through untouched ----
        mem_data = 32'hDEAD_BEEF;
        funct3   = 3'b010;
        check("LW pass-through", 32'hDEAD_BEEF);

        // ---- LBU: same negative-looking byte, but zero-extended ----
        mem_data = 32'h0000_0080;
        funct3   = 3'b100;
        check("LBU zero-extend", 32'h0000_0080);

        // ---- LHU: same negative-looking half, but zero-extended ----
        mem_data = 32'h0000_8001;
        funct3   = 3'b101;
        check("LHU zero-extend", 32'h0000_8001);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
