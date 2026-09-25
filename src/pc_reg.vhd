library ieee;
use ieee.std_logic_1164.all;

entity pc_reg is
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    stall    : in  std_logic;                       -- '1' = hold current PC
    pc_next  : in  std_logic_vector(31 downto 0);
    pc       : out std_logic_vector(31 downto 0)
  );
end entity pc_reg;

architecture rtl of pc_reg is
  signal pc_r : std_logic_vector(31 downto 0) := (others => '0');
begin
  process (clk, reset)
  begin
    if reset = '1' then
      pc_r <= (others => '0');
    elsif rising_edge(clk) then
      if stall = '0' then
        pc_r <= pc_next;
      end if;
    end if;
  end process;
  pc <= pc_r;
end architecture rtl;
