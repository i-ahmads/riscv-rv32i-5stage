library ieee;
use ieee.std_logic_1164.all;

entity if_id_reg is
  port (
    clk        : in  std_logic;
    reset      : in  std_logic;
    stall      : in  std_logic;  -- hold current contents (load-use hazard)
    flush      : in  std_logic;  -- clear to bubble (branch taken in EX)
    pc_in      : in  std_logic_vector(31 downto 0);
    pc4_in     : in  std_logic_vector(31 downto 0);
    instr_in   : in  std_logic_vector(31 downto 0);
    pc_out     : out std_logic_vector(31 downto 0);
    pc4_out    : out std_logic_vector(31 downto 0);
    instr_out  : out std_logic_vector(31 downto 0)
  );
end entity if_id_reg;

architecture rtl of if_id_reg is
  signal pc_r, pc4_r, instr_r : std_logic_vector(31 downto 0) := (others => '0');
begin
  process (clk, reset)
  begin
    if reset = '1' then
      pc_r    <= (others => '0');
      pc4_r   <= (others => '0');
      instr_r <= (others => '0');
    elsif rising_edge(clk) then
      if flush = '1' then
        pc_r    <= (others => '0');
        pc4_r   <= (others => '0');
        instr_r <= (others => '0');
      elsif stall = '0' then
        pc_r    <= pc_in;
        pc4_r   <= pc4_in;
        instr_r <= instr_in;
      end if;
      -- stall='1' and flush='0': hold current contents
    end if;
  end process;

  pc_out    <= pc_r;
  pc4_out   <= pc4_r;
  instr_out <= instr_r;
end architecture rtl;
