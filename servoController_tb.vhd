--  AUTHOR: Jack Lowrey
--  LAB NAME:  Servo Controller
--  FILE NAME:  servoController.vhd
--

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

ENTITY servoController IS
  PORT(
    clk        : IN std_logic;          -- 50 Mhz system clock
    reset_n    : IN std_logic;          -- active low system reset
    write      : IN std_logic;          -- active high write enable
    address    : IN std_logic;          -- address of register to be written to (from CPU)
    writedata  : IN std_logic_vector(31 DOWNTO 0);  -- data from the CPU to be stored in the component
    --
    out_wave_export  : OUT std_logic;  -- wave data visible to other components
    irq : OUT std_logic  -- signal to interrupt the processor                      
    );
END ENTITY servoController;

ARCHITECTURE rtl OF servoController IS

  signal cntr : std_logic_vector(25 downto 0);
  signal period_cntr : std_logic_vector(25 downto 0);
  signal angle_cntr : std_logic_vector(25 downto 0);
  
  -- ram_type is a 2-dimensional array or inferred ram.  
  -- It stores eight 32-bit values
  TYPE ram_type IS ARRAY (1 DOWNTO 0) OF std_logic_vector (31 DOWNTO 0);
  SIGNAL Registers : ram_type;          --instance of ram_type

  --internal signal to address ram
  SIGNAL internal_addr : std_logic;  
  
  type state_type is (SWEEP_RIGHT, INT_RIGHT, SWEEP_LEFT, INT_LEFT);
  signal next_state : state_type;
  signal current_state : state_type;
  signal is_new_state : std_logic;
  
BEGIN

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

  --this process interrupts the processor once a sweep is complete
  interrupts : PROCESS(current_state)
  BEGIN
    IF (current_state == INT_RIGHT || current_state == INT_LEFT) THEN
      irq <= '1';
    ELSE
      irq <= '0';
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
