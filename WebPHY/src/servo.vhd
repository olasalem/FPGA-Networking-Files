-------------------------------------------------------------------------------
--
--  Title  : servo.vhd
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

--this module interfaces rc servos.  it produces a pulse width of 1 to 2 ms with 10 bit resolution.
--the pulse is repeated every 16 ms.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity servo is
port(
  clk : in std_logic;
  cmd_in : in std_logic_vector(9 downto 0);		 
  pwm_out : out std_logic
);
end servo;

architecture servo of servo is 
signal timebase_975ns_cnt : integer range 0 to 78;
signal timebase_975ns : std_logic; 
signal pwm_ramp : std_logic_vector(13 downto 0);
signal cmd: std_logic_vector(13 downto 0);

begin 

timebase_975ns_proc : process(clk)
begin
  if rising_edge(clk) then
    if timebase_975ns_cnt < 77 then
      timebase_975ns_cnt  <= timebase_975ns_cnt + 1;
      timebase_975ns      <= '0';
    else
      timebase_975ns_cnt  <= 0;
      timebase_975ns      <= '1';
    end if;
  end if;
end process;


process(clk)
begin
  if rising_edge(clk) then
    if timebase_975ns = '1' then
        pwm_ramp <= pwm_ramp + "00000000000001";
    end if;
    cmd <= "0001" & cmd_in;
    if (pwm_ramp > cmd) then
        pwm_out <= '0';
    else
        pwm_out <= '1';
    end if;  
  end if;
end process;

end servo;
