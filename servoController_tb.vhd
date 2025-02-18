--  AUTHOR: Jack Lowrey
--  LAB NAME:  Servo Controller
--  FILE NAME:  servoController.vhd
--

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

ENTITY servoController_tb IS
END ENTITY servoController_tb;

ARCHITECTURE rtl OF servoController IS

  component servoController IS
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
  END component;

  signal clk        : std_logic;          -- 50 Mhz system clock
  signal reset_n    : std_logic;          -- active low system reset
  signal write      : std_logic;          -- active high write enable
  signal address    : std_logic;          -- address of register to be written to (from CPU)
  signal writedata  : std_logic_vector(31 DOWNTO 0);  -- data from the CPU to be stored in the component
  signal out_wave_export  : std_logic;  -- wave data visible to other components
  signal irq : std_logic  -- signal to interrupt the processor
    
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


uut : servoController
  port map(
    clk      => clk,
    reset_n  => reset,
    write    => write,
    address  => address,
    writedata => writedata,
    out_wave_export => out_wave_export,
    irq => irq
  );

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
