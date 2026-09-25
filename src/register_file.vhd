library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
  port (
    clk       : in  std_logic;
    rs1_addr  : in  std_logic_vector(4 downto 0);
    rs2_addr  : in  std_logic_vector(4 downto 0);
    rd_addr   : in  std_logic_vector(4 downto 0);
    rd_data   : in  std_logic_vector(31 downto 0);
    reg_write : in  std_logic;
    rs1_data  : out std_logic_vector(31 downto 0);
    rs2_data  : out std_logic_vector(31 downto 0);

    -- simulation/debug-only read port, no hazard bypass, for the testbench
    -- to inspect final architectural state; not part of the pipeline datapath
    dbg_addr  : in  std_logic_vector(4 downto 0) := (others => '0');
    dbg_data  : out std_logic_vector(31 downto 0)
  );
end entity register_file;

architecture rtl of register_file is
  type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);
  signal regs : reg_array := (others => (others => '0'));
begin

  process (clk)
  begin
    if rising_edge(clk) then
      if reg_write = '1' and rd_addr /= "00000" then
        regs(to_integer(unsigned(rd_addr))) <= rd_data;
      end if;
    end if;
  end process;

  -- Combinational read with write-through bypass: if the instruction in WB
  -- is writing the same register this ID stage is reading this cycle, hand
  -- it the new value directly instead of the (stale until next edge) array
  -- contents. x0 always reads zero regardless of any write.
  process (rs1_addr, rs2_addr, rd_addr, rd_data, reg_write, regs)
  begin
    if rs1_addr = "00000" then
      rs1_data <= (others => '0');
    elsif reg_write = '1' and rd_addr = rs1_addr then
      rs1_data <= rd_data;
    else
      rs1_data <= regs(to_integer(unsigned(rs1_addr)));
    end if;

    if rs2_addr = "00000" then
      rs2_data <= (others => '0');
    elsif reg_write = '1' and rd_addr = rs2_addr then
      rs2_data <= rd_data;
    else
      rs2_data <= regs(to_integer(unsigned(rs2_addr)));
    end if;
  end process;

  dbg_data <= (others => '0') when dbg_addr = "00000" else regs(to_integer(unsigned(dbg_addr)));

end architecture rtl;
