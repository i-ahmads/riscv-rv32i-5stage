library ieee;
use ieee.std_logic_1164.all;

-- Extends the original hazard_detection_unit with one new case: a branch
-- (or JALR) sitting in ID this cycle needs its operand from the
-- instruction immediately ahead of it, which is currently only in EX --
-- one stage too early for id_forward_unit to reach (that only covers
-- EX/MEM). This is the real cost of resolving branches in ID: it buys
-- back most of the flush penalty but reintroduces a stall for this one
-- adjacency case. Branch/jump flush itself only needs IF/ID now (one
-- instruction in flight, not two), so there is no separate control-flush
-- port for ID/EX here -- only the bubble needed for a genuine stall.
entity hazard_detection_unit_idres is
  port (
    id_ex_reg_write   : in  std_logic;   -- instruction now in EX
    id_ex_rd_addr     : in  std_logic_vector(4 downto 0);
    if_id_rs1_addr    : in  std_logic_vector(4 downto 0);
    if_id_rs2_addr    : in  std_logic_vector(4 downto 0);
    if_id_needs_cmp   : in  std_logic;   -- '1' if the ID-stage instruction is branch/JALR
    load_use_mem_read : in  std_logic;   -- id_ex_mem_read, for the ordinary load-use case
    branch_taken      : in  std_logic;   -- resolved combinationally in ID this cycle

    pc_stall    : out std_logic;
    if_id_stall : out std_logic;
    if_id_flush : out std_logic;
    id_ex_flush : out std_logic
  );
end entity hazard_detection_unit_idres;

architecture rtl of hazard_detection_unit_idres is
  signal load_use_hazard, branch_source_hazard, any_stall : std_logic;
begin
  load_use_hazard <= '1' when (load_use_mem_read = '1' and id_ex_rd_addr /= "00000"
                                and (id_ex_rd_addr = if_id_rs1_addr
                                     or id_ex_rd_addr = if_id_rs2_addr))
                      else '0';

  branch_source_hazard <= '1' when (if_id_needs_cmp = '1' and id_ex_reg_write = '1'
                                     and id_ex_rd_addr /= "00000"
                                     and (id_ex_rd_addr = if_id_rs1_addr
                                          or id_ex_rd_addr = if_id_rs2_addr))
                           else '0';

  any_stall <= load_use_hazard or branch_source_hazard;

  pc_stall    <= any_stall;
  if_id_stall <= any_stall;
  if_id_flush <= branch_taken;
  id_ex_flush <= any_stall;   -- bubble the (stalled-out) instruction behind
end architecture rtl;
