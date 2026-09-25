library ieee;
use ieee.std_logic_1164.all;

entity id_ex_reg is
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    flush     : in  std_logic;  -- insert bubble (load-use stall)

    pc_in     : in  std_logic_vector(31 downto 0);
    pc4_in    : in  std_logic_vector(31 downto 0);
    rs1_data_in : in std_logic_vector(31 downto 0);
    rs2_data_in : in std_logic_vector(31 downto 0);
    rs1_addr_in : in std_logic_vector(4 downto 0);
    rs2_addr_in : in std_logic_vector(4 downto 0);
    rd_addr_in  : in std_logic_vector(4 downto 0);
    imm_in      : in std_logic_vector(31 downto 0);
    funct3_in   : in std_logic_vector(2 downto 0);
    funct7b5_in : in std_logic;

    reg_write_in : in std_logic;
    mem_read_in  : in std_logic;
    mem_write_in : in std_logic;
    alu_src_in   : in std_logic;
    branch_in    : in std_logic;
    jump_in      : in std_logic;
    is_jalr_in   : in std_logic;
    op_a_sel_in  : in std_logic_vector(1 downto 0);
    alu_op_in    : in std_logic_vector(1 downto 0);
    result_src_in: in std_logic_vector(1 downto 0);
    is_rtype_in  : in std_logic;

    pc_out     : out std_logic_vector(31 downto 0);
    pc4_out    : out std_logic_vector(31 downto 0);
    rs1_data_out : out std_logic_vector(31 downto 0);
    rs2_data_out : out std_logic_vector(31 downto 0);
    rs1_addr_out : out std_logic_vector(4 downto 0);
    rs2_addr_out : out std_logic_vector(4 downto 0);
    rd_addr_out  : out std_logic_vector(4 downto 0);
    imm_out      : out std_logic_vector(31 downto 0);
    funct3_out   : out std_logic_vector(2 downto 0);
    funct7b5_out : out std_logic;

    reg_write_out : out std_logic;
    mem_read_out  : out std_logic;
    mem_write_out : out std_logic;
    alu_src_out   : out std_logic;
    branch_out    : out std_logic;
    jump_out      : out std_logic;
    is_jalr_out   : out std_logic;
    op_a_sel_out  : out std_logic_vector(1 downto 0);
    alu_op_out    : out std_logic_vector(1 downto 0);
    result_src_out: out std_logic_vector(1 downto 0);
    is_rtype_out  : out std_logic
  );
end entity id_ex_reg;

architecture rtl of id_ex_reg is
begin
  process (clk, reset)
  begin
    if reset = '1' then
      pc_out       <= (others => '0');
      pc4_out      <= (others => '0');
      rs1_data_out <= (others => '0');
      rs2_data_out <= (others => '0');
      rs1_addr_out <= (others => '0');
      rs2_addr_out <= (others => '0');
      rd_addr_out  <= (others => '0');
      imm_out      <= (others => '0');
      funct3_out   <= (others => '0');
      funct7b5_out <= '0';
      reg_write_out  <= '0';
      mem_read_out   <= '0';
      mem_write_out  <= '0';
      alu_src_out    <= '0';
      branch_out     <= '0';
      jump_out       <= '0';
      is_jalr_out    <= '0';
      op_a_sel_out   <= (others => '0');
      alu_op_out     <= (others => '0');
      result_src_out <= (others => '0');
      is_rtype_out   <= '0';
    elsif rising_edge(clk) then
      if flush = '1' then
        pc_out       <= (others => '0');
        pc4_out      <= (others => '0');
        rs1_data_out <= (others => '0');
        rs2_data_out <= (others => '0');
        rs1_addr_out <= (others => '0');
        rs2_addr_out <= (others => '0');
        rd_addr_out  <= (others => '0');
        imm_out      <= (others => '0');
        funct3_out   <= (others => '0');
        funct7b5_out <= '0';
        reg_write_out  <= '0';
        mem_read_out   <= '0';
        mem_write_out  <= '0';
        alu_src_out    <= '0';
        branch_out     <= '0';
        jump_out       <= '0';
        is_jalr_out    <= '0';
        op_a_sel_out   <= (others => '0');
        alu_op_out     <= (others => '0');
        result_src_out <= (others => '0');
        is_rtype_out   <= '0';
      else
        pc_out       <= pc_in;
        pc4_out      <= pc4_in;
        rs1_data_out <= rs1_data_in;
        rs2_data_out <= rs2_data_in;
        rs1_addr_out <= rs1_addr_in;
        rs2_addr_out <= rs2_addr_in;
        rd_addr_out  <= rd_addr_in;
        imm_out      <= imm_in;
        funct3_out   <= funct3_in;
        funct7b5_out <= funct7b5_in;
        reg_write_out  <= reg_write_in;
        mem_read_out   <= mem_read_in;
        mem_write_out  <= mem_write_in;
        alu_src_out    <= alu_src_in;
        branch_out     <= branch_in;
        jump_out       <= jump_in;
        is_jalr_out    <= is_jalr_in;
        op_a_sel_out   <= op_a_sel_in;
        alu_op_out     <= alu_op_in;
        result_src_out <= result_src_in;
        is_rtype_out   <= is_rtype_in;
      end if;
    end if;
  end process;
end architecture rtl;
