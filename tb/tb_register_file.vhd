library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity tb_register_file is
end entity tb_register_file;

architecture sim of tb_register_file is
  signal clk : std_logic := '0';
  signal rs1_addr, rs2_addr, rd_addr, dbg_addr : std_logic_vector(4 downto 0) := (others => '0');
  signal rd_data : std_logic_vector(31 downto 0) := (others => '0');
  signal reg_write : std_logic := '0';
  signal rs1_data, rs2_data, dbg_data : std_logic_vector(31 downto 0);
begin
  dut : entity work.register_file
    port map (clk => clk, rs1_addr => rs1_addr, rs2_addr => rs2_addr,
              rd_addr => rd_addr, rd_data => rd_data, reg_write => reg_write,
              rs1_data => rs1_data, rs2_data => rs2_data,
              dbg_addr => dbg_addr, dbg_data => dbg_data);

  clk_gen : process begin clk <= '0'; wait for 5 ns; clk <= '1'; wait for 5 ns; end process;

  stim : process
    variable l : line;
    variable pass_count, fail_count : integer := 0;
    procedure check(cond : boolean; name : string) is
    begin
      if cond then
        write(l, string'("  PASS  ")); write(l, name); writeline(output, l);
        pass_count := pass_count + 1;
      else
        write(l, string'("  FAIL  ")); write(l, name); writeline(output, l);
        fail_count := fail_count + 1;
      end if;
    end procedure;
  begin
    -- x0 always reads zero, even if you try to write it
    rd_addr <= "00000"; rd_data <= x"DEADBEEF"; reg_write <= '1';
    wait until rising_edge(clk); wait for 1 ns;
    dbg_addr <= "00000"; wait for 1 ns;
    check(dbg_data = x"00000000", "x0 stays zero after attempted write");

    -- basic write then read on a normal register
    rd_addr <= "00101"; rd_data <= x"0000002A"; reg_write <= '1'; -- x5 = 42
    wait until rising_edge(clk); wait for 1 ns;
    reg_write <= '0';
    rs1_addr <= "00101"; wait for 1 ns;
    check(rs1_data = x"0000002A", "basic write-then-read (x5=42)");

    dbg_addr <= "00101"; wait for 1 ns;
    check(dbg_data = x"0000002A", "debug port reads the same value");

    -- write-through bypass: same-cycle write to x6 while ID stage reads x6
    rd_addr <= "00110"; rd_data <= x"00000063"; reg_write <= '1'; -- writing 99 to x6
    rs1_addr <= "00110"; -- simultaneously trying to read x6 THIS same cycle
    wait for 1 ns;
    check(rs1_data = x"00000063",
          "write-through bypass: read sees the value being written this cycle, not stale data");
    wait until rising_edge(clk);
    reg_write <= '0';

    write(l, string'("-------------------------------------")); writeline(output, l);
    write(l, string'("register_file unit test: ")); write(l, pass_count);
    write(l, string'(" passed, ")); write(l, fail_count); write(l, string'(" failed"));
    writeline(output, l);
    assert fail_count = 0 report "REGISTER_FILE TESTBENCH FAILED" severity failure;
    report "REGISTER_FILE TESTBENCH PASSED";
    wait;
  end process;
end architecture sim;
