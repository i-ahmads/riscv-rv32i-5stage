#!/usr/bin/env python3
"""
Full-coverage RV32I integration test program + Python reference model.
Register plan (verified zero-overlap before writing this):
  scratch (freely reused, never checked): x1,x2,x9,x10,x11,x12,x15
  results (write-once, checked at end):   x3-x8,x13,x14,x16-x31
Exhaustive per-opcode ALU correctness is NOT this program's job -- that's
tb_alu.vhd's job. This program proves pipeline control correctness
(forwarding, load-use stall, branch/jump flush) across a representative
instruction mix.
"""
import sys

MASK32 = 0xFFFFFFFF
def s32(x):
    x &= MASK32
    return x - (1 << 32) if x & 0x80000000 else x
def u32(x): return x & MASK32
def r(x, n): return format(x & ((1 << n) - 1), f'0{n}b')

def rtype(f7,rs2,rs1,f3,rd,op): return r(f7,7)+r(rs2,5)+r(rs1,5)+r(f3,3)+r(rd,5)+r(op,7)
def itype(imm,rs1,f3,rd,op):    return r(imm,12)+r(rs1,5)+r(f3,3)+r(rd,5)+r(op,7)
def stype(imm,rs2,rs1,f3,op):   return r((imm>>5)&0x7F,7)+r(rs2,5)+r(rs1,5)+r(f3,3)+r(imm&0x1F,5)+r(op,7)
def btype(imm,rs2,rs1,f3,op):
    b12,b10_5,b4_1,b11=(imm>>12)&1,(imm>>5)&0x3F,(imm>>1)&0xF,(imm>>11)&1
    return r(b12,1)+r(b10_5,6)+r(rs2,5)+r(rs1,5)+r(f3,3)+r(b4_1,4)+r(b11,1)+r(op,7)
def utype(imm20,rd,op): return r(imm20,20)+r(rd,5)+r(op,7)
def jtype(imm,rd,op):
    b20,b10_1,b11,b19_12=(imm>>20)&1,(imm>>1)&0x3FF,(imm>>11)&1,(imm>>12)&0xFF
    return r(b20,1)+r(b10_1,10)+r(b11,1)+r(b19_12,8)+r(rd,5)+r(op,7)

OP_IMM=0b0010011; OP=0b0110011; LOAD=0b0000011; STORE=0b0100011
BRANCH=0b1100011; JAL=0b1101111; JALR=0b1100111; LUI=0b0110111; AUIPC=0b0010111

def addi(rd,rs1,imm): return itype(imm,rs1,0b000,rd,OP_IMM)
def add_r(rd,rs1,rs2): return rtype(0,rs2,rs1,0b000,rd,OP)
def sub_(rd,rs1,rs2): return rtype(0b0100000,rs2,rs1,0b000,rd,OP)
def sll_(rd,rs1,rs2): return rtype(0,rs2,rs1,0b001,rd,OP)
def srl_(rd,rs1,rs2): return rtype(0,rs2,rs1,0b101,rd,OP)
def sra_(rd,rs1,rs2): return rtype(0b0100000,rs2,rs1,0b101,rd,OP)
def slt_(rd,rs1,rs2): return rtype(0,rs2,rs1,0b010,rd,OP)
def sltu_(rd,rs1,rs2):return rtype(0,rs2,rs1,0b011,rd,OP)

def lw(rd,imm,rs1):  return itype(imm,rs1,0b010,rd,LOAD)
def lh(rd,imm,rs1):  return itype(imm,rs1,0b001,rd,LOAD)
def lhu(rd,imm,rs1): return itype(imm,rs1,0b101,rd,LOAD)
def lb(rd,imm,rs1):  return itype(imm,rs1,0b000,rd,LOAD)
def lbu(rd,imm,rs1): return itype(imm,rs1,0b100,rd,LOAD)
def sw(rs2,imm,rs1): return stype(imm,rs2,rs1,0b010,STORE)
def sh(rs2,imm,rs1): return stype(imm,rs2,rs1,0b001,STORE)
def sb(rs2,imm,rs1): return stype(imm,rs2,rs1,0b000,STORE)

def beq(rs1,rs2,imm): return btype(imm,rs2,rs1,0b000,BRANCH)
def bne(rs1,rs2,imm): return btype(imm,rs2,rs1,0b001,BRANCH)
def blt(rs1,rs2,imm): return btype(imm,rs2,rs1,0b100,BRANCH)
def bge(rs1,rs2,imm): return btype(imm,rs2,rs1,0b101,BRANCH)
def bltu(rs1,rs2,imm):return btype(imm,rs2,rs1,0b110,BRANCH)
def bgeu(rs1,rs2,imm):return btype(imm,rs2,rs1,0b111,BRANCH)

def jal(rd,imm):      return jtype(imm,rd,JAL)
def jalr(rd,rs1,imm): return itype(imm,rs1,0b000,rd,JALR)
def lui_raw(rd,imm20):   return utype(imm20,rd,LUI)
def auipc_raw(rd,imm20): return utype(imm20,rd,AUIPC)
def nop(): return addi(0,0,0)

prog = []
def emit(b):
    assert len(b) == 32
    prog.append(b)
def here(): return len(prog) * 4

expected = {}
def setreg(n, v):
    if n != 0: expected[n] = s32(v)

def li(rd, imm32):
    imm32 = u32(imm32); lo = imm32 & 0xFFF
    if lo & 0x800:
        hi20 = ((imm32 >> 12) + 1) & 0xFFFFF; lo_signed = lo - 0x1000
    else:
        hi20 = (imm32 >> 12) & 0xFFFFF; lo_signed = lo
    emit(lui_raw(rd, hi20)); emit(addi(rd, rd, lo_signed)); setreg(rd, imm32)

def lui(rd, imm32):
    imm32 = u32(imm32) & 0xFFFFF000
    emit(lui_raw(rd, (imm32 >> 12) & 0xFFFFF)); setreg(rd, imm32)

def byte_of(w,l): return (w>>(8*l))&0xFF
def half_of(w,l): return (w>>(16*l))&0xFFFF
def sext(v,bits):
    m = 1<<(bits-1); return (v^m)-m

# ============================================================ the program
# x1,x2,x9,x10,x11,x12,x15 = scratch only, never checked at the end.

# ---- R-type ALU (representative subset; exhaustive coverage is tb_alu.vhd's job) ----
emit(addi(1, 0, 5))                       # scratch: 5
emit(addi(2, 0, 10))                      # scratch: 10
emit(sub_(3, 2, 1));  setreg(3, 10-5)
emit(addi(9, 0, 2))                       # scratch: shift amount = 2
lui(12, 0x80000000)                       # scratch: MSB-set pattern (also result-checked below via reuse is NOT done - x12 stays scratch)
emit(sll_(4, 1, 9));   setreg(4, u32(5 << 2))
emit(srl_(5, 12, 9));  setreg(5, u32(0x80000000) >> 2)
emit(sra_(6, 12, 9));  setreg(6, s32(s32(0x80000000) >> 2))
emit(slt_(7, 12, 1));  setreg(7, 1 if s32(0x80000000) < 5 else 0)
emit(sltu_(8, 12, 1)); setreg(8, 1 if u32(0x80000000) < 5 else 0)

# ---- I-type ALU (representative) ----
emit(addi(13, 1, 100)); setreg(13, 5 + 100)

# ---- AUIPC ----
auipc_addr = here()
emit(auipc_raw(14, 0x00001)); setreg(14, s32(u32(auipc_addr + 0x1000)))

# ---- word store/load round trip (also proves SUB's value made it to memory) ----
emit(sw(3, 0, 0))
emit(lw(17, 0, 0)); setreg(17, expected[3])

# ---- byte/halfword load-store correctness ----
li(15, 0x1234FF80)                        # scratch: test word
WORD_ADDR = 0x40
emit(sw(15, WORD_ADDR, 0))
stored_word = expected[15] & MASK32 if 15 in expected else 0x1234FF80
# (li() sets expected[15], but x15 is scratch-only by convention: ignore it)
del expected[15]

emit(lb(18, WORD_ADDR, 0));  setreg(18, sext(byte_of(stored_word,0), 8))
emit(lbu(19, WORD_ADDR, 0)); setreg(19, byte_of(stored_word,0))
emit(lh(20, WORD_ADDR, 0));  setreg(20, sext(half_of(stored_word,0), 16))
emit(lhu(21, WORD_ADDR, 0)); setreg(21, half_of(stored_word,0))

# SB then SH, single combined final-word check
emit(addi(1, 0, 0x0A))                    # scratch
emit(sb(1, WORD_ADDR, 0))
stored_word = (stored_word & 0xFFFFFF00) | 0x0A
li(2, 0x5678)                             # scratch (li() also sets expected[2]; discard it, x2 is scratch)
if 2 in expected: del expected[2]
emit(sh(2, WORD_ADDR + 2, 0))
stored_word = (stored_word & 0x0000FFFF) | (0x5678 << 16)
emit(lw(22, WORD_ADDR, 0)); setreg(22, s32(stored_word))

# ---- load-use hazard: 1-cycle stall + MEM/WB forward ----
emit(lw(1, WORD_ADDR, 0))                 # scratch (holds the just-verified word)
emit(add_r(23, 1, 1)); setreg(23, s32(u32(stored_word + stored_word)))

# ---- every branch condition, each guarded by a poison instruction ----
emit(addi(10, 0, 3))                      # scratch
emit(addi(11, 0, 2))                      # scratch
lui(9, 0x80000000)                        # scratch: refresh huge-unsigned pattern into x9

emit(beq(10, 10, 8));  emit(addi(24,0,999)); emit(addi(24,0,111)); setreg(24,111)  # BEQ  taken (3==3)
emit(bne(10, 11, 8));  emit(addi(25,0,999)); emit(addi(25,0,112)); setreg(25,112)  # BNE  taken (3!=2)
emit(blt(11, 10, 8));  emit(addi(26,0,999)); emit(addi(26,0,113)); setreg(26,113)  # BLT  taken (2<3)
emit(bge(10, 11, 8));  emit(addi(27,0,999)); emit(addi(27,0,114)); setreg(27,114)  # BGE  taken (3>=2)
emit(bltu(11, 9, 8));  emit(addi(28,0,999)); emit(addi(28,0,115)); setreg(28,115)  # BLTU taken (2 <u huge)
emit(bgeu(9, 11, 8));  emit(addi(29,0,999)); emit(addi(29,0,116)); setreg(29,116)  # BGEU taken (huge >=u 2)
emit(beq(10, 11, 8));  emit(addi(30,0,117)); setreg(30,117)                        # BEQ NOT taken (3!=2), single fallthrough instruction, nothing after to clobber it

# ---- JAL and JALR: each combined into one link+target check ----
jal_addr = here()
emit(jal(1, 8))                                       # scratch: x1 = jal_addr+4, jump +8
emit(addi(31, 0, 888))                                # skipped
emit(addi(31, 1, 31)); setreg(31, (jal_addr + 4) + 31) # target: x31 = link_reg + 31 (proves link value AND that target was reached)

jalr_addr = here()
jalr_target = jalr_addr + 8       # rs1=x0 -> JALR target = imm directly (absolute; program is well under 2KB)
emit(jalr(2, 0, jalr_target))                          # scratch: x2 = jalr_addr+4, jump to jalr_target
emit(addi(16, 0, 777))                                 # skipped
emit(addi(16, 2, 45)); setreg(16, (jalr_addr + 4) + 45) # target: x16 = link_reg + 45

# padding
print(f"real_instruction_count = {len(prog)} (last real addr = 0x{(len(prog)-1)*4:x})", file=sys.stderr)
while len(prog) < 256:
    emit(nop())

for b in prog:
    print(f'    x"{format(int(b,2), "08x")}",')

print("---EXPECTED---", file=sys.stderr)
for k in sorted(expected):
    print(f"x{k:<2d} = {expected[k]:>12d}  (0x{expected[k] & 0xFFFFFFFF:08x})", file=sys.stderr)
print(f"program length = {len(prog)} words = {len(prog)*4} bytes", file=sys.stderr)
