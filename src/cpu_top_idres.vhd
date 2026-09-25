library ieee;
use ieee.std_logic_1164.all;

entity cpu_top_idres is
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    dbg_addr : in  std_logic_vector(4 downto 0) := (others => '0');
    dbg_data : out std_logic_vector(31 downto 0);
    dbg_pc   : out std_logic_vector(31 downto 0)
  );
end entity cpu_top_idres;

architecture rtl of cpu_top_idres is
begin
  u_datapath : entity work.datapath_idres
    port map (clk => clk, reset => reset,
              dbg_addr => dbg_addr, dbg_data => dbg_data, dbg_pc => dbg_pc);
end architecture rtl;
