library ieee;
use ieee.std_logic_1164.all;
use work.riscv_pkg.all;

entity immediate_gen is
  port (
    instr : in  std_logic_vector(31 downto 0);
    imm   : out std_logic_vector(31 downto 0)
  );
end entity immediate_gen;

architecture rtl of immediate_gen is
  signal opcode : std_logic_vector(6 downto 0);
begin
  opcode <= instr(6 downto 0);

  process (instr, opcode)
    variable sign : std_logic;
  begin
    case opcode is
      when OPCODE_ITYPE | OPCODE_LOAD | OPCODE_JALR =>
        sign := instr(31);
        imm  <= (31 downto 12 => sign) & instr(31 downto 20);

      when OPCODE_STORE =>
        sign := instr(31);
        imm  <= (31 downto 12 => sign) & instr(31 downto 25) & instr(11 downto 7);

      when OPCODE_BRANCH =>
        sign := instr(31);
        imm  <= (31 downto 13 => sign) & instr(31) & instr(7) & instr(30 downto 25)
                & instr(11 downto 8) & '0';

      when OPCODE_JAL =>
        sign := instr(31);
        imm  <= (31 downto 21 => sign) & instr(31) & instr(19 downto 12)
                & instr(20) & instr(30 downto 21) & '0';

      when OPCODE_LUI | OPCODE_AUIPC =>
        imm <= instr(31 downto 12) & (11 downto 0 => '0');

      when others =>
        imm <= (others => '0');
    end case;
  end process;
end architecture rtl;
