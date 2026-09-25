library ieee;
use ieee.std_logic_1164.all;

-- Illustrative-only top level for the worked-example walkthrough (report
-- Section 7.7). Structurally identical to cpu_top.vhd -- a thin wrapper
-- around the datapath -- except it wraps datapath_worked instead of
-- datapath, to expose the extra per-stage trace ports the walkthrough
-- testbench reads.
entity cpu_top_worked is
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    dbg_addr : in  std_logic_vector(4 downto 0) := (others => '0');
    dbg_data : out std_logic_vector(31 downto 0);
    dbg_pc   : out std_logic_vector(31 downto 0);

    tr_ifid_instr       : out std_logic_vector(31 downto 0);
    tr_idex_rd_addr      : out std_logic_vector(4 downto 0);
    tr_idex_rs1_data     : out std_logic_vector(31 downto 0);
    tr_idex_rs2_data     : out std_logic_vector(31 downto 0);
    tr_ex_forward_a      : out std_logic_vector(1 downto 0);
    tr_ex_forward_b      : out std_logic_vector(1 downto 0);
    tr_ex_operand_a      : out std_logic_vector(31 downto 0);
    tr_ex_operand_b      : out std_logic_vector(31 downto 0);
    tr_ex_alu_result     : out std_logic_vector(31 downto 0);
    tr_exmem_rd_addr     : out std_logic_vector(4 downto 0);
    tr_exmem_alu_result  : out std_logic_vector(31 downto 0);
    tr_memwb_rd_addr     : out std_logic_vector(4 downto 0);
    tr_wb_rd_data        : out std_logic_vector(31 downto 0)
  );
end entity cpu_top_worked;

architecture rtl of cpu_top_worked is
begin
  u_datapath : entity work.datapath_worked
    port map (clk => clk, reset => reset,
              dbg_addr => dbg_addr, dbg_data => dbg_data, dbg_pc => dbg_pc,
              tr_ifid_instr       => tr_ifid_instr,
              tr_idex_rd_addr     => tr_idex_rd_addr,
              tr_idex_rs1_data    => tr_idex_rs1_data,
              tr_idex_rs2_data    => tr_idex_rs2_data,
              tr_ex_forward_a     => tr_ex_forward_a,
              tr_ex_forward_b     => tr_ex_forward_b,
              tr_ex_operand_a     => tr_ex_operand_a,
              tr_ex_operand_b     => tr_ex_operand_b,
              tr_ex_alu_result    => tr_ex_alu_result,
              tr_exmem_rd_addr    => tr_exmem_rd_addr,
              tr_exmem_alu_result => tr_exmem_alu_result,
              tr_memwb_rd_addr    => tr_memwb_rd_addr,
              tr_wb_rd_data       => tr_wb_rd_data);
end architecture rtl;
