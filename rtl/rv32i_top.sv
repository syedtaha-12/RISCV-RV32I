// rv32i_top.sv
// Single-cycle RV32I datapath - wires together every verified module
// into one instruction-per-clock core.

module rv32i_top (
    input logic clk,
    input logic reset
);

    // ---------------- PC ----------------
    logic [31:0] pc_current;
    logic [31:0] next_pc;

    pc pc_reg (
        .reset  (reset),
        .clk    (clk),
        .pc_in  (next_pc),
        .pc_out (pc_current)
    );

    logic [31:0] pc_plus4;

    adder_pc pc4_adder (
        .a   (pc_current),
        .sum (pc_plus4)
    );

    // ---------------- Fetch ----------------
    logic [31:0] instr;

    instr_mem imem (
        .addr      (pc_current),
        .instr_out (instr)
    );

    // ---------------- Decode: instruction fields ----------------
    logic [6:0] opcode;
    logic [4:0] rd_addr;
    logic [2:0] funct3;
    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [6:0] funct7;

    assign opcode   = instr[6:0];
    assign rd_addr  = instr[11:7];
    assign funct3   = instr[14:12];
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign funct7   = instr[31:25];

    // ---------------- Control ----------------
    logic       reg_write;
    logic       mem_read;
    logic       mem_write;
    logic [1:0] wb_sel;
    logic       alu_src;
    logic [1:0] alu_a_sel;
    logic       branch_inst;
    logic       jump_inst;
    logic [2:0] alu_op_code;

    control ctrl (
        .opcode      (opcode),
        .reg_write   (reg_write),
        .mem_read    (mem_read),
        .mem_write   (mem_write),
        .wb_sel      (wb_sel),
        .alu_src     (alu_src),
        .alu_a_sel   (alu_a_sel),
        .branch_inst (branch_inst),
        .jump_inst   (jump_inst),
        .alu_op      (alu_op_code)
    );

    // ---------------- Immediate generator ----------------
    logic [31:0] imm;
    logic [2:0]  imm_type;

    imm_gen immgen (
        .instr    (instr),
        .imm_out  (imm),
        .imm_type (imm_type)
    );

    // ---------------- Register file ----------------
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] wb_data;

    register regfile (
        .clk      (clk),
        .we       (reg_write),
        .rs1_addr (rs1_addr),
        .rs2_addr (rs2_addr),
        .rd_addr  (rd_addr),
        .rd_data  (wb_data),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );

    // ---------------- ALU control ----------------
    logic [3:0] alu_ctrl;

    alu_control aluctrl (
        .alu_op   (alu_op_code),
        .funct3   (funct3),
        .funct7   (funct7),
        .alu_ctrl (alu_ctrl)
    );

    // ---------------- ALU input muxes ----------------
    logic [31:0] alu_in_a;
    logic [31:0] alu_in_b;

    alu_input_a_mux a_mux (
        .rs1       (rs1_data),
        .pc        (pc_current),
        .alu_a_sel (alu_a_sel),
        .out       (alu_in_a)
    );

    alu_input_b_mux b_mux (
        .rs2     (rs2_data),
        .imm     (imm),
        .alu_src (alu_src),
        .out     (alu_in_b)
    );

    // ---------------- ALU ----------------
    logic [31:0] alu_result;
    logic        alu_zero;

    alu alu_unit (
        .a       (alu_in_a),
        .b       (alu_in_b),
        .alu_op  (alu_ctrl),
        .alu_out (alu_result),
        .zero    (alu_zero)
    );

    // ---------------- Branch condition ----------------
    logic branch_taken;

    branch_comparator bcomp (
        .rs1_data     (rs1_data),
        .rs2_data     (rs2_data),
        .funct3       (funct3),
        .branch_taken (branch_taken)
    );

    // ---------------- PC-relative target (branches and JAL) ----------------
    logic [31:0] pc_plus_imm;

    branch_jump_target_adder pc_imm_adder (
        .immediate         (imm),
        .pc_out            (pc_current),
        .pc_plus_immediate (pc_plus_imm)
    );

    // JALR's target is rs1 + imm, which the shared ALU already computes
    // (control sets alu_a_sel=rs1, alu_src=imm for opcode 1100111).
    // JAL's target is pc + imm, from the adder above. Pick per opcode.
    logic [31:0] jump_target;
    localparam logic [6:0] OPCODE_JALR = 7'b1100111;

    assign jump_target = (opcode == OPCODE_JALR) ? alu_result : pc_plus_imm;

    // ---------------- Next-PC selection ----------------
    logic [1:0] next_pc_sel;

    next_pc_select_logic pcsel (
        .branch_inst_bool (branch_inst),
        .jump_inst_bool   (jump_inst),
        .branch_taken     (branch_taken),
        .next_pc_select   (next_pc_sel)
    );

    next_pc_mux pcmux (
        .pc_plus4_inst_address (pc_plus4),
        .branch_inst_address   (pc_plus_imm),
        .jump_inst_address     (jump_target),
        .next_pc_select        (next_pc_sel),
        .next_pc_out           (next_pc)
    );

    // ---------------- Data memory ----------------
    logic [31:0] mem_read_data;

    data_mem dmem (
        .clk        (clk),
        .we         (mem_write),
        .addr       (alu_result),
        .size       (funct3[1:0]),
        .write_data (rs2_data),
        .read_data  (mem_read_data)
    );

    logic [31:0] load_data;

    load_extend lext (
        .mem_data (mem_read_data),
        .funct3   (funct3),
        .out      (load_data)
    );

    // ---------------- Writeback ----------------
    wb_mux wbmux (
        .alu_result (alu_result),
        .mem_data   (load_data),
        .pc_plus4   (pc_plus4),
        .wb_sel     (wb_sel),
        .out        (wb_data)
    );

endmodule
