library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Handles the byte/halfword slicing that data_mem.vhd itself doesn't do -
-- data_mem is a plain word-addressed array; this unit sits between it and
-- the pipeline to (a) merge a byte/halfword into the existing word for
-- SB/SH without clobbering the other bytes, and (b) extract + sign/zero
-- extend a byte/halfword out of a word for LB/LH/LBU/LHU. Little-endian:
-- byte 0 (addr bits 1:0 = "00") is the least-significant byte of the word.
entity load_store_unit is
  port (
    byte_addr  : in  std_logic_vector(1 downto 0);  -- addr(1 downto 0)
    funct3     : in  std_logic_vector(2 downto 0);
    old_word   : in  std_logic_vector(31 downto 0); -- current word at this address
    store_data : in  std_logic_vector(31 downto 0); -- raw rs2 (unaligned)
    write_word : out std_logic_vector(31 downto 0); -- word to actually write
    load_data  : out std_logic_vector(31 downto 0)  -- extracted + extended
  );
end entity load_store_unit;

architecture rtl of load_store_unit is
  signal lane      : integer range 0 to 3;
  signal half_lane : integer range 0 to 1;
  signal byte_sel  : std_logic_vector(7 downto 0);
  signal half_sel  : std_logic_vector(15 downto 0);
begin
  lane      <= to_integer(unsigned(byte_addr));
  half_lane <= to_integer(unsigned(byte_addr(1 downto 1)));

  byte_sel <= old_word(lane*8+7 downto lane*8);
  half_sel <= old_word(half_lane*16+15 downto half_lane*16);

  -- store side: merge store_data's low byte/halfword into old_word
  process (funct3, old_word, store_data, lane, half_lane)
    variable w : std_logic_vector(31 downto 0);
  begin
    w := old_word;
    case funct3 is
      when "000" =>  -- SB
        w(lane*8+7 downto lane*8) := store_data(7 downto 0);
      when "001" =>  -- SH
        w(half_lane*16+15 downto half_lane*16) := store_data(15 downto 0);
      when others => -- SW
        w := store_data;
    end case;
    write_word <= w;
  end process;

  -- load side: extract and sign/zero extend
  process (funct3, byte_sel, half_sel, old_word)
  begin
    case funct3 is
      when "000" => load_data <= (31 downto 8 => byte_sel(7)) & byte_sel;        -- LB
      when "001" => load_data <= (31 downto 16 => half_sel(15)) & half_sel;      -- LH
      when "100" => load_data <= (31 downto 8 => '0') & byte_sel;                -- LBU
      when "101" => load_data <= (31 downto 16 => '0') & half_sel;              -- LHU
      when others => load_data <= old_word;                                      -- LW
    end case;
  end process;
end architecture rtl;
