library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_pkg.all;

-- Illustrative-only copy of datapath.vhd, used solely by the worked-example
-- walkthrough in the report (Section 7.7). Identical to the verified
-- datapath.vhd in every respect except two: it fetches from
-- instr_mem_worked instead of instr_mem, and it brings extra per-stage
-- signals out to the top level so the testbench can print, cycle by cycle,
-- which instruction sits in which pipeline stage and what the forwarding
-- muxes are doing. None of the added ports feed back into the datapath;
-- they are read-only taps on signals that already exist in the verified
-- design, so the underlying pipeline logic is byte-for-byte the same as
-- datapath.vhd.
entity datapath_worked is
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    -- debug/verification only
    dbg_addr  : in  std_logic_vector(4 downto 0) := (others => '0');
    dbg_data  : out std_logic_vector(31 downto 0);
    dbg_pc    : out std_logic_vector(31 downto 0);

    -- extra per-stage trace taps, worked-example only
    tr_ifid_instr      : out std_logic_vector(31 downto 0); -- instruction now in ID
    tr_idex_rd_addr    : out std_logic_vector(4 downto 0);  -- instruction now in EX (by rd)
    tr_idex_rs1_data   : out std_logic_vector(31 downto 0); -- rs1 value latched into ID/EX (pre-forward)
    tr_idex_rs2_data   : out std_logic_vector(31 downto 0); -- rs2 value latched into ID/EX (pre-forward)
    tr_ex_forward_a    : out std_logic_vector(1 downto 0);
    tr_ex_forward_b    : out std_logic_vector(1 downto 0);
    tr_ex_operand_a    : out std_logic_vector(31 downto 0); -- ALU operand A after forwarding mux
    tr_ex_operand_b    : out std_logic_vector(31 downto 0); -- ALU operand B after forwarding mux
    tr_ex_alu_result   : out std_logic_vector(31 downto 0);
    tr_exmem_rd_addr   : out std_logic_vector(4 downto 0);  -- instruction now in MEM (by rd)
    tr_exmem_alu_result: out std_logic_vector(31 downto 0);
    tr_memwb_rd_addr   : out std_logic_vector(4 downto 0);  -- instruction now in WB (by rd)
    tr_wb_rd_data      : out std_logic_vector(31 downto 0)
  );
end entity datapath_worked;

architecture rtl of datapath_worked is

  -- IF
  signal pc_current, pc_next, pc_plus4, if_instr : std_logic_vector(31 downto 0);

  -- IF/ID
  signal ifid_pc, ifid_pc4, ifid_instr : std_logic_vector(31 downto 0);

  -- ID
  signal id_opcode                      : std_logic_vector(6 downto 0);
  signal id_rs1_addr, id_rs2_addr, id_rd_addr : std_logic_vector(4 downto 0);
  signal id_rs1_data, id_rs2_data, id_imm     : std_logic_vector(31 downto 0);
  signal id_funct3                      : std_logic_vector(2 downto 0);
  signal id_funct7b5                    : std_logic;
  signal id_reg_write, id_mem_read, id_mem_write, id_alu_src,
         id_branch, id_jump, id_is_jalr, id_is_rtype : std_logic;
  signal id_op_a_sel                    : std_logic_vector(1 downto 0);
  signal id_alu_op, id_result_src        : std_logic_vector(1 downto 0);

  -- ID/EX
  signal idex_pc, idex_pc4, idex_rs1_data, idex_rs2_data, idex_imm : std_logic_vector(31 downto 0);
  signal idex_rs1_addr, idex_rs2_addr, idex_rd_addr : std_logic_vector(4 downto 0);
  signal idex_funct3 : std_logic_vector(2 downto 0);
  signal idex_funct7b5 : std_logic;
  signal idex_reg_write, idex_mem_read, idex_mem_write, idex_alu_src,
         idex_branch, idex_jump, idex_is_jalr, idex_is_rtype : std_logic;
  signal idex_op_a_sel : std_logic_vector(1 downto 0);
  signal idex_alu_op, idex_result_src : std_logic_vector(1 downto 0);

  -- EX
  signal ex_alu_ctrl : std_logic_vector(3 downto 0);
  signal ex_forward_a, ex_forward_b : std_logic_vector(1 downto 0);
  signal ex_operand_a, ex_alu_opA, ex_operand_b, ex_rs2_fwd : std_logic_vector(31 downto 0);
  signal ex_alu_result : std_logic_vector(31 downto 0);
  signal ex_branch_cond, ex_branch_taken : std_logic;
  signal ex_pc_plus_imm, ex_jalr_target, ex_target : std_logic_vector(31 downto 0);
  signal exmem_fwd_value : std_logic_vector(31 downto 0);

  -- EX/MEM
  signal exmem_alu_result, exmem_rs2_data, exmem_pc4 : std_logic_vector(31 downto 0);
  signal exmem_rd_addr : std_logic_vector(4 downto 0);
  signal exmem_funct3 : std_logic_vector(2 downto 0);
  signal exmem_reg_write, exmem_mem_read, exmem_mem_write : std_logic;
  signal exmem_result_src : std_logic_vector(1 downto 0);

  -- MEM
  signal mem_read_data, mem_write_word, mem_load_data : std_logic_vector(31 downto 0);

  -- MEM/WB
  signal memwb_mem_data, memwb_alu_result, memwb_pc4 : std_logic_vector(31 downto 0);
  signal memwb_rd_addr : std_logic_vector(4 downto 0);
  signal memwb_reg_write : std_logic;
  signal memwb_result_src : std_logic_vector(1 downto 0);

  -- WB
  signal wb_rd_data : std_logic_vector(31 downto 0);

  -- hazard control
  signal hz_pc_stall, hz_if_id_stall, hz_if_id_flush, hz_id_ex_flush : std_logic;

begin

  ----------------------------------------------------------------- IF stage
  pc_plus4 <= std_logic_vector(unsigned(pc_current) + 4);
  pc_next  <= ex_target when ex_branch_taken = '1' else pc_plus4;

  u_pc_reg : entity work.pc_reg
    port map (clk => clk, reset => reset, stall => hz_pc_stall,
              pc_next => pc_next, pc => pc_current);

  u_instr_mem : entity work.instr_mem_worked
    port map (addr => pc_current, instr => if_instr);

  u_if_id_reg : entity work.if_id_reg
    port map (clk => clk, reset => reset,
              stall => hz_if_id_stall, flush => hz_if_id_flush,
              pc_in => pc_current, pc4_in => pc_plus4, instr_in => if_instr,
              pc_out => ifid_pc, pc4_out => ifid_pc4, instr_out => ifid_instr);

  ----------------------------------------------------------------- ID stage
  id_opcode   <= ifid_instr(6 downto 0);
  id_rs1_addr <= ifid_instr(19 downto 15);
  id_rs2_addr <= ifid_instr(24 downto 20);
  id_rd_addr  <= ifid_instr(11 downto 7);
  id_funct3   <= ifid_instr(14 downto 12);
  id_funct7b5 <= ifid_instr(30);

  u_control_unit : entity work.control_unit
    port map (opcode => id_opcode, reg_write => id_reg_write,
              mem_read => id_mem_read, mem_write => id_mem_write,
              alu_src => id_alu_src, branch => id_branch, jump => id_jump,
              is_jalr => id_is_jalr, op_a_sel => id_op_a_sel,
              alu_op => id_alu_op, result_src => id_result_src,
              is_rtype => id_is_rtype);

  u_immediate_gen : entity work.immediate_gen
    port map (instr => ifid_instr, imm => id_imm);

  u_register_file : entity work.register_file
    port map (clk => clk, rs1_addr => id_rs1_addr, rs2_addr => id_rs2_addr,
              rd_addr => memwb_rd_addr, rd_data => wb_rd_data,
              reg_write => memwb_reg_write,
              rs1_data => id_rs1_data, rs2_data => id_rs2_data,
              dbg_addr => dbg_addr, dbg_data => dbg_data);

  u_hazard_detection : entity work.hazard_detection_unit
    port map (id_ex_mem_read => idex_mem_read, id_ex_rd_addr => idex_rd_addr,
              if_id_rs1_addr => id_rs1_addr, if_id_rs2_addr => id_rs2_addr,
              branch_taken => ex_branch_taken,
              pc_stall => hz_pc_stall, if_id_stall => hz_if_id_stall,
              if_id_flush => hz_if_id_flush, id_ex_flush => hz_id_ex_flush);

  u_id_ex_reg : entity work.id_ex_reg
    port map (clk => clk, reset => reset, flush => hz_id_ex_flush,
              pc_in => ifid_pc, pc4_in => ifid_pc4,
              rs1_data_in => id_rs1_data, rs2_data_in => id_rs2_data,
              rs1_addr_in => id_rs1_addr, rs2_addr_in => id_rs2_addr,
              rd_addr_in => id_rd_addr, imm_in => id_imm,
              funct3_in => id_funct3, funct7b5_in => id_funct7b5,
              reg_write_in => id_reg_write, mem_read_in => id_mem_read,
              mem_write_in => id_mem_write, alu_src_in => id_alu_src,
              branch_in => id_branch, jump_in => id_jump,
              is_jalr_in => id_is_jalr, op_a_sel_in => id_op_a_sel,
              alu_op_in => id_alu_op, result_src_in => id_result_src,
              is_rtype_in => id_is_rtype,
              pc_out => idex_pc, pc4_out => idex_pc4,
              rs1_data_out => idex_rs1_data, rs2_data_out => idex_rs2_data,
              rs1_addr_out => idex_rs1_addr, rs2_addr_out => idex_rs2_addr,
              rd_addr_out => idex_rd_addr, imm_out => idex_imm,
              funct3_out => idex_funct3, funct7b5_out => idex_funct7b5,
              reg_write_out => idex_reg_write, mem_read_out => idex_mem_read,
              mem_write_out => idex_mem_write, alu_src_out => idex_alu_src,
              branch_out => idex_branch, jump_out => idex_jump,
              is_jalr_out => idex_is_jalr, op_a_sel_out => idex_op_a_sel,
              alu_op_out => idex_alu_op, result_src_out => idex_result_src,
              is_rtype_out => idex_is_rtype);

  ----------------------------------------------------------------- EX stage
  u_forwarding_unit : entity work.forwarding_unit
    port map (id_ex_rs1_addr => idex_rs1_addr, id_ex_rs2_addr => idex_rs2_addr,
              ex_mem_rd_addr => exmem_rd_addr, ex_mem_reg_write => exmem_reg_write,
              mem_wb_rd_addr => memwb_rd_addr, mem_wb_reg_write => memwb_reg_write,
              forward_a => ex_forward_a, forward_b => ex_forward_b);

  -- EX/MEM forwarding must supply whatever WB will actually write for that
  -- instruction. For JAL/JALR that's pc4, not the ALU's (unused) output --
  -- forwarding the raw alu_result would silently hand the consumer garbage.
  -- (A MEM-sourced/load producer is never forwarded from here: the hazard
  -- unit always stalls that case instead, since load data isn't ready yet.)
  exmem_fwd_value <= exmem_pc4 when exmem_result_src = RESSRC_PC4 else exmem_alu_result;

  ex_operand_a <= idex_rs1_data      when ex_forward_a = "00" else
                  exmem_fwd_value    when ex_forward_a = "01" else
                  wb_rd_data         when ex_forward_a = "10" else
                  (others => '0');

  ex_rs2_fwd   <= idex_rs2_data      when ex_forward_b = "00" else
                  exmem_fwd_value    when ex_forward_b = "01" else
                  wb_rd_data         when ex_forward_b = "10" else
                  (others => '0');

  -- operand-A override for LUI (zero) / AUIPC (PC); everything else uses
  -- the (possibly forwarded) rs1 value straight through
  ex_alu_opA <= idex_pc       when idex_op_a_sel = OPA_PC   else
                (others=>'0') when idex_op_a_sel = OPA_ZERO else
                ex_operand_a;

  ex_operand_b <= idex_imm when idex_alu_src = '1' else ex_rs2_fwd;

  u_alu_control : entity work.alu_control
    port map (alu_op => idex_alu_op, funct3 => idex_funct3,
              funct7_b5 => idex_funct7b5, is_rtype => idex_is_rtype,
              alu_ctrl => ex_alu_ctrl);

  u_alu : entity work.alu
    port map (a => ex_alu_opA, b => ex_operand_b, alu_ctrl => ex_alu_ctrl,
              result => ex_alu_result, zero => open);

  u_branch_unit : entity work.branch_unit
    port map (a => ex_operand_a, b => ex_rs2_fwd, funct3 => idex_funct3,
              taken => ex_branch_cond);

  ex_pc_plus_imm  <= std_logic_vector(unsigned(idex_pc) + unsigned(idex_imm));
  ex_jalr_target  <= ex_alu_result(31 downto 1) & '0';  -- rs1+imm, LSB cleared
  ex_target       <= ex_jalr_target when idex_is_jalr = '1' else ex_pc_plus_imm;
  ex_branch_taken <= (idex_branch and ex_branch_cond) or idex_jump or idex_is_jalr;

  u_ex_mem_reg : entity work.ex_mem_reg
    port map (clk => clk, reset => reset,
              alu_result_in => ex_alu_result, rs2_data_in => ex_rs2_fwd,
              rd_addr_in => idex_rd_addr, pc4_in => idex_pc4,
              funct3_in => idex_funct3,
              reg_write_in => idex_reg_write, mem_read_in => idex_mem_read,
              mem_write_in => idex_mem_write, result_src_in => idex_result_src,
              alu_result_out => exmem_alu_result, rs2_data_out => exmem_rs2_data,
              rd_addr_out => exmem_rd_addr, pc4_out => exmem_pc4,
              funct3_out => exmem_funct3,
              reg_write_out => exmem_reg_write, mem_read_out => exmem_mem_read,
              mem_write_out => exmem_mem_write, result_src_out => exmem_result_src);

  ---------------------------------------------------------------- MEM stage
  u_data_mem : entity work.data_mem
    port map (clk => clk, addr => exmem_alu_result, write_data => mem_write_word,
              mem_write => exmem_mem_write, mem_read => exmem_mem_read,
              read_data => mem_read_data);

  u_load_store_unit : entity work.load_store_unit
    port map (byte_addr => exmem_alu_result(1 downto 0), funct3 => exmem_funct3,
              old_word => mem_read_data, store_data => exmem_rs2_data,
              write_word => mem_write_word, load_data => mem_load_data);

  u_mem_wb_reg : entity work.mem_wb_reg
    port map (clk => clk, reset => reset,
              mem_data_in => mem_load_data, alu_result_in => exmem_alu_result,
              rd_addr_in => exmem_rd_addr, pc4_in => exmem_pc4,
              reg_write_in => exmem_reg_write, result_src_in => exmem_result_src,
              mem_data_out => memwb_mem_data, alu_result_out => memwb_alu_result,
              rd_addr_out => memwb_rd_addr, pc4_out => memwb_pc4,
              reg_write_out => memwb_reg_write, result_src_out => memwb_result_src);

  ----------------------------------------------------------------- WB stage
  wb_rd_data <= memwb_alu_result when memwb_result_src = RESSRC_ALU else
                memwb_mem_data   when memwb_result_src = RESSRC_MEM else
                memwb_pc4        when memwb_result_src = RESSRC_PC4 else
                (others => '0');

  dbg_pc <= pc_current;

  -- worked-example trace taps: read-only, do not affect pipeline behavior
  tr_ifid_instr       <= ifid_instr;
  tr_idex_rd_addr     <= idex_rd_addr;
  tr_idex_rs1_data    <= idex_rs1_data;
  tr_idex_rs2_data    <= idex_rs2_data;
  tr_ex_forward_a     <= ex_forward_a;
  tr_ex_forward_b     <= ex_forward_b;
  tr_ex_operand_a     <= ex_operand_a;
  tr_ex_operand_b     <= ex_operand_b;
  tr_ex_alu_result    <= ex_alu_result;
  tr_exmem_rd_addr    <= exmem_rd_addr;
  tr_exmem_alu_result <= exmem_alu_result;
  tr_memwb_rd_addr    <= memwb_rd_addr;
  tr_wb_rd_data       <= wb_rd_data;
end architecture rtl;
