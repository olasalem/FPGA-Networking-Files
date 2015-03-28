-------------------------------------------------------------------------------
--
--  Title  : user_logic.vhd
--  COPYRIGHT (C) 2009 WebPHY
--   _       __     __    ____  __  ____  __  
--  | |     / /__  / /_  / __ \/ / / /\_\/_/  
--  | | /| / / _ \/ __ \/ /_/ / /_/ /  \__/   
--  | |/ |/ /  __/ /_/ / ____/ __  /   / /    
--  |__/|__/\___/_.___/_/   /_/ /_/   /_/  
-- 
--  All rights reserved.
-- 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity user_logic is
  port (
    -- clk/rst
    clk                 : in std_logic;
    rst                 : in std_logic;
    -- databus interface
    rd                  : in std_logic;
    rd_ack              : out std_logic;
    rd_dat              : out std_logic_vector(7 downto 0);
    wr                  : in std_logic;
    wr_dat              : in std_logic_vector(7 downto 0);
    addr                : in std_logic_vector(31 downto 0);
    -- IO
    status              : in std_logic_vector;
    servo_out           : out std_logic;
    leds                : out std_logic_vector;
    -- 7-seg display
    seg7                : out std_logic_vector(6 downto 0);
    anode               : out std_logic_vector(3 downto 0)
  );
end user_logic;

architecture user_logic_arch of user_logic is
  -- stat_count_proc
  type statcnt_type is array (status'range) of std_logic_vector(7 downto 0);
  signal statcnt              : statcnt_type;
  signal statcnt_rst          : std_logic;
  signal rd_dat_mem           : std_logic_vector(7 downto 0);
  signal rd_dat_regs          : std_logic_vector(7 downto 0);
  signal rd_r1                : std_logic;
  signal wr_mem               : std_logic;
  signal sel                  : integer range 0 to 3;
  signal servo_cmd            : std_logic_vector(15 downto 0) := X"8000";
  signal servo_cmd_hibyte     : std_logic_vector(7 downto 0);
begin
  ----------------------------------------------------------------
  sel <= to_integer(unsigned(addr(13 downto 12)));

  ----------------------------------------------------------------
  -- Count status pulses from core
  stat_count_proc : process(clk)
  begin
    if rising_edge(clk) then
      if statcnt_rst = '1' then
        statcnt <= (others => (others => '0'));
      else
        for i in status'range loop
          if status(i) = '1' then
            statcnt(i) <= statcnt(i) + 1;
          end if;
        end loop;
      end if;
    end if;
  end process;
    
  ----------------------------------------------------------------
  -- read/write regs
  wr_regs_proc : process(clk)
  begin
    if rising_edge(clk) then
      if wr = '1' and sel = 0 then
        case addr(11 downto 0) is
          -- servo
          when X"000" => servo_cmd_hibyte <= wr_dat;
          when X"001" => servo_cmd <= servo_cmd_hibyte & wr_dat;
          -- leds 
          when X"010" => leds <= wr_dat;
          when X"011" => statcnt_rst <= wr_dat(0); -- reset status counters
          
          when others => null;
        end case;
      end if;
    end if;
  end process;
  
  rd_regs_proc : process(clk)
  begin
    if rising_edge(clk) then
      case addr(3 downto 0) is
        when X"0" => rd_dat_regs <= statcnt(3);
        when X"1" => rd_dat_regs <= statcnt(4);
        when X"2" => rd_dat_regs <= statcnt(6);
        when others => null;
      end case;
    end if;
  end process;
  
  ----------------------------------------------------------------
  -- 4k BRAM
  wr_mem <= wr when sel = 1 else '0';
  
  mem : entity work.mem
    port map (
      clk     => clk,
      addr    => addr(11 downto 0),
      wr_dat  => wr_dat,
      wr      => wr_mem,
      rd_dat  => rd_dat_mem
    );
    
  --------------------------------------------------------------
  -- Servo
  servo : entity work.servo
    port map (
      clk        => clk,
      cmd_in         => servo_cmd(15 downto 6),
      pwm_out        => servo_out
    );

  ------------------------------------------------------------
  -- Digilent board display
  hex_to_quad7seg : entity work.hex_to_quad7seg
    port map (
      clk   => clk,
      rst   => rst,
      din   => servo_cmd(15 downto 0),
      seg7  => seg7,
      anode => anode
    );
    
  ------------------------------------------------------------
  -- Final mux + register of all readback paths
  final_rdmux_proc : process(clk)
  begin
    if rising_edge(clk) then
      case sel is
        when 0      => rd_dat <= rd_dat_regs;
        when 1      => rd_dat <= rd_dat_mem;
        when 2      => rd_dat <= rd_dat_mem;
        when 3      => rd_dat <= rd_dat_mem;
        when others => rd_dat <= rd_dat_mem;
      end case;
    end if;
  end process;
  
  -- This pipeline MUST match the total latency of the readback datapath
  -- pipeline for the WebPHY core to operate correctly.  In this
  -- example the BRAM and register mux are both registered, and 
  -- are followed by another registered mux.  Therefore the total
  -- depth is two, so we must add two registers between the core's
  -- rd output and rd_ack input.  This creates a "data valid"
  -- signal for the readback data to the core.
  rd_ack_proc : process(clk)
  begin
    if rising_edge(clk) then
      rd_r1  <= rd;
      rd_ack <= rd_r1;
    end if;
  end process;

  ------------------------------------------------------------
end user_logic_arch;