library ieee;
use ieee.std_logic_1164.all;
use work.riscv_pkg.all;

-- alu_op: "00" = address calc (loads/stores/AUIPC/LUI/JALR) -> ADD
--         others = R-type/I-type ALU instruction -> decode funct3/funct7b5
--
-- Note on funct7_b5 (instr(30)): for the ADD/SUB case this bit is only a
-- real opcode discriminator on R-type (ADDI never has a SUB variant - its
-- imm field can legally have bit 30 set as ordinary immediate data, so it
-- must NOT be read as an opcode bit there). For the shift-right case,
-- instr(30) genuinely distinguishes SRL/SRLI from SRA/SRAI in BOTH R-type
-- and I-type encodings (the shift-immediate format reserves that bit),
-- so no is_rtype gating is applied there.
entity alu_control is
  port (
    alu_op    : in  std_logic_vector(1 downto 0);
    funct3    : in  std_logic_vector(2 downto 0);
    funct7_b5 : in  std_logic;
    is_rtype  : in  std_logic;
    alu_ctrl  : out std_logic_vector(3 downto 0)
  );
end entity alu_control;

architecture rtl of alu_control is
begin
  process (alu_op, funct3, funct7_b5, is_rtype)
  begin
    case alu_op is
      when "00"   => alu_ctrl <= ALU_ADD;
      when others =>
        case funct3 is
          when "000" =>
            if is_rtype = '1' and funct7_b5 = '1' then
              alu_ctrl <= ALU_SUB;
            else
              alu_ctrl <= ALU_ADD;
            end if;
          when "001" => alu_ctrl <= ALU_SLL;
          when "010" => alu_ctrl <= ALU_SLT;
          when "011" => alu_ctrl <= ALU_SLTU;
          when "100" => alu_ctrl <= ALU_XOR;
          when "101" =>
            if funct7_b5 = '1' then
              alu_ctrl <= ALU_SRA;
            else
              alu_ctrl <= ALU_SRL;
            end if;
          when "110" => alu_ctrl <= ALU_OR;
          when "111" => alu_ctrl <= ALU_AND;
          when others => alu_ctrl <= ALU_ADD;
        end case;
    end case;
  end process;
end architecture rtl;
