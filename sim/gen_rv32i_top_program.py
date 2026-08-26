# gen_rv32i_top_program.py
#
# Generates the integration test program for tb/rv32i_top_tb.sv:
#   - a tiny hand-rolled RV32I assembler + reference simulator
#   - assembles `prog` below into rv32i_top_program.hex (little-endian byte
#     dump, same format as instr_mem_init.hex, loaded via rv32i_top's
#     INSTR_INIT_FILE parameter)
#   - independently re-simulates the program in Python and emits the
#     expected per-cycle PC/register trace, final register file, and final
#     data memory contents as trace_arrays.svh - a reference for hand
#     cross-checking the constants already embedded in tb/rv32i_top_tb.sv
#
# Run from the repo root:
#   python sim/gen_rv32i_top_program.py
#
# If `prog` changes, regenerate and re-paste the resulting trace_arrays.svh
# content into tb/rv32i_top_tb.sv's expected-value arrays.

import re

def sext(val, bits):
    val &= (1 << bits) - 1
    if val & (1 << (bits - 1)):
        val -= (1 << bits)
    return val

def u32(val):
    return val & 0xFFFFFFFF

REG = {f"x{i}": i for i in range(32)}

# ---------------- program (mnemonics with label support) ----------------
prog = """
ADDI x1, x0, 5
ADDI x2, x0, 10
ADDI x3, x0, -3
ADD  x4, x1, x2
SUB  x5, x2, x1
AND  x6, x1, x2
OR   x7, x1, x2
XOR  x8, x1, x2
SLT  x9, x1, x2
SLT  x10, x2, x1
SLTU x11, x3, x1
SLL  x12, x1, x2
SRL  x13, x12, x2
SRA  x14, x3, x2
ANDI x15, x2, 6
ORI  x16, x2, 5
XORI x17, x2, 5
SLTI x18, x1, 10
SLTIU x19, x1, 10
SLLI x20, x1, 2
SRLI x21, x20, 2
SRAI x22, x3, 1
LUI  x23, 0x12345
AUIPC x24, 1
ADDI x25, x0, 64
SW   x4, 0(x25)
SH   x1, 4(x25)
SB   x2, 8(x25)
LW   x26, 0(x25)
LH   x27, 4(x25)
LB   x28, 8(x25)
LBU  x29, 8(x25)
LHU  x30, 4(x25)
SW   x3, 12(x25)
LW   x31, 12(x25)
BEQ  x1, x1, beq_target
ADDI x6, x0, 999
beq_target:
ADDI x6, x0, 111
BNE  x1, x1, bne_target
ADDI x7, x0, 222
bne_target:
BLT  x1, x2, blt_target
ADDI x8, x0, 999
blt_target:
ADDI x8, x0, 444
BGE  x2, x1, bge_target
ADDI x9, x0, 999
bge_target:
ADDI x9, x0, 555
BLTU x3, x1, bltu_target
ADDI x10, x0, 666
bltu_target:
BGEU x3, x1, bgeu_target
ADDI x11, x0, 999
bgeu_target:
ADDI x11, x0, 777
JAL  x12, jal_target
ADDI x13, x0, 999
jal_target:
ADDI x13, x0, 888
ADDI x14, x0, jalr_target
JALR x15, x14, 0
ADDI x16, x0, 999
jalr_target:
ADDI x16, x0, 111
halt:
JAL  x0, halt
"""

lines = []
for raw in prog.strip().splitlines():
    line = raw.split('#')[0].strip()
    if line:
        lines.append(line)

# pass 1: resolve addresses of labels and instructions
addr = 0
labels = {}
instrs = []  # (addr, mnemonic_line)
for line in lines:
    if line.endswith(':'):
        labels[line[:-1]] = addr
    else:
        instrs.append((addr, line))
        addr += 4

def parse_reg(tok):
    return REG[tok.strip().rstrip(',')]

def parse_imm(tok, cur_addr, relative=False):
    # `relative=True` resolves a label to a PC-relative offset (branches,
    # JAL). Otherwise a label resolves to its absolute address (e.g. an
    # ADDI loading a target address for a later JALR).
    tok = tok.strip().rstrip(',')
    if tok in labels:
        return (labels[tok] - cur_addr) if relative else labels[tok]
    return int(tok, 0)

def r_type(rd, rs1, rs2, funct3, funct7):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0b0110011

def i_type(rd, rs1, imm, funct3, opcode):
    imm = imm & 0xFFF
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def i_shift(rd, rs1, shamt, funct3, funct7):
    return (funct7 << 25) | (shamt << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0b0010011

def s_type(rs1, rs2, imm, funct3):
    imm = imm & 0xFFF
    imm_11_5 = (imm >> 5) & 0x7F
    imm_4_0 = imm & 0x1F
    return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | 0b0100011

def b_type(rs1, rs2, imm, funct3):
    imm = imm & 0x1FFF
    b12 = (imm >> 12) & 1
    b10_5 = (imm >> 5) & 0x3F
    b4_1 = (imm >> 1) & 0xF
    b11 = (imm >> 11) & 1
    return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (b4_1 << 8) | (b11 << 7) | 0b1100011

def u_type(rd, imm, opcode):
    return (u32(imm) & 0xFFFFF000) | (rd << 7) | opcode

def j_type(rd, imm, opcode):
    imm = imm & 0x1FFFFF
    b20 = (imm >> 20) & 1
    b10_1 = (imm >> 1) & 0x3FF
    b11 = (imm >> 11) & 1
    b19_12 = (imm >> 12) & 0xFF
    return (b20 << 31) | (b10_1 << 21) | (b11 << 20) | (b19_12 << 12) | (rd << 7) | opcode

machine = {}
for cur_addr, line in instrs:
    parts = line.replace(',', ' ').split()
    mnem = parts[0].upper()
    if mnem in ("SW", "SH", "SB"):
        # store: MNEM rs2, imm(rs1)
        rs2 = parse_reg(parts[1])
        m = re.match(r'(-?\w+)\((x\d+)\)', parts[2])
        imm = parse_imm(m.group(1), cur_addr)
        rs1 = parse_reg(m.group(2))
        funct3 = {"SB": 0, "SH": 1, "SW": 2}[mnem]
        word = s_type(rs1, rs2, imm, funct3)
    elif mnem in ("LW", "LH", "LB", "LBU", "LHU"):
        rd = parse_reg(parts[1])
        m = re.match(r'(-?\w+)\((x\d+)\)', parts[2])
        imm = parse_imm(m.group(1), cur_addr)
        rs1 = parse_reg(m.group(2))
        funct3 = {"LB": 0, "LH": 1, "LW": 2, "LBU": 4, "LHU": 5}[mnem]
        word = i_type(rd, rs1, imm, funct3, 0b0000011)
    elif mnem == "ADD":
        word = r_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_reg(parts[3]), 0, 0)
    elif mnem == "SUB":
        word = r_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_reg(parts[3]), 0, 0b0100000)
    elif mnem == "AND":
        word = r_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_reg(parts[3]), 0b111, 0)
    elif mnem == "OR":
        word = r_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_reg(parts[3]), 0b110, 0)
    elif mnem == "XOR":
        word = r_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_reg(parts[3]), 0b100, 0)
    elif mnem == "SLT":
        word = r_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_reg(parts[3]), 0b010, 0)
    elif mnem == "SLTU":
        word = r_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_reg(parts[3]), 0b011, 0)
    elif mnem == "SLL":
        word = r_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_reg(parts[3]), 0b001, 0)
    elif mnem == "SRL":
        word = r_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_reg(parts[3]), 0b101, 0)
    elif mnem == "SRA":
        word = r_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_reg(parts[3]), 0b101, 0b0100000)
    elif mnem == "ADDI":
        word = i_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3], cur_addr), 0, 0b0010011)
    elif mnem == "ANDI":
        word = i_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3], cur_addr), 0b111, 0b0010011)
    elif mnem == "ORI":
        word = i_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3], cur_addr), 0b110, 0b0010011)
    elif mnem == "XORI":
        word = i_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3], cur_addr), 0b100, 0b0010011)
    elif mnem == "SLTI":
        word = i_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3], cur_addr), 0b010, 0b0010011)
    elif mnem == "SLTIU":
        word = i_type(parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3], cur_addr), 0b011, 0b0010011)
    elif mnem == "SLLI":
        word = i_shift(parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3], cur_addr) & 0x1F, 0b001, 0)
    elif mnem == "SRLI":
        word = i_shift(parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3], cur_addr) & 0x1F, 0b101, 0)
    elif mnem == "SRAI":
        word = i_shift(parse_reg(parts[1]), parse_reg(parts[2]), parse_imm(parts[3], cur_addr) & 0x1F, 0b101, 0b0100000)
    elif mnem == "LUI":
        word = u_type(parse_reg(parts[1]), parse_imm(parts[2], cur_addr) << 12, 0b0110111)
    elif mnem == "AUIPC":
        word = u_type(parse_reg(parts[1]), parse_imm(parts[2], cur_addr) << 12, 0b0010111)
    elif mnem in ("BEQ", "BNE", "BLT", "BGE", "BLTU", "BGEU"):
        rs1 = parse_reg(parts[1]); rs2 = parse_reg(parts[2])
        imm = parse_imm(parts[3], cur_addr, relative=True)
        funct3 = {"BEQ":0,"BNE":1,"BLT":4,"BGE":5,"BLTU":6,"BGEU":7}[mnem]
        word = b_type(rs1, rs2, imm, funct3)
    elif mnem == "JAL":
        rd = parse_reg(parts[1])
        imm = parse_imm(parts[2], cur_addr, relative=True)
        word = j_type(rd, imm, 0b1101111)
    elif mnem == "JALR":
        rd = parse_reg(parts[1]); rs1 = parse_reg(parts[2])
        imm = parse_imm(parts[3], cur_addr)
        word = i_type(rd, rs1, imm, 0, 0b1100111)
    else:
        raise ValueError(f"unknown mnemonic {mnem} in line: {line}")
    machine[cur_addr] = u32(word)

max_addr = max(machine) + 4
print(f"; program length = {max_addr} bytes, {len(machine)} instructions")
print("; labels:", labels)

# ---------------- emit hex byte file (little-endian, one byte per line) ----------------
MEM_SIZE = 256
out_bytes = [0] * MEM_SIZE
for a, w in machine.items():
    out_bytes[a]     = w & 0xFF
    out_bytes[a + 1] = (w >> 8) & 0xFF
    out_bytes[a + 2] = (w >> 16) & 0xFF
    out_bytes[a + 3] = (w >> 24) & 0xFF

hexpath = "rv32i_top_program.hex"
with open(hexpath, "w") as f:
    for b in out_bytes:
        f.write(f"{b:02X}\n")
print(f"wrote {hexpath}")

# ---------------- reference simulator ----------------
regs = [0] * 32
mem = bytearray(256)
pc = 0
steps = 0
MAX_STEPS = 200

def rd_mem(addr, size):
    if size == 0:
        return mem[addr]
    if size == 1:
        return mem[addr] | (mem[addr+1] << 8)
    if size == 2:
        return mem[addr] | (mem[addr+1]<<8) | (mem[addr+2]<<16) | (mem[addr+3]<<24)

def wr_mem(addr, size, val):
    val = u32(val)
    mem[addr] = val & 0xFF
    if size >= 1:
        mem[addr+1] = (val >> 8) & 0xFF
    if size >= 2:
        mem[addr+2] = (val >> 16) & 0xFF
        mem[addr+3] = (val >> 24) & 0xFF

trace = []
while steps < MAX_STEPS:
    w = machine.get(pc, 0)
    opcode = w & 0x7F
    rd = (w >> 7) & 0x1F
    funct3 = (w >> 12) & 0x7
    rs1 = (w >> 15) & 0x1F
    rs2 = (w >> 20) & 0x1F
    funct7 = (w >> 25) & 0x7F
    next_pc = pc + 4

    if opcode == 0b0110011:  # R-type
        a, b = regs[rs1], regs[rs2]
        if funct3 == 0: val = a - b if funct7 & 0x20 else a + b
        elif funct3 == 0b111: val = a & b
        elif funct3 == 0b110: val = a | b
        elif funct3 == 0b100: val = a ^ b
        elif funct3 == 0b010: val = 1 if sext(a,32) < sext(b,32) else 0
        elif funct3 == 0b011: val = 1 if u32(a) < u32(b) else 0
        elif funct3 == 0b001: val = a << (b & 0x1F)
        elif funct3 == 0b101:
            val = (u32(a) >> (b & 0x1F)) if not (funct7 & 0x20) else u32(sext(a,32) >> (b & 0x1F))
        regs[rd] = u32(val)
    elif opcode == 0b0010011:  # I-type ALU imm
        imm = sext(w >> 20, 12)
        a = regs[rs1]
        if funct3 == 0: val = a + imm
        elif funct3 == 0b111: val = a & u32(imm)
        elif funct3 == 0b110: val = a | u32(imm)
        elif funct3 == 0b100: val = a ^ u32(imm)
        elif funct3 == 0b010: val = 1 if sext(a,32) < imm else 0
        elif funct3 == 0b011: val = 1 if u32(a) < u32(imm) else 0
        elif funct3 == 0b001: val = a << (imm & 0x1F)
        elif funct3 == 0b101:
            shamt = imm & 0x1F
            val = (u32(a) >> shamt) if not (funct7 & 0x20) else u32(sext(a,32) >> shamt)
        regs[rd] = u32(val)
    elif opcode == 0b0000011:  # loads
        imm = sext(w >> 20, 12)
        addr = u32(regs[rs1] + imm)
        if funct3 == 0: regs[rd] = u32(sext(rd_mem(addr,0),8))
        elif funct3 == 1: regs[rd] = u32(sext(rd_mem(addr,1),16))
        elif funct3 == 2: regs[rd] = u32(rd_mem(addr,2))
        elif funct3 == 4: regs[rd] = rd_mem(addr,0)
        elif funct3 == 5: regs[rd] = rd_mem(addr,1)
    elif opcode == 0b0100011:  # stores
        imm11_5 = (w >> 25) & 0x7F
        imm4_0 = (w >> 7) & 0x1F
        imm = sext((imm11_5 << 5) | imm4_0, 12)
        addr = u32(regs[rs1] + imm)
        size = {0:0,1:1,2:2}[funct3]
        wr_mem(addr, size, regs[rs2])
    elif opcode == 0b1100011:  # branch
        b12 = (w >> 31) & 1; b11 = (w >> 7) & 1; b10_5 = (w >> 25) & 0x3F; b4_1 = (w >> 8) & 0xF
        imm = sext((b12<<12)|(b11<<11)|(b10_5<<5)|(b4_1<<1), 13)
        a, b = regs[rs1], regs[rs2]
        taken = False
        if funct3 == 0: taken = a == b
        elif funct3 == 1: taken = a != b
        elif funct3 == 4: taken = sext(a,32) < sext(b,32)
        elif funct3 == 5: taken = sext(a,32) >= sext(b,32)
        elif funct3 == 6: taken = u32(a) < u32(b)
        elif funct3 == 7: taken = u32(a) >= u32(b)
        if taken: next_pc = u32(pc + imm)
    elif opcode == 0b1101111:  # JAL
        b20 = (w>>31)&1; b19_12=(w>>12)&0xFF; b11=(w>>20)&1; b10_1=(w>>21)&0x3FF
        imm = sext((b20<<20)|(b19_12<<12)|(b11<<11)|(b10_1<<1), 21)
        regs[rd] = u32(pc + 4)
        next_pc = u32(pc + imm)
    elif opcode == 0b1100111:  # JALR
        imm = sext(w >> 20, 12)
        target = u32(regs[rs1] + imm) & ~1
        regs[rd] = u32(pc + 4)
        next_pc = target
    elif opcode == 0b0110111:  # LUI
        regs[rd] = w & 0xFFFFF000
    elif opcode == 0b0010111:  # AUIPC
        regs[rd] = u32(pc + (w & 0xFFFFF000))
    else:
        raise ValueError(f"unknown opcode at pc={pc}: {w:08x}")

    regs[0] = 0
    does_write = opcode not in (0b0100011, 0b1100011) and rd != 0
    trace.append({
        "pc": pc,
        "next_pc": next_pc,
        "rd": rd if does_write else 0,
        "val": u32(regs[rd]) if does_write else 0,
        "write": does_write,
    })
    if pc == labels['halt'] and next_pc == pc:
        break
    pc = next_pc
    steps += 1

print(f"; simulator halted after {steps} steps at pc={pc}")
print(";")
print("; ---- final register file ----")
for i in range(32):
    print(f"; x{i:<2d} = 0x{regs[i]:08X}")

print(";")
print("; ---- relevant data memory (base=64) ----")
for off in [0,4,8,12]:
    print(f"; mem[64+{off:2d}] word = 0x{rd_mem(64+off,2):08X}")

print(";")
print("; ---- labels (addresses) ----")
for name, a in labels.items():
    print(f"; {name} = {a}")

# ---------------- emit SV per-cycle expected-trace arrays ----------------
n = len(trace)
with open("sim/trace_arrays.svh", "w") as f:
    f.write(f"localparam int N_STEPS = {n};\n\n")
    f.write("logic [31:0] exp_pc   [0:N_STEPS-1];\n")
    f.write("int          exp_rd   [0:N_STEPS-1];\n")
    f.write("logic [31:0] exp_val  [0:N_STEPS-1];\n")
    f.write("bit          exp_write[0:N_STEPS-1];\n\n")
    addr_to_line = {a: l for a, l in instrs}
    f.write("initial begin\n")
    for i, t in enumerate(trace):
        mnemonic = addr_to_line.get(t['pc'], '?')
        f.write(f"    exp_pc[{i}]='h{t['next_pc']:03X}; exp_rd[{i}]={t['rd']:2d}; "
                f"exp_val[{i}]=32'h{t['val']:08X}; exp_write[{i}]={1 if t['write'] else 0}; "
                f"// [{i}] addr={t['pc']:3d}: {mnemonic}\n")
    f.write("end\n\n")

    f.write("logic [31:0] exp_final_regs[0:31];\n")
    f.write("initial begin\n")
    for i in range(32):
        f.write(f"    exp_final_regs[{i}] = 32'h{regs[i]:08X};\n")
    f.write("end\n")
print("wrote sim/trace_arrays.svh")
