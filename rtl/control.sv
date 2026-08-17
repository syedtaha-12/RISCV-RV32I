// control.sv
// Main Control Unit
// Takes only the 7-bit opcode and produces the top-level control
// signals for the datapath. Does NOT decide the exact ALU operation
// (that needs funct3/funct7 too) - it only outputs a short alu_op
// code that a separate alu_control block will refine later.

module control (
    input  logic [6:0] opcode,

    output logic       reg_write,   // 1 = write result into rd
    output logic       mem_read,    // 1 = this is a load
    output logic       mem_write,   // 1 = this is a store
    output logic [1:0] wb_sel,      // 00 = ALU result, 01 = mem data, 10 = PC+4
    output logic       alu_src,     // 1 = ALU input B is the immediate, 0 = it's rs2
    output logic       branch,      // 1 = this is a conditional branch
    output logic       jump,        // 1 = this is an unconditional jump (JAL/JALR)
    output logic [2:0] alu_op       // rough category, refined later by alu_control
);

    // alu_op meaning (kept intentionally short/simple):
    //   000 -> ALU just needs to ADD (loads, stores, JALR, AUIPC)
    //   001 -> ALU needs to SUBTRACT for a branch comparison
    //   010 -> R-type: exact op decided by funct3/funct7 in alu_control
    //   011 -> I-type ALU-immediate: exact op decided by funct3/funct7 in alu_control
    //   100 -> LUI: ALU just passes input B (immediate) straight through, no math

    // wb_sel meaning:
    //   00 -> writeback comes from the ALU result
    //   01 -> writeback comes from data_mem (loads)
    //   10 -> writeback comes from PC+4 (JAL/JALR return address)

    always_comb begin
        // Safe defaults so we never leave a signal unassigned
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        wb_sel     = 2'b00;
        alu_src    = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 3'b000;

        case (opcode)
            7'b0110011: begin // R-type (ADD, SUB, AND, OR, ...)
                reg_write = 1'b1;
                alu_src   = 1'b0; // ALU input B = rs2
                wb_sel    = 2'b00; // writeback from ALU
                alu_op    = 3'b010;
            end

            7'b0010011: begin // I-type ALU-immediate (ADDI, ANDI, ...)
                reg_write = 1'b1;
                alu_src   = 1'b1; // ALU input B = immediate
                wb_sel    = 2'b00;
                alu_op    = 3'b011;
            end

            7'b0000011: begin // LOAD (LB/LH/LW/LBU/LHU)
                reg_write = 1'b1;
                alu_src   = 1'b1; // address = rs1 + imm
                mem_read  = 1'b1;
                wb_sel    = 2'b01; // writeback from data_mem
                alu_op    = 3'b000; // ALU just adds for the address
            end

            7'b0100011: begin // STORE (SB/SH/SW)
                alu_src   = 1'b1; // address = rs1 + imm
                mem_write = 1'b1;
                alu_op    = 3'b000; // ALU just adds for the address
                // reg_write stays 0 - stores don't write a register
            end

            7'b1100011: begin // BRANCH (BEQ/BNE/BLT/...)
                alu_src = 1'b0;  // compare rs1 vs rs2
                branch  = 1'b1;
                alu_op  = 3'b001; // ALU subtracts to compare
                // reg_write stays 0 - branches don't write a register
            end

            7'b1101111: begin // JAL
                reg_write = 1'b1;
                jump      = 1'b1;
                wb_sel    = 2'b10; // writeback = PC+4
            end

            7'b1100111: begin // JALR
                reg_write = 1'b1;
                alu_src   = 1'b1; // target = rs1 + imm
                jump      = 1'b1;
                wb_sel    = 2'b10; // writeback = PC+4
                alu_op    = 3'b000;
            end

            7'b0110111: begin // LUI
                reg_write = 1'b1;
                alu_src   = 1'b1; // ALU input B = immediate
                wb_sel    = 2'b00; // writeback from ALU (pass-through result)
                alu_op    = 3'b100; // tells alu_control: just pass B through
            end

            7'b0010111: begin // AUIPC
                reg_write = 1'b1;
                alu_src   = 1'b1; // ALU input B = immediate, input A = PC (handled outside)
                wb_sel    = 2'b00;
                alu_op    = 3'b000; // ADD
            end

            default: begin
                // Unrecognized opcode - keep everything at safe defaults
                reg_write = 1'b0;
                mem_read  = 1'b0;
                mem_write = 1'b0;
                wb_sel    = 2'b00;
                alu_src   = 1'b0;
                branch    = 1'b0;
                jump      = 1'b0;
                alu_op    = 3'b000;
            end
        endcase
    end

endmodule