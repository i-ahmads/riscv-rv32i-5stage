library ieee;
use ieee.std_logic_1164.all;

entity mem_wb_reg is
  port (
    clk   : in std_logic;
    reset : in std_logic;

    mem_data_in   : in std_logic_vector(31 downto 0);
    alu_result_in : in std_logic_vector(31 downto 0);
    rd_addr_in    : in std_logic_vector(4 downto 0);
    pc4_in        : in std_logic_vector(31 downto 0);

    reg_write_in  : in std_logic;
    result_src_in : in std_logic_vector(1 downto 0);

    mem_data_out   : out std_logic_vector(31 downto 0);
    alu_result_out : out std_logic_vector(31 downto 0);
    rd_addr_out    : out std_logic_vector(4 downto 0);
    pc4_out        : out std_logic_vector(31 downto 0);

    reg_write_out  : out std_logic;
    result_src_out : out std_logic_vector(1 downto 0)
  );
end entity mem_wb_reg;

architecture rtl of mem_wb_reg is
begin
  process (clk, reset)
  begin
    if reset = '1' then
      mem_data_out   <= (others => '0');
      alu_result_out <= (others => '0');
      rd_addr_out    <= (others => '0');
      pc4_out        <= (others => '0');
      reg_write_out  <= '0';
      result_src_out <= (others => '0');
    elsif rising_edge(clk) then
      mem_data_out   <= mem_data_in;
      alu_result_out <= alu_result_in;
      rd_addr_out    <= rd_addr_in;
      pc4_out        <= pc4_in;
      reg_write_out  <= reg_write_in;
      result_src_out <= result_src_in;
    end if;
  end process;
end architecture rtl;
