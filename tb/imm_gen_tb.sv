// imm_gen_tb.sv
// Testbench for imm_gen.sv
// Covers I, S, B, U, J formats, plus sign-extension edge cases
// (both positive and negative immediates).

module imm_gen_tb;

    logic [31:0] instr;
    logic [31:0] imm_out;
    logic [2:0]  imm_type;

    int pass_count = 0;
    int fail_count = 0;

    imm_gen dut (
        .instr(instr),
        .imm_out(imm_out),
        .imm_type(imm_type)
    );

    task check(input [31:0] test_instr,
               input [31:0] expected_imm,
               input [2:0]  expected_type,
               input string test_name);
        instr = test_instr;
        #1; // let combinational logic settle

        if (imm_out === expected_imm && imm_type === expected_type) begin
            $display("PASS: %s | imm_out=%h imm_type=%0d", test_name, imm_out, imm_type);
            pass_count++;
        end else begin
            $display("FAIL: %s | expected imm=%h type=%0d, got imm=%h type=%0d",
                       test_name, expected_imm, expected_type, imm_out, imm_type);
            fail_count++;
        end
    endtask

    initial begin
        // ---------- I-type ----------
        // ADDI x1, x0, 5   -> imm = 5
        check(32'b000000000101_00000_000_00001_0010011, 32'd5, 3'd0, "I-type positive (ADDI +5)");

        // ADDI x1, x0, -5  -> imm[11:0] = -5 (0xFFB), sign-extended
        check(32'b111111111011_00000_000_00001_0010011, -32'sd5, 3'd0, "I-type negative (ADDI -5)");

        // ---------- S-type ----------
        // SW x2, 5(x1)  -> imm = 5  (imm[11:5]=0000000, imm[4:0]=00101)
        check(32'b0000000_00010_00001_010_00101_0100011, 32'd5, 3'd1, "S-type positive (SW +5)");

        // SW x2, -5(x1) -> imm = -5
        check(32'b1111111_00010_00001_010_11011_0100011, -32'sd5, 3'd1, "S-type negative (SW -5)");

        // ---------- B-type ----------
        // BEQ x1, x2, +8   (imm = 8, bit0 always 0)
        // imm[12|10:5|4:1|11] = 0|000000|0100|0 = 0000000001000 (after re-arranging [11:0]) = 8 in decimal
        check(32'b0_000000_00010_00001_000_0100_0_1100011, 32'd8, 3'd2, "B-type positive (BEQ +8)");

        // BEQ x1, x2, -8   (imm = -8)
        // imm[12|10:5|4:1|11] = 1|111111|1100|1
        check(32'b1_111111_00010_00001_000_1100_1_1100011, -32'sd8, 3'd2, "B-type negative (BEQ -8)");

        // ---------- U-type ----------
        // LUI x1, 0x12345  -> imm = 0x12345000
        check(32'h12345_0B7, 32'h12345000, 3'd3, "U-type (LUI 0x12345)");

        // ---------- J-type ----------
        // JAL x1, +16  (imm = 16, bit0 always 0)
        // imm[20|10:1|11|19:12] = 0|0000001000|0|00000000
        check(32'b0_0000001000_0_00000000_00001_1101111, 32'd16, 3'd4, "J-type positive (JAL +16)");

        // JAL x1, -16  (imm = -16)
        // imm[20|10:1|11|19:12] = 1|1111111000|1|11111111
        check(32'b1_1111111000_1_11111111_00001_1101111, -32'sd16, 3'd4, "J-type negative (JAL -16)");

        // ---------- Summary ----------
        $display("----------------------------------------");
        $display("Total: %0d passed, %0d failed", pass_count, fail_count);
        $display("----------------------------------------");

        $stop;
    end

endmodule
