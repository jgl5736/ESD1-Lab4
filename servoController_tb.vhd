--  AUTHOR: Jack Lowrey
--  LAB NAME:  Servo Controller
--  FILE NAME:  servoController_tb.vhd
--

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

ENTITY servoController_tb IS
END ENTITY servoController_tb;

ARCHITECTURE rtl OF servoController_tb IS

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

  constant period       : time := 20 ns;
  constant min_angle    : integer := 50000;
  constant max_angle    : integer := 100000;
  
  signal clk        : std_logic := '0';          -- 50 Mhz system clock
  signal reset_n    : std_logic := '0';          -- active low system reset
  signal write      : std_logic := '0';          -- active high write enable
  signal address    : std_logic := '0';          -- address of register to be written to (from CPU)
  signal writedata  : std_logic_vector(31 DOWNTO 0) := (others => '0');  -- data from the CPU to be stored in the component
  signal out_wave_export  : std_logic;  -- wave data visible to other components
  signal irq : std_logic;  -- signal to interrupt the processor
    
BEGIN

  -- clock process
  clock: process
  begin
    clk <= not clk;
    wait for period/2;
  end process; 
   
  -- reset process
  async_reset: process
  begin
    wait for period;
    reset_n <= '1';
    wait;
  end process; 

  -- ISR sets write high for one clock
  -- ISR : process
  -- BEGIN
    -- wait until rising_edge(irq);
    -- write <= '1';
    -- wait until rising_edge(clk);
    -- wait until falling_edge(clk);
    -- write <= '0';
  -- end process;

  main : process
  BEGIN
    wait until rising_edge(irq);
    address <= '0';
    write <= '1';
    writedata <= std_logic_vector(to_unsigned(min_angle,32));
    wait for period;
    write <= '0';
    wait for period;
    address <= '1';
    wait for period;
    write <= '1';
    writedata <= std_logic_vector(to_unsigned(max_angle,32));
    wait for period;
    write <= '0';
    wait;
  end process;

  uut : servoController
  port map(
    clk      => clk,
    reset_n  => reset_n,
    write    => write,
    address  => address,
    writedata => writedata,
    out_wave_export => out_wave_export,
    irq => irq
  );

END ARCHITECTURE rtl;
