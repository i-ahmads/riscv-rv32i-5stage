library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Same FPGA note as instr_mem.vhd: combinational read here for simulation
-- simplicity; add a registered read stage before real synthesis so XST
-- infers Block RAM.
entity data_mem is
  port (
    clk       : in  std_logic;
    addr      : in  std_logic_vector(31 downto 0);
    write_data: in  std_logic_vector(31 downto 0);
    mem_write : in  std_logic;
    mem_read  : in  std_logic;
    read_data : out std_logic_vector(31 downto 0)
  );
end entity data_mem;

architecture rtl of data_mem is
  type ram_array is array (0 to 63) of std_logic_vector(31 downto 0);
  signal ram : ram_array := (others => (others => '0'));
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if mem_write = '1' then
        ram(to_integer(unsigned(addr(7 downto 2)))) <= write_data;
      end if;
    end if;
  end process;

  read_data <= ram(to_integer(unsigned(addr(7 downto 2))));
end architecture rtl;
