library ieee;
use ieee.std_logic_1164.all;

-- Shared opcode / ALU-control constants for the RV32I pipeline.
-- Scope: full RV32I base integer ISA (R-type, I-type ALU ops, loads/stores
-- incl. byte/halfword, all branches, JAL/JALR, LUI/AUIPC). FENCE/ECALL/
-- EBREAK/CSR system instructions are out of scope, as is anything from
-- the M/A/F/D/C extensions.
package riscv_pkg is

  constant OPCODE_RTYPE  : std_logic_vector(6 downto 0) := "0110011";
  constant OPCODE_ITYPE  : std_logic_vector(6 downto 0) := "0010011";
  constant OPCODE_LOAD   : std_logic_vector(6 downto 0) := "0000011";
  constant OPCODE_STORE  : std_logic_vector(6 downto 0) := "0100011";
  constant OPCODE_BRANCH : std_logic_vector(6 downto 0) := "1100011";
  constant OPCODE_JAL    : std_logic_vector(6 downto 0) := "1101111";
  constant OPCODE_JALR   : std_logic_vector(6 downto 0) := "1100111";
  constant OPCODE_LUI    : std_logic_vector(6 downto 0) := "0110111";
  constant OPCODE_AUIPC  : std_logic_vector(6 downto 0) := "0010111";

  -- Internal 4-bit ALU control codes (alu_control.vhd output, alu.vhd input)
  constant ALU_ADD  : std_logic_vector(3 downto 0) := "0000";
  constant ALU_SUB  : std_logic_vector(3 downto 0) := "0001";
  constant ALU_AND  : std_logic_vector(3 downto 0) := "0010";
  constant ALU_OR   : std_logic_vector(3 downto 0) := "0011";
  constant ALU_XOR  : std_logic_vector(3 downto 0) := "0100";
  constant ALU_SLT  : std_logic_vector(3 downto 0) := "0101";
  constant ALU_SLTU : std_logic_vector(3 downto 0) := "0110";
  constant ALU_SLL  : std_logic_vector(3 downto 0) := "0111";
  constant ALU_SRL  : std_logic_vector(3 downto 0) := "1000";
  constant ALU_SRA  : std_logic_vector(3 downto 0) := "1001";

  -- EX-stage "a" operand select: rs1 (default), current PC (AUIPC), or zero (LUI)
  constant OPA_RS1  : std_logic_vector(1 downto 0) := "00";
  constant OPA_PC   : std_logic_vector(1 downto 0) := "01";
  constant OPA_ZERO : std_logic_vector(1 downto 0) := "10";

  -- Result-select mux (mem_wb stage): what gets written back to the regfile
  constant RESSRC_ALU : std_logic_vector(1 downto 0) := "00";
  constant RESSRC_MEM : std_logic_vector(1 downto 0) := "01";
  constant RESSRC_PC4 : std_logic_vector(1 downto 0) := "10";

end package riscv_pkg;
