--  AUTHOR: Jack Lowrey
--  LAB NAME:  Servo Controller
--  FILE NAME:  servoSweep.vhd
--

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

ENTITY servoSweep IS
  PORT( CLOCK_50  : IN    std_logic;
        KEY       : IN    std_logic_vector(0 DOWNTO 0);
        SW        : IN    std_logic_vector(3 DOWNTO 0);
        LEDR      : OUT   std_logic_vector(9 DOWNTO 0)
      );
END ENTITY servoSweep;

ARCHITECTURE rtl OF servoSweep IS

  signal cntr : std_logic_vector(25 downto 0);
  
  -- ram_type is a 2-dimensional array or inferred ram.  
  -- It stores eight 32-bit values
  TYPE ram_type IS ARRAY (1 DOWNTO 0) OF std_logic_vector (31 DOWNTO 0);
  SIGNAL Registers : ram_type;          --instance of ram_type
  
  type state_type is (SWEEP_RIGHT, INT_RIGHT, SWEEP_LEFT, INT_LEFT);
  signal next_state : state_type;
  signal current_state : state_type;
  signal is_new_state : std_logic;

BEGIN

  LEDR(9) <= cntr(24);

  --this process loads data from the CPU.  The CPU provides the address, 
  --the data and the write enable signal
  PROCESS(clk, reset_n)
  BEGIN
    IF (reset_n = '0') THEN
      --Registers <= (OTHERS => "00000000000000000000000000000000");
    ELSIF (clk'event AND clk = '1') THEN
      IF (write = '1') THEN
        Registers(to_integer(unsigned(address))) <= writedata;
        --when write enable is active, the ram location at the given address
        --is loaded with the input data
      END IF;
    END IF;
  END PROCESS;


--this process updates the internal address on each clock edge.
  latch : PROCESS(clk, reset_n)
  BEGIN
    IF (reset_n = '0') THEN
      internal_addr <= '0';
    ELSIF (clk'event AND clk = '1') THEN
      internal_addr <= ext_addr;
    END IF;
  END PROCESS;

  --- heartbeat counter --------
  counter_proc : process (CLOCK_50) begin
    if (rising_edge(CLOCK_50)) then
      if (reset_n = '0') then
        cntr <= "00" & x"000000";
      else
        cntr <= cntr + ("00" & x"000001");
      end if;
    end if;
  end process counter_proc;
  
END ARCHITECTURE rtl;         
