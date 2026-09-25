library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.riscv_pkg.all;

-- Exhaustive-by-design unit test: every ALU operation is checked against
-- several operand pairs chosen to hit edge cases (zero, negative, the
-- signed/unsigned boundary at 0x80000000, shift amounts >0). This is the
-- authoritative correctness check for the ALU; the integration testbench
-- only exercises a representative subset in realistic context.
entity tb_alu is
end entity tb_alu;

architecture sim of tb_alu is
  signal a, b, result : std_logic_vector(31 downto 0);
  signal alu_ctrl : std_logic_vector(3 downto 0);
  signal zero : std_logic;

begin
  dut : entity work.alu port map (a => a, b => b, alu_ctrl => alu_ctrl,
                                    result => result, zero => zero);

  stim : process
    variable l : line;
    variable pass_count, fail_count : integer := 0;

    procedure check(av, bv : integer; ctrl : std_logic_vector(3 downto 0);
                     expected : integer; name : string) is
    begin
      a <= std_logic_vector(to_signed(av, 32));
      b <= std_logic_vector(to_signed(bv, 32));
      alu_ctrl <= ctrl;
      wait for 1 ns;
      if to_integer(signed(result)) = expected then
        write(l, string'("  PASS  ")); write(l, name);
        writeline(output, l);
        pass_count := pass_count + 1;
      else
        write(l, string'("  FAIL  ")); write(l, name);
        write(l, string'(" got ")); write(l, to_integer(signed(result)));
        write(l, string'(" expected ")); write(l, expected);
        writeline(output, l);
        fail_count := fail_count + 1;
      end if;
    end procedure;

    -- unsigned-domain variant, for SLTU/SRL where interpreting operands as
    -- unsigned matters (to_signed(-1,32) still gives the all-ones bit
    -- pattern, i.e. 0xFFFFFFFF, so this reuses the same encoding trick)
    procedure checku(av, bv : integer; ctrl : std_logic_vector(3 downto 0);
                      expected : integer; name : string) is
    begin
      check(av, bv, ctrl, expected, name);
    end procedure;

  begin
    -- ADD
    check(5, 10, ALU_ADD, 15, "ADD 5+10");
    check(-5, 10, ALU_ADD, 5, "ADD -5+10");
    check(0, 0, ALU_ADD, 0, "ADD 0+0");
    check(2147483647, 1, ALU_ADD, -2147483648, "ADD overflow wrap");

    -- SUB
    check(10, 5, ALU_SUB, 5, "SUB 10-5");
    check(5, 10, ALU_SUB, -5, "SUB 5-10");
    check(0, 0, ALU_SUB, 0, "SUB 0-0");
    check(-2147483648, 1, ALU_SUB, 2147483647, "SUB underflow wrap");

    -- AND / OR / XOR
    check(12, 10, ALU_AND, 8, "AND 12&10");
    check(0, -1, ALU_AND, 0, "AND with zero");
    check(12, 10, ALU_OR, 14, "OR 12|10");
    check(0, 0, ALU_OR, 0, "OR 0|0");
    check(12, 10, ALU_XOR, 6, "XOR 12^10");
    check(-1, -1, ALU_XOR, 0, "XOR self");

    -- SLT (signed) / SLTU (unsigned) -- the case that actually needs
    -- distinct signed/unsigned interpretation
    check(5, 10, ALU_SLT, 1, "SLT 5<10 true");
    check(10, 5, ALU_SLT, 0, "SLT 10<5 false");
    check(-1, 0, ALU_SLT, 1, "SLT -1<0 true (signed)");
    checku(-1, 0, ALU_SLTU, 0, "SLTU 0xFFFFFFFF<0 false (unsigned)");
    checku(0, -1, ALU_SLTU, 1, "SLTU 0<0xFFFFFFFF true (unsigned)");

    -- SLL / SRL / SRA
    check(1, 4, ALU_SLL, 16, "SLL 1<<4");
    check(1, 31, ALU_SLL, -2147483648, "SLL 1<<31 (sign bit)");
    checku(-2147483648, 4, ALU_SRL, 134217728, "SRL 0x80000000>>4 (zero-fill)");
    check(-2147483648, 4, ALU_SRA, -134217728, "SRA 0x80000000>>4 (sign-fill)");
    check(-1, 4, ALU_SRA, -1, "SRA all-ones stays all-ones");
    checku(-1, 4, ALU_SRL, 268435455, "SRL all-ones zero-fills top bits");

    write(l, string'("-------------------------------------")); writeline(output, l);
    write(l, string'("ALU unit test: ")); write(l, pass_count);
    write(l, string'(" passed, ")); write(l, fail_count); write(l, string'(" failed"));
    writeline(output, l);
    assert fail_count = 0 report "ALU TESTBENCH FAILED" severity failure;
    report "ALU TESTBENCH PASSED";
    wait;
  end process;
end architecture sim;
