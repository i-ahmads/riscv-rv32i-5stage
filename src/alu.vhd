library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_pkg.all;

entity alu is
  port (
    a, b     : in  std_logic_vector(31 downto 0);
    alu_ctrl : in  std_logic_vector(3 downto 0);
    result   : out std_logic_vector(31 downto 0);
    zero     : out std_logic
  );
end entity alu;

architecture rtl of alu is
  signal res : std_logic_vector(31 downto 0);
begin
  process (a, b, alu_ctrl)
    variable shamt : integer range 0 to 31;
  begin
    shamt := to_integer(unsigned(b(4 downto 0)));
    case alu_ctrl is
      when ALU_ADD => res <= std_logic_vector(unsigned(a) + unsigned(b));
      when ALU_SUB => res <= std_logic_vector(unsigned(a) - unsigned(b));
      when ALU_AND => res <= a and b;
      when ALU_OR  => res <= a or b;
      when ALU_XOR => res <= a xor b;
      when ALU_SLT =>
        if signed(a) < signed(b) then
          res <= (0 => '1', others => '0');
        else
          res <= (others => '0');
        end if;
      when ALU_SLTU =>
        if unsigned(a) < unsigned(b) then
          res <= (0 => '1', others => '0');
        else
          res <= (others => '0');
        end if;
      when ALU_SLL => res <= std_logic_vector(shift_left(unsigned(a), shamt));
      when ALU_SRL => res <= std_logic_vector(shift_right(unsigned(a), shamt));
      when ALU_SRA => res <= std_logic_vector(shift_right(signed(a), shamt));
      when others  => res <= (others => '0');
    end case;
  end process;

  result <= res;
  zero   <= '1' when res = x"00000000" else '0';
end architecture rtl;
