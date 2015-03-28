-------------------------------------------------------------------------------
--
--  Title  : hex_to_quad7seg.vhd
--  COPYRIGHT (C) 2009 WebPHY
--   _       __     __    ____  __  ____  __  
--  | |     / /__  / /_  / __ \/ / / /\_\/_/  
--  | | /| / / _ \/ __ \/ /_/ / /_/ /  \__/   
--  | |/ |/ /  __/ /_/ / ____/ __  /   / /    
--  |__/|__/\___/_.___/_/   /_/ /_/   /_/  
-- 
--   All rights reserved. 
-- 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity hex_to_quad7seg is
  port ( 
    clk   : in std_logic;
    rst   : in std_logic;
    din   : in std_logic_vector(15 downto 0);
    seg7  : out std_logic_vector(6 downto 0);
    anode : out std_logic_vector(3 downto 0)
  ); 
end hex_to_quad7seg;

architecture hex_to_quad7seg of hex_to_quad7seg is
  signal inccnt : std_logic_vector(13 downto 0);
  signal digit : std_logic_vector(1 downto 0);
  signal hex : std_logic_vector(3 downto 0);
begin
---------------------------------------------------------------------------------------
  inc_proc : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        inccnt <= (others => '0');
      else
        inccnt <= inccnt + 1;
      end if;
    end if;
  end process;
  
  digit <= inccnt(13 downto 12);
  
  scan_proc : process(clk)
  begin
    if rising_edge(clk) then
      case digit is
        when "00" => hex <= din(15 downto 12);  anode <= "1110";
        when "01" => hex <= din(11 downto 8);   anode <= "1101";
        when "10" => hex <= din(7 downto 4);    anode <= "1011";
        when "11" => hex <= din(3 downto 0);    anode <= "0111";
        when others => null;
      end case;
    end if;
  end process;

  seg7_proc : process(hex)
  begin
    case hex is
      when X"0" => seg7 <= "0000001";
      when X"1" => seg7 <= "1001111";
      when X"2" => seg7 <= "0010010";
      when X"3" => seg7 <= "0000110";
      when X"4" => seg7 <= "1001100";
      when X"5" => seg7 <= "0100100";
      when X"6" => seg7 <= "0100000";
      when X"7" => seg7 <= "0001111";
      when X"8" => seg7 <= "0000000";
      when X"9" => seg7 <= "0000100";
      when X"A" => seg7 <= "0001000";
      when X"B" => seg7 <= "1100000";
      when X"C" => seg7 <= "0110001";
      when X"D" => seg7 <= "1000010";
      when X"E" => seg7 <= "0110000";
      when X"F" => seg7 <= "0111000";
      when others => null;
    end case;
  end process;

end hex_to_quad7seg;

---------------------------------------------------------------------------------------



