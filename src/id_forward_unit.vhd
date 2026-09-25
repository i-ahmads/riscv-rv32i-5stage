library ieee;
use ieee.std_logic_1164.all;

-- Forwarding into the ID stage, needed only by the ID-resolution pipeline
-- variant (branches/JALR compare their operands one stage earlier than in
-- the EX-resolution design). Only the EX/MEM source needs handling here:
-- the MEM/WB source is already covered for free by register_file.vhd's
-- built-in write-through bypass (same-cycle write-then-read of the same
-- register), since that bypass fires on every register_file read whether
-- it's ID's normal decode or this comparator's operand fetch.
entity id_forward_unit is
  port (
    if_id_rs1_addr  : in  std_logic_vector(4 downto 0);
    if_id_rs2_addr  : in  std_logic_vector(4 downto 0);
    ex_mem_rd_addr  : in  std_logic_vector(4 downto 0);
    ex_mem_reg_write: in  std_logic;
    fwd_a, fwd_b    : out std_logic  -- '1' = use EX/MEM's value instead of the register-file read
  );
end entity id_forward_unit;

architecture rtl of id_forward_unit is
begin
  fwd_a <= '1' when (ex_mem_reg_write = '1' and ex_mem_rd_addr /= "00000"
                      and ex_mem_rd_addr = if_id_rs1_addr) else '0';
  fwd_b <= '1' when (ex_mem_reg_write = '1' and ex_mem_rd_addr /= "00000"
                      and ex_mem_rd_addr = if_id_rs2_addr) else '0';
end architecture rtl;
