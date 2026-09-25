library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Illustrative-only instruction ROM used solely by the worked-example
-- walkthrough in the report (Section 7.7). Same combinational-read
-- interface as instr_mem.vhd, but preloaded with just three real
-- instructions instead of the full-coverage program:
--
--   addr 0x00 : 0x00500093  ADDI x1, x0, 5     (x1 = 5)
--   addr 0x04 : 0x00300113  ADDI x2, x0, 3     (x2 = 3)
--   addr 0x08 : 0x002081b3  ADD  x3, x1, x2    (x3 = x1 + x2)
--   remainder : 0x00000013  NOP (ADDI x0, x0, 0), padding so the pipeline
--               can drain cleanly after the ADD without fetching garbage
--
-- This file is not part of either verified cpu_top / cpu_top_idres build
-- and is never instantiated by them; it exists only so the worked example
-- can be simulated on real, synthesizable RTL rather than hand-traced.
entity instr_mem_worked is
  port (
    addr  : in  std_logic_vector(31 downto 0);
    instr : out std_logic_vector(31 downto 0)
  );
end entity instr_mem_worked;

architecture rtl of instr_mem_worked is
  type rom_array is array (0 to 15) of std_logic_vector(31 downto 0);
  constant rom : rom_array := (
    0 => x"00500093",  -- ADDI x1, x0, 5
    1 => x"00300113",  -- ADDI x2, x0, 3
    2 => x"002081b3",  -- ADD  x3, x1, x2
    others => x"00000013"  -- NOP
  );
begin
  instr <= rom(to_integer(unsigned(addr(5 downto 2))));
end architecture rtl;
