library ieee;
use ieee.std_logic_1164.all;

-- forward_a/forward_b: "00" = no forward (use ID/EX register value)
--                       "01" = forward from EX/MEM (most recent)
--                       "10" = forward from MEM/WB
entity forwarding_unit is
  port (
    id_ex_rs1_addr  : in  std_logic_vector(4 downto 0);
    id_ex_rs2_addr  : in  std_logic_vector(4 downto 0);
    ex_mem_rd_addr  : in  std_logic_vector(4 downto 0);
    ex_mem_reg_write: in  std_logic;
    mem_wb_rd_addr  : in  std_logic_vector(4 downto 0);
    mem_wb_reg_write: in  std_logic;
    forward_a       : out std_logic_vector(1 downto 0);
    forward_b       : out std_logic_vector(1 downto 0)
  );
end entity forwarding_unit;

architecture rtl of forwarding_unit is
begin
  process (id_ex_rs1_addr, id_ex_rs2_addr, ex_mem_rd_addr, ex_mem_reg_write,
           mem_wb_rd_addr, mem_wb_reg_write)
  begin
    -- operand A
    if ex_mem_reg_write = '1' and ex_mem_rd_addr /= "00000"
       and ex_mem_rd_addr = id_ex_rs1_addr then
      forward_a <= "01";
    elsif mem_wb_reg_write = '1' and mem_wb_rd_addr /= "00000"
       and mem_wb_rd_addr = id_ex_rs1_addr then
      forward_a <= "10";
    else
      forward_a <= "00";
    end if;

    -- operand B
    if ex_mem_reg_write = '1' and ex_mem_rd_addr /= "00000"
       and ex_mem_rd_addr = id_ex_rs2_addr then
      forward_b <= "01";
    elsif mem_wb_reg_write = '1' and mem_wb_rd_addr /= "00000"
       and mem_wb_rd_addr = id_ex_rs2_addr then
      forward_b <= "10";
    else
      forward_b <= "00";
    end if;
  end process;
end architecture rtl;
