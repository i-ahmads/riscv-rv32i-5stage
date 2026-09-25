library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

-- Worked-example testbench for the report walkthrough (Section 7.7).
-- Drives cpu_top_worked through the three-instruction sequence
--   ADDI x1, x0, 5
--   ADDI x2, x0, 3
--   ADD  x3, x1, x2
-- and prints, on every clock edge, exactly which instruction (identified
-- by its destination register) is sitting in each of the five pipeline
-- stages, together with the live forwarding-mux selects and operand
-- values feeding the ALU in EX. This is the same dbg_addr / dbg_data
-- debug port pattern used by tb_cpu_top.vhd for the final register check;
-- the only addition here is the per-stage trace, which exists solely to
-- make the cycle-by-cycle table in the report traceable back to real
-- simulation output rather than a hand-drawn diagram.
entity tb_worked_example is
end entity tb_worked_example;

architecture sim of tb_worked_example is
  signal clk      : std_logic := '0';
  signal reset    : std_logic := '1';
  signal dbg_addr : std_logic_vector(4 downto 0) := (others => '0');
  signal dbg_data : std_logic_vector(31 downto 0);
  signal dbg_pc   : std_logic_vector(31 downto 0);

  signal tr_ifid_instr       : std_logic_vector(31 downto 0);
  signal tr_idex_rd_addr     : std_logic_vector(4 downto 0);
  signal tr_idex_rs1_data    : std_logic_vector(31 downto 0);
  signal tr_idex_rs2_data    : std_logic_vector(31 downto 0);
  signal tr_ex_forward_a     : std_logic_vector(1 downto 0);
  signal tr_ex_forward_b     : std_logic_vector(1 downto 0);
  signal tr_ex_operand_a     : std_logic_vector(31 downto 0);
  signal tr_ex_operand_b     : std_logic_vector(31 downto 0);
  signal tr_ex_alu_result    : std_logic_vector(31 downto 0);
  signal tr_exmem_rd_addr    : std_logic_vector(4 downto 0);
  signal tr_exmem_alu_result : std_logic_vector(31 downto 0);
  signal tr_memwb_rd_addr    : std_logic_vector(4 downto 0);
  signal tr_wb_rd_data       : std_logic_vector(31 downto 0);

  constant CLK_PERIOD : time := 10 ns;

  procedure check(signal dbg_addr_s : out std_logic_vector(4 downto 0);
                   signal dbg_data_s : in  std_logic_vector(31 downto 0);
                   addr : integer; expected : integer; reg_label : string;
                   variable pass_count : inout integer;
                   variable fail_count : inout integer) is
    variable l : line;
  begin
    dbg_addr_s <= std_logic_vector(to_unsigned(addr, 5));
    wait for 1 ns;
    if to_integer(signed(dbg_data_s)) = expected then
      write(l, string'("  PASS  x"));
      write(l, reg_label);
      write(l, string'(" = "));
      write(l, to_integer(signed(dbg_data_s)));
      writeline(output, l);
      pass_count := pass_count + 1;
    else
      write(l, string'("  FAIL  x"));
      write(l, reg_label);
      write(l, string'(" = "));
      write(l, to_integer(signed(dbg_data_s)));
      write(l, string'(" (expected "));
      write(l, expected);
      write(l, string'(")"));
      writeline(output, l);
      fail_count := fail_count + 1;
    end if;
  end procedure;

begin

  u_dut : entity work.cpu_top_worked
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

  clk_gen : process
  begin
    clk <= '0'; wait for CLK_PERIOD/2;
    clk <= '1'; wait for CLK_PERIOD/2;
  end process;

  stim : process
    variable l : line;
    variable pass_count : integer := 0;
    variable fail_count : integer := 0;
  begin
    reset <= '1';
    wait for CLK_PERIOD * 2;
    reset <= '0';

    write(l, string'("cyc | IF pc     | ID rd | EX rd fwdA fwdB opA        opB        alu        | MEM rd alu        | WB rd data"));
    writeline(output, l);
    write(l, string'("----+-----------+-------+---------------------------------------------------+---------------------+----------------"));
    writeline(output, l);

    for i in 0 to 9 loop
      wait until rising_edge(clk);
      wait for 1 ns;  -- let combinational taps settle after the edge

      write(l, i, right, 3);
      write(l, string'(" | 0x"));
      hwrite(l, dbg_pc);
      write(l, string'(" |   "));
      write(l, to_integer(unsigned(tr_ifid_instr(11 downto 7))), right, 2);
      write(l, string'("  |  "));
      write(l, to_integer(unsigned(tr_idex_rd_addr)), right, 2);
      write(l, string'("   "));
      write(l, to_integer(unsigned(tr_ex_forward_a)), right, 2);
      write(l, string'("   "));
      write(l, to_integer(unsigned(tr_ex_forward_b)), right, 2);
      write(l, string'("  "));
      write(l, to_integer(signed(tr_ex_operand_a)), right, 10);
      write(l, string'(" "));
      write(l, to_integer(signed(tr_ex_operand_b)), right, 10);
      write(l, string'(" "));
      write(l, to_integer(signed(tr_ex_alu_result)), right, 10);
      write(l, string'("  |   "));
      write(l, to_integer(unsigned(tr_exmem_rd_addr)), right, 2);
      write(l, string'("  "));
      write(l, to_integer(signed(tr_exmem_alu_result)), right, 10);
      write(l, string'("  |   "));
      write(l, to_integer(unsigned(tr_memwb_rd_addr)), right, 2);
      write(l, string'("  "));
      write(l, to_integer(signed(tr_wb_rd_data)), right, 6);
      writeline(output, l);
    end loop;

    write(l, string'("---------------------------------------------"));
    writeline(output, l);
    write(l, string'("Final architectural register check:"));
    writeline(output, l);

    check(dbg_addr, dbg_data, 1, 5, "1 ", pass_count, fail_count);
    check(dbg_addr, dbg_data, 2, 3, "2 ", pass_count, fail_count);
    check(dbg_addr, dbg_data, 3, 8, "3 ", pass_count, fail_count);

    write(l, string'("---------------------------------------------"));
    writeline(output, l);
    write(l, string'("Result: "));
    write(l, pass_count);
    write(l, string'(" passed, "));
    write(l, fail_count);
    write(l, string'(" failed"));
    writeline(output, l);

    assert fail_count = 0
      report "TESTBENCH FAILED - see FAIL lines above"
      severity failure;

    report "TESTBENCH PASSED - all checks correct";
    wait;
  end process;

end architecture sim;
