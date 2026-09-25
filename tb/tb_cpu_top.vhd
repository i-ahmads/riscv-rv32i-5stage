library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity tb_cpu_top is
end entity tb_cpu_top;

architecture sim of tb_cpu_top is
  signal clk      : std_logic := '0';
  signal reset    : std_logic := '1';
  signal dbg_addr : std_logic_vector(4 downto 0) := (others => '0');
  signal dbg_data : std_logic_vector(31 downto 0);
  signal dbg_pc   : std_logic_vector(31 downto 0);

  constant CLK_PERIOD : time := 10 ns;
  signal cycle_count  : integer := 0;

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
      write(l, string'("  PASS  x") );
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

  u_dut : entity work.cpu_top
    port map (clk => clk, reset => reset, dbg_addr => dbg_addr, dbg_data => dbg_data, dbg_pc => dbg_pc);

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

    -- run long enough for the full-coverage program (real instructions end
    -- well before the 256-word ROM boundary, so no wraparound risk here)
    for i in 0 to 199 loop
      wait until rising_edge(clk);
      write(l, string'("cycle "));
      write(l, i);
      write(l, string'("  PC = 0x"));
      hwrite(l, dbg_pc);
      writeline(output, l);
    end loop;

    write(l, string'("---------------------------------------------"));
    writeline(output, l);
    write(l, string'("Final architectural register check:"));
    writeline(output, l);

    check(dbg_addr, dbg_data, 3, 5, "3 ", pass_count, fail_count);
    check(dbg_addr, dbg_data, 4, 20, "4 ", pass_count, fail_count);
    check(dbg_addr, dbg_data, 5, 536870912, "5 ", pass_count, fail_count);
    check(dbg_addr, dbg_data, 6, -536870912, "6 ", pass_count, fail_count);
    check(dbg_addr, dbg_data, 7, 1, "7 ", pass_count, fail_count);
    check(dbg_addr, dbg_data, 8, 0, "8 ", pass_count, fail_count);
    check(dbg_addr, dbg_data, 9, -2147483648, "9 ", pass_count, fail_count);
    check(dbg_addr, dbg_data, 12, -2147483648, "12", pass_count, fail_count);
    check(dbg_addr, dbg_data, 13, 105, "13", pass_count, fail_count);
    check(dbg_addr, dbg_data, 14, 4140, "14", pass_count, fail_count);
    check(dbg_addr, dbg_data, 16, 269, "16", pass_count, fail_count);
    check(dbg_addr, dbg_data, 17, 5, "17", pass_count, fail_count);
    check(dbg_addr, dbg_data, 18, -128, "18", pass_count, fail_count);
    check(dbg_addr, dbg_data, 19, 128, "19", pass_count, fail_count);
    check(dbg_addr, dbg_data, 20, -128, "20", pass_count, fail_count);
    check(dbg_addr, dbg_data, 21, 65408, "21", pass_count, fail_count);
    check(dbg_addr, dbg_data, 22, 1450770186, "22", pass_count, fail_count);
    check(dbg_addr, dbg_data, 23, -1393426924, "23", pass_count, fail_count);
    check(dbg_addr, dbg_data, 24, 111, "24", pass_count, fail_count);
    check(dbg_addr, dbg_data, 25, 112, "25", pass_count, fail_count);
    check(dbg_addr, dbg_data, 26, 113, "26", pass_count, fail_count);
    check(dbg_addr, dbg_data, 27, 114, "27", pass_count, fail_count);
    check(dbg_addr, dbg_data, 28, 115, "28", pass_count, fail_count);
    check(dbg_addr, dbg_data, 29, 116, "29", pass_count, fail_count);
    check(dbg_addr, dbg_data, 30, 117, "30", pass_count, fail_count);
    check(dbg_addr, dbg_data, 31, 243, "31", pass_count, fail_count);

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
