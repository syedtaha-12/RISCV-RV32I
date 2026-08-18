// alu_control_tb.sv
// Testbench for alu_control.sv
// Purely combinational DUT - no clock needed.

module alu_control_tb;

    logic [2:0] alu_op;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [3:0] alu_ctrl;

    int errors = 0;

    // Must match alu.sv's localparams
    localparam logic [3:0] ALU_ADD  = 4'b0000;
    localparam logic [3:0] ALU_SUB  = 4'b0001;
    localparam logic [3:0] ALU_AND  = 4'b0010;
    localparam logic [3:0] ALU_OR   = 4'b0011;
    localparam logic [3:0] ALU_XOR  = 4'b0100;
    localparam logic [3:0] ALU_SLL  = 4'b0101;
    localparam logic [3:0] ALU_SRL  = 4'b0110;
    localparam logic [3:0] ALU_SRA  = 4'b0111;
    localparam logic [3:0] ALU_SLT  = 4'b1000;
    localparam logic [3:0] ALU_SLTU = 4'b1001;

    alu_control dut (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .alu_ctrl(alu_ctrl)
    );

    task check(string name, logic [3:0] expected);
        #1;
        if (alu_ctrl !== expected) begin
            $display("FAIL [%s]: got alu_ctrl=%b, expected=%b", name, alu_ctrl, expected);
            errors++;
        end else begin
            $display("PASS [%s]", name);
        end
    endtask

    initial begin

        // ---- Fixed categories (funct3/funct7 don't matter) ----
        alu_op = 3'b000; funct3 = 3'b000; funct7 = 7'b0000000;
        check("ADD category (load/store/JALR/AUIPC)", ALU_ADD);

        alu_op = 3'b001; funct3 = 3'b000; funct7 = 7'b0000000;
        check("SUB category (branch)", ALU_SUB);

        alu_op = 3'b100; funct3 = 3'b000; funct7 = 7'b0000000;
        check("LUI pass-through (uses ADD)", ALU_ADD);

        // ---- R-type (alu_op = 010) ----
        alu_op = 3'b010;

        funct3 = 3'b000; funct7 = 7'b0000000; check("R: ADD", ALU_ADD);
        funct3 = 3'b000; funct7 = 7'b0100000; check("R: SUB", ALU_SUB);
        funct3 = 3'b001; funct7 = 7'b0000000; check("R: SLL", ALU_SLL);
        funct3 = 3'b010; funct7 = 7'b0000000; check("R: SLT", ALU_SLT);
        funct3 = 3'b011; funct7 = 7'b0000000; check("R: SLTU", ALU_SLTU);
        funct3 = 3'b100; funct7 = 7'b0000000; check("R: XOR", ALU_XOR);
        funct3 = 3'b101; funct7 = 7'b0000000; check("R: SRL", ALU_SRL);
        funct3 = 3'b101; funct7 = 7'b0100000; check("R: SRA", ALU_SRA);
        funct3 = 3'b110; funct7 = 7'b0000000; check("R: OR", ALU_OR);
        funct3 = 3'b111; funct7 = 7'b0000000; check("R: AND", ALU_AND);

        // ---- I-type ALU-immediate (alu_op = 011) ----
        alu_op = 3'b011;

        funct3 = 3'b000; funct7 = 7'b0000000; check("I: ADDI", ALU_ADD);
        funct3 = 3'b001; funct7 = 7'b0000000; check("I: SLLI", ALU_SLL);
        funct3 = 3'b010; funct7 = 7'b0000000; check("I: SLTI", ALU_SLT);
        funct3 = 3'b011; funct7 = 7'b0000000; check("I: SLTIU", ALU_SLTU);
        funct3 = 3'b100; funct7 = 7'b0000000; check("I: XORI", ALU_XOR);
        funct3 = 3'b101; funct7 = 7'b0000000; check("I: SRLI", ALU_SRL);
        funct3 = 3'b101; funct7 = 7'b0100000; check("I: SRAI", ALU_SRA);
        funct3 = 3'b110; funct7 = 7'b0000000; check("I: ORI", ALU_OR);
        funct3 = 3'b111; funct7 = 7'b0000000; check("I: ANDI", ALU_AND);

        // ---- Unknown alu_op -> safe default ----
        alu_op = 3'b111; funct3 = 3'b000; funct7 = 7'b0000000;
        check("Unknown alu_op default", ALU_ADD);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule