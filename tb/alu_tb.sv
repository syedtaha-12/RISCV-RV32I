`timescale 1ns/1ps

module alu_tb;

    logic [31:0] a;
    logic [31:0] b;
    logic [3:0]  alu_op;
    logic [31:0] alu_out;
    logic        zero;

    localparam logic [3:0] ALU_ADD  = 4'b0000;
    localparam logic [3:0] ALU_SUB  = 4'b0001;
    localparam logic [3:0] ALU_AND  = 4'b0010;
    localparam logic [3:0] ALU_OR   = 4'b0011;
    localparam logic [3:0] ALU_SLL  = 4'b0101;
    localparam logic [3:0] ALU_SRL  = 4'b0110;
    localparam logic [3:0] ALU_SRA  = 4'b0111;
    localparam logic [3:0] ALU_SLT  = 4'b1000;
    localparam logic [3:0] ALU_SLTU = 4'b1001;

    alu dut (
        .a       (a),
        .b       (b),
        .alu_op  (alu_op),
        .alu_out (alu_out),
        .zero(zero)
    );

    initial begin

        // ADD: 12 + 4 = 16
        a      = 32'd12;
        b      = 32'd4;
        alu_op = ALU_ADD;

        #2;

        if (alu_out !== 32'd16)
            $error("ADD failed: expected 16, got %0d", alu_out);

        // SUB: 50 - 20 = 30
        a      = 32'd50;
        b      = 32'd20;
        alu_op = ALU_SUB;

        #2;

        if (alu_out !== 32'd30)
            $error("SUB failed: expected 30, got %0d", alu_out);

        // AND: 50 & 20 = 16
        a      = 32'd50;
        b      = 32'd20;
        alu_op = ALU_AND;

        #2;

        if (alu_out !== 32'd16)
            $error("AND failed: expected 16, got %0d", alu_out);

        // OR: 6 | 0 = 6
        a      = 32'd6;
        b      = 32'd0;
        alu_op = ALU_OR;

        #2;

        if (alu_out !== 32'd6)
            $error("OR failed: expected 6, got %0d", alu_out);

        // SLL: 24 << 2 = 96
        a      = 32'd24;
        b      = 32'd2;
        alu_op = ALU_SLL;

        #2;

        if (alu_out !== 32'd96)
            $error("SLL failed: expected 96, got %0d", alu_out);

        // SRL: 24 >> 2 = 6
        a      = 32'd24;
        b      = 32'd2;
        alu_op = ALU_SRL;

        #2;

        if (alu_out !== 32'd6)
            $error("SRL failed: expected 6, got %0d", alu_out);

        // SRA: -16 >>> 2 = -4
        a      = -32'sd16;
        b      = 32'd2;
        alu_op = ALU_SRA;

        #2;

        if (alu_out !== -32'sd4)
            $error(
                "SRA failed: expected -4, got %0d",
                $signed(alu_out)
            );

        // SLT signed: -5 < 2 is true
        a      = -32'sd5;
        b      = 32'd2;
        alu_op = ALU_SLT;

        #2;

        if (alu_out !== 32'd1)
            $error("SLT failed: expected 1, got %0d", alu_out);

        // SLTU unsigned:
        // 0xFFFFFFFF = 4,294,967,295 unsigned
        // 4,294,967,295 < 2 is false
        a      = 32'hFFFFFFFF;
        b      = 32'd2;
        alu_op = ALU_SLTU;

        #2;

        if (alu_out !== 32'd0)
            $error("SLTU failed: expected 0, got %0d", alu_out);

        $display("All ALU tests completed. Check transcript for errors.");
        $stop;

    end

endmodule