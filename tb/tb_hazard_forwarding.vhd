library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity tb_hazard_forwarding is
end entity tb_hazard_forwarding;

architecture sim of tb_hazard_forwarding is
  -- forwarding_unit signals
  signal f_idex_rs1, f_idex_rs2, f_exmem_rd, f_memwb_rd : std_logic_vector(4 downto 0) := (others=>'0');
  signal f_exmem_rw, f_memwb_rw : std_logic := '0';
  signal f_fwd_a, f_fwd_b : std_logic_vector(1 downto 0);

  -- hazard_detection_unit signals
  signal h_idex_memread : std_logic := '0';
  signal h_idex_rd, h_ifid_rs1, h_ifid_rs2 : std_logic_vector(4 downto 0) := (others=>'0');
  signal h_branch_taken : std_logic := '0';
  signal h_pc_stall, h_ifid_stall, h_ifid_flush, h_idex_flush : std_logic;

begin
  u_fwd : entity work.forwarding_unit
    port map (id_ex_rs1_addr => f_idex_rs1, id_ex_rs2_addr => f_idex_rs2,
              ex_mem_rd_addr => f_exmem_rd, ex_mem_reg_write => f_exmem_rw,
              mem_wb_rd_addr => f_memwb_rd, mem_wb_reg_write => f_memwb_rw,
              forward_a => f_fwd_a, forward_b => f_fwd_b);

  u_hz : entity work.hazard_detection_unit
    port map (id_ex_mem_read => h_idex_memread, id_ex_rd_addr => h_idex_rd,
              if_id_rs1_addr => h_ifid_rs1, if_id_rs2_addr => h_ifid_rs2,
              branch_taken => h_branch_taken,
              pc_stall => h_pc_stall, if_id_stall => h_ifid_stall,
              if_id_flush => h_ifid_flush, id_ex_flush => h_idex_flush);

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
    ------------------------------------------------------------ forwarding
    -- no hazard: nothing matches, both forwards should be "00"
    f_idex_rs1 <= "00011"; f_idex_rs2 <= "00100";
    f_exmem_rd <= "00101"; f_exmem_rw <= '1';
    f_memwb_rd <= "00110"; f_memwb_rw <= '1';
    wait for 1 ns;
    check(f_fwd_a = "00" and f_fwd_b = "00", "no forward when no address matches");

    -- EX/MEM forward on rs1 only
    f_idex_rs1 <= "00101"; f_idex_rs2 <= "00100";
    wait for 1 ns;
    check(f_fwd_a = "01" and f_fwd_b = "00", "EX/MEM forward on rs1 match");

    -- MEM/WB forward on rs2 only
    f_idex_rs1 <= "00011"; f_idex_rs2 <= "00110";
    wait for 1 ns;
    check(f_fwd_a = "00" and f_fwd_b = "10", "MEM/WB forward on rs2 match");

    -- EX/MEM takes priority over MEM/WB when both match the same register
    f_idex_rs1 <= "00101";
    f_memwb_rd <= "00101"; f_memwb_rw <= '1';   -- both EX/MEM and MEM/WB target x5 now
    wait for 1 ns;
    check(f_fwd_a = "01", "EX/MEM forwarding wins over MEM/WB when both match");

    -- x0 is never a valid forwarding source, even if reg_write is asserted
    f_exmem_rd <= "00000"; f_exmem_rw <= '1';
    f_idex_rs1 <= "00000";
    wait for 1 ns;
    check(f_fwd_a = "00", "x0 is never forwarded as a source");

    ------------------------------------------------------------ hazard unit
    -- load-use hazard: id_ex is a load into x3, if_id wants x3 as rs1
    h_idex_memread <= '1'; h_idex_rd <= "00011";
    h_ifid_rs1 <= "00011"; h_ifid_rs2 <= "00000";
    h_branch_taken <= '0';
    wait for 1 ns;
    check(h_pc_stall = '1' and h_ifid_stall = '1' and h_idex_flush = '1' and h_ifid_flush = '0',
          "load-use hazard stalls PC/IF-ID and bubbles ID/EX only");

    -- same load, but the following instruction doesn't actually use x3: no hazard
    h_ifid_rs1 <= "00100"; h_ifid_rs2 <= "00101";
    wait for 1 ns;
    check(h_pc_stall = '0' and h_ifid_stall = '0' and h_idex_flush = '0',
          "no stall when the load's destination isn't actually needed yet");

    -- branch taken: flushes IF/ID and ID/EX, no stall
    h_idex_memread <= '0'; h_branch_taken <= '1';
    wait for 1 ns;
    check(h_ifid_flush = '1' and h_idex_flush = '1' and h_pc_stall = '0' and h_ifid_stall = '0',
          "branch taken flushes both IF/ID and ID/EX, without stalling PC");

    -- neither condition: everything quiet
    h_branch_taken <= '0';
    wait for 1 ns;
    check(h_pc_stall = '0' and h_ifid_stall = '0' and h_ifid_flush = '0' and h_idex_flush = '0',
          "no hazard, no flush: pipeline runs normally");

    write(l, string'("-------------------------------------")); writeline(output, l);
    write(l, string'("hazard/forwarding unit test: ")); write(l, pass_count);
    write(l, string'(" passed, ")); write(l, fail_count); write(l, string'(" failed"));
    writeline(output, l);
    assert fail_count = 0 report "HAZARD/FORWARDING TESTBENCH FAILED" severity failure;
    report "HAZARD/FORWARDING TESTBENCH PASSED";
    wait;
  end process;
end architecture sim;
