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
  signal wave : std_logic := '0';
  signal count : integer := 0;
  signal angle_count : integer := 0;
  constant period_count : integer := 1000000;
  
  -- ram_type is a 2-dimensional array or inferred ram.  
  -- It stores eight 32-bit values
  TYPE ram_type IS ARRAY (1 DOWNTO 0) OF std_logic_vector (31 DOWNTO 0);
  SIGNAL Registers : ram_type;          --instance of ram_type
  alias min_angle_count : std_logic_vector(31 DOWNTO 0) is Registers(0);
  alias max_angle_count : std_logic_vector(31 DOWNTO 0) is Registers(1);
  
  --internal signal to address ram
  SIGNAL internal_addr : std_logic_vector(1 DOWNTO 0) := "00";  
  
  type state_type is (SWEEP_RIGHT, INT_RIGHT, SWEEP_LEFT, INT_LEFT);
  signal next_state : state_type;
  signal current_state : state_type;
  signal is_new_state : boolean := false;
  
BEGIN

  out_wave_export <= wave;
  is_new_state <= (current_state /= next_state);
  
  --this process loads data from the CPU.  The CPU provides the address, 
  --the data and the write enable signal
  PROCESS(clk, reset_n)
  BEGIN
    IF (reset_n = '0') THEN
      Registers(0) <= x"C350";
      Registers(1) <= x"186A0";
    ELSIF (clk'event AND clk = '1') THEN
      IF (write = '1') THEN
        Registers(to_integer(unsigned(internal_addr))) <= writedata;
        --when write enable is active, the ram location at the given address
        --is loaded with the input data
      END IF;
    END IF;
  END PROCESS;

  --- PWM Counter
  PWM_counter : process(clk)
  BEGIN 
    IF (clk'event AND clk = '1') THEN
      if (count < period_count) then
        count <= count + 10000;
      else
        count <= 0;
      end if;
    end if;
  end process;

  --this process updates the internal address on each clock edge.
  latch : PROCESS(clk, reset_n)
  BEGIN
    IF (reset_n = '0') THEN
      internal_addr(0) <= '0';
    ELSIF (clk'event AND clk = '1') THEN
      internal_addr(0) <= address;
    END IF;
  END PROCESS;

  --Update current_state
  state : PROCESS(clk, reset_n)
  BEGIN
    IF (reset_n = '0') THEN
      current_state <= SWEEP_RIGHT;
    ELSIF (clk'event AND clk = '1') THEN
      current_state <= next_state;
    END IF;
  END PROCESS;

  -- Next State Logic
  NSL : process(current_state, angle_count,write)
  BEGIN
    case (current_state) is
      when SWEEP_RIGHT =>
        if (angle_count >= to_integer(unsigned(max_angle_count))) THEN
          next_state <= INT_RIGHT;
        ELSE
          next_state <= SWEEP_RIGHT;
        end if;
      when INT_RIGHT =>
        if (write ='1') THEN
          next_state <= SWEEP_LEFT;
        else 
          next_state <= INT_RIGHT;
        end IF;
      when SWEEP_LEFT =>
        if (angle_count <= to_integer(unsigned(min_angle_count))) THEN
          next_state <= INT_LEFT;
        ELSE
          next_state <= SWEEP_LEFT;
        end if;
      when INT_LEFT=>
        if (write ='1') THEN
          next_state <= SWEEP_RIGHT;
        else 
          next_state <= INT_LEFT;
        end IF;
      when others =>
        next_state <= SWEEP_RIGHT;
    end case;
  end PROCESS;
  
  -- wave output logic
  wave_output : process(count)
  BEGIN
    if (count < angle_count) then
      wave <= '1';
    elsif (count < period_count) then
      wave <= '0';
    end if;
  end process;
  
  -- Servo Sweep logic
  sweep : process(count)
  BEGIN
    if (current_state = SWEEP_RIGHT) THEN
      if (is_new_state) THEN
        angle_count <= to_integer(unsigned(min_angle_count));
      end if;
      if (count = 0) THEN
        if (angle_count <= to_integer(unsigned(max_angle_count))) THEN
          angle_count <= angle_count + to_integer(unsigned'(x"002710"));
        else 
          angle_count <= to_integer(unsigned(max_angle_count));
        end if;
      end if;
    elsif (current_state = SWEEP_LEFT) THEN
      if (is_new_state) THEN
        angle_count <= to_integer(unsigned(max_angle_count));
      end if;
      if (count = 0) THEN
        if (angle_count >= to_integer(unsigned(min_angle_count))) THEN
          angle_count <= angle_count - to_integer(unsigned'(x"002710"));
        else 
          angle_count <= to_integer(unsigned(min_angle_count));
        end if;
      end if;
    end if;
  end PROCESS;
  
  --this process interrupts the processor once a sweep is complete
  interrupts : PROCESS(current_state)
  BEGIN
    IF (current_state = INT_RIGHT or current_state = INT_LEFT) THEN
      irq <= '1';
    ELSE
      irq <= '0';
    END IF;
  END PROCESS;

END ARCHITECTURE rtl;
