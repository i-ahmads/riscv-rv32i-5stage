library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Evaluates all six RV32I branch conditions directly, rather than reusing
-- the ALU's subtract+zero-flag trick (which only covers BEQ/BNE). Keeping
-- this separate from alu.vhd also means the ALU is free to do something
-- else (or nothing) on a branch instruction without any conflict.
entity branch_unit is
  port (
    a, b   : in  std_logic_vector(31 downto 0);
    funct3 : in  std_logic_vector(2 downto 0);
    taken  : out std_logic
  );
end entity branch_unit;

architecture rtl of branch_unit is
begin
  process (a, b, funct3)
  begin
    case funct3 is
      when "000" =>
        if a = b then taken <= '1'; else taken <= '0'; end if;             -- BEQ
      when "001" =>
        if a /= b then taken <= '1'; else taken <= '0'; end if;            -- BNE
      when "100" =>
        if signed(a) < signed(b) then taken <= '1'; else taken <= '0'; end if;   -- BLT
      when "101" =>
        if signed(a) >= signed(b) then taken <= '1'; else taken <= '0'; end if;  -- BGE
      when "110" =>
        if unsigned(a) < unsigned(b) then taken <= '1'; else taken <= '0'; end if;  -- BLTU
      when "111" =>
        if unsigned(a) >= unsigned(b) then taken <= '1'; else taken <= '0'; end if; -- BGEU
      when others => taken <= '0';
    end case;
  end process;
end architecture rtl;
