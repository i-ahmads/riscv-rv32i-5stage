library ieee;
use ieee.std_logic_1164.all;
use work.riscv_pkg.all;

entity control_unit is
  port (
    opcode      : in  std_logic_vector(6 downto 0);
    reg_write   : out std_logic;
    mem_read    : out std_logic;
    mem_write   : out std_logic;
    alu_src     : out std_logic;                     -- 0 = rs2, 1 = immediate
    branch      : out std_logic;
    jump        : out std_logic;                      -- JAL
    is_jalr     : out std_logic;                      -- JALR (register-indirect)
    op_a_sel    : out std_logic_vector(1 downto 0);   -- EX operand-A source
    alu_op      : out std_logic_vector(1 downto 0);
    result_src  : out std_logic_vector(1 downto 0);
    is_rtype    : out std_logic
  );
end entity control_unit;

architecture rtl of control_unit is
begin
  process (opcode)
  begin
    -- safe defaults (NOP-like, no side effects)
    reg_write  <= '0';
    mem_read   <= '0';
    mem_write  <= '0';
    alu_src    <= '0';
    branch     <= '0';
    jump       <= '0';
    is_jalr    <= '0';
    op_a_sel   <= OPA_RS1;
    alu_op     <= "10";
    result_src <= RESSRC_ALU;
    is_rtype   <= '0';

    case opcode is
      when OPCODE_RTYPE =>
        reg_write <= '1';
        alu_op    <= "10";
        is_rtype  <= '1';

      when OPCODE_ITYPE =>
        reg_write <= '1';
        alu_src   <= '1';
        alu_op    <= "10";
        is_rtype  <= '0';

      when OPCODE_LOAD =>
        reg_write  <= '1';
        mem_read   <= '1';
        alu_src    <= '1';
        alu_op     <= "00";
        result_src <= RESSRC_MEM;

      when OPCODE_STORE =>
        mem_write <= '1';
        alu_src   <= '1';
        alu_op    <= "00";

      when OPCODE_BRANCH =>
        branch <= '1';
        alu_op <= "00";  -- ALU unused for the branch decision itself

      when OPCODE_JAL =>
        reg_write  <= '1';
        jump       <= '1';
        result_src <= RESSRC_PC4;

      when OPCODE_JALR =>
        reg_write  <= '1';
        is_jalr    <= '1';
        alu_src    <= '1';   -- ALU computes rs1+imm, reused as the jump target
        alu_op     <= "00";
        result_src <= RESSRC_PC4;

      when OPCODE_LUI =>
        reg_write <= '1';
        alu_src   <= '1';
        alu_op    <= "00";
        op_a_sel  <= OPA_ZERO;  -- result = 0 + imm

      when OPCODE_AUIPC =>
        reg_write <= '1';
        alu_src   <= '1';
        alu_op    <= "00";
        op_a_sel  <= OPA_PC;    -- result = PC + imm

      when others =>
        null; -- unimplemented opcode: behaves as NOP
    end case;
  end process;
end architecture rtl;
