-------------------------------------------------------------------------------
--
--  Title  : mem.vhd
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

entity mem is  
  port(
    clk     : in std_logic;
    addr    : in std_logic_vector;
    wr_dat   : in std_logic_vector(7 downto 0);
    wr      : in std_logic;
    rd_dat   : out std_logic_vector(7 downto 0)
  );
end mem;

architecture mem_arch of mem is
  type mem_type is array (0 to 2**addr'length-1) of std_logic_vector(7 downto 0);
  impure function init_mem return mem_type is
    variable ramimage : mem_type;
  begin
    for i in 0 to ramimage'high loop
      ramimage(i) := X"55";
    end loop;
    return ramimage;
  end function;
  signal mem : mem_type;
begin

  process(clk)
  begin
    if rising_edge(clk) then
      --Write to mem
      if wr = '1' then
        mem(to_integer(unsigned(addr))) <= wr_dat;
      end if;
      --Read from mem
      rd_dat <= mem(to_integer(unsigned(addr)));
    end if;
  end process;
  
end mem_arch;
