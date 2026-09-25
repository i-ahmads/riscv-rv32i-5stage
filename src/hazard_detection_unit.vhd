library ieee;
use ieee.std_logic_1164.all;

entity hazard_detection_unit is
  port (
    id_ex_mem_read  : in  std_logic;
    id_ex_rd_addr   : in  std_logic_vector(4 downto 0);
    if_id_rs1_addr  : in  std_logic_vector(4 downto 0);
    if_id_rs2_addr  : in  std_logic_vector(4 downto 0);
    branch_taken    : in  std_logic;  -- resolved combinationally in EX this cycle

    pc_stall    : out std_logic;  -- hold PC (load-use hazard)
    if_id_stall : out std_logic;  -- hold IF/ID (load-use hazard)
    if_id_flush : out std_logic;  -- clear IF/ID to bubble (branch taken)
    id_ex_flush : out std_logic   -- clear ID/EX to bubble (load-use OR branch)
  );
end entity hazard_detection_unit;

architecture rtl of hazard_detection_unit is
  signal load_use_hazard : std_logic;
begin
  load_use_hazard <= '1' when (id_ex_mem_read = '1' and id_ex_rd_addr /= "00000"
                                and (id_ex_rd_addr = if_id_rs1_addr
                                     or id_ex_rd_addr = if_id_rs2_addr))
                      else '0';

  pc_stall    <= load_use_hazard;
  if_id_stall <= load_use_hazard;
  if_id_flush <= branch_taken;
  id_ex_flush <= load_use_hazard or branch_taken;
end architecture rtl;
