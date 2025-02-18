--  AUTHOR: Jack Lowrey
--  LAB NAME:  Servo Controller
--  FILE NAME:  servoSweep.vhd
--

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

ENTITY servoSweep IS
  PORT(CLOCK_50  : IN    std_logic;
       KEY       : IN    std_logic_vector(0 DOWNTO 0);
       SW        : IN    std_logic_vector(3 DOWNTO 0);
       LEDR      : OUT   std_logic_vector(9 DOWNTO 0)
       );
END ENTITY servoSweep;

ARCHITECTURE rtl OF servoSweep IS

  -- ram_type is a 2-dimensional array or inferred ram.  
  -- It stores eight 32-bit values
  TYPE ram_type IS ARRAY (1 DOWNTO 0) OF std_logic_vector (31 DOWNTO 0);
  SIGNAL Registers : ram_type;          --instance of ram_type
  
  type state_type is (SWEEP_RIGHT, INT_RIGHT, SWEEP_LEFT, INT_LEFT);
  signal next_state : state_type;
  signal current_state : state_type;
  signal is_new_state : std_logic;

  --internal signal to address ram
  SIGNAL internal_addr : std_logic;  
  SIGNAL ext_addr  : std_logic;  
  SIGNAL ext_data  : std_logic;  
  
BEGIN

  ext_addr <= ext_addr_export;
  out_wave_export <= ext_data;

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

-- Next State Logic
  nsl : process(clk, reset_n)
  BEGIN
    IF (reset_n = '0') THEN
      next_state <= SWEEP_RIGHT;
    ELSIF (clk'event AND clk = '1') THEN
      case (current_state) is
        when SWEEP_RIGHT =>
          if (angle_count >= max_angle_count) THEN
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
          if (angle_count <= min_angle_count) THEN
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
      end case;
    END IF;
      
  --output the data being requested
  ext_data <= Registers(conv_integer(internal_addr));  

  --this process interrupts the processor if it receives and invalid signal
  interrupts : PROCESS(invalid)
  BEGIN
    IF  THEN
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
