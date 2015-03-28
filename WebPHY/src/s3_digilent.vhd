-------------------------------------------------------------------------------
--
--  Title  : s3_digilent.vhd
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
use IEEE.std_logic_textio.all;
use STD.textio.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity s3_digilent is
  port
  (
    osc_in        : in std_logic;
    leds          : out std_logic_vector(0 to 7);
    tx_p          : out std_logic;
    tx_n          : out std_logic;
    rx_p          : in std_logic;
    rx_n          : in std_logic;
    link_l        : out std_logic;
    act_l         : out std_logic;
    tx_tst        : out std_logic; --scope debug
    rx_tst        : out std_logic; --scope debug
    servo_out     : out std_logic;
    seg7          : out std_logic_vector(6 downto 0);
    anode         : out std_logic_vector(3 downto 0)
  );
end s3_digilent;

architecture s3_digilent_arch of s3_digilent is

  signal clk80              : std_logic;
  signal rst80              : std_logic;
  signal rst_pipe           : std_logic_vector(15 downto 0) := (others => '1');
  signal locked_out         : std_logic;

  -- webpage_rom
  signal webram_rd_addr     : std_logic_vector(15 downto 0);
  signal webram_rd_dat      : std_logic_vector(7 downto 0);
  signal webram_rd          : std_logic;
  signal webram_size        : std_logic_vector(15 downto 0);
  
  -- update to webpage_rom
  signal webram_wr_addr     : std_logic_vector(15 downto 0);
  signal webram_wr_dat      : std_logic_vector(7 downto 0);
  signal webram_wr          : std_logic;

  -- databus
  signal databus_addr       : std_logic_vector(31 downto 0);
  signal databus_rd         : std_logic;
  signal databus_rd_ack     : std_logic;
  signal databus_rd_dat     : std_logic_vector(7 downto 0);
  signal databus_wr         : std_logic;
  signal databus_wr_dat     : std_logic_vector(7 downto 0);
  
  component WebPHY_DATABUS is
    port
    (
      -- clk/reset
      clk80               : in std_logic;
      rst80               : in std_logic;
      
      -- Webpage RAM
      webram_rd_addr      : out std_logic_vector(15 downto 0);
      webram_rd_dat       : in std_logic_vector(7 downto 0);
      webram_rd           : out std_logic;
      webram_size         : in std_logic_vector(15 downto 0);
      webram_wr_dat       : out std_logic_vector(7 downto 0);
      webram_wr_addr      : out std_logic_vector(15 downto 0);
      webram_wr           : out std_logic;
      
      -- Network params
      ip_address_src_1    : in std_logic_vector(7 downto 0);
      ip_address_src_2    : in std_logic_vector(7 downto 0);
      ip_address_src_3    : in std_logic_vector(7 downto 0);
      ip_address_src_4    : in std_logic_vector(7 downto 0);
      
      mac_address_src_1   : in std_logic_vector(7 downto 0);
      mac_address_src_2   : in std_logic_vector(7 downto 0);
      mac_address_src_3   : in std_logic_vector(7 downto 0);
      mac_address_src_4   : in std_logic_vector(7 downto 0);
      mac_address_src_5   : in std_logic_vector(7 downto 0);
      mac_address_src_6   : in std_logic_vector(7 downto 0);
      
      -- User Databus Interface
      rd                  : out std_logic;
      rd_ack              : in std_logic;
      rd_dat              : in std_logic_vector(7 downto 0);
      wr                  : out std_logic;
      wr_dat              : out std_logic_vector(7 downto 0);
      addr                : out std_logic_vector(31 downto 0);
      
      -- Ethernet Interface
      tx_p                : out std_logic;
      tx_n                : out std_logic;
      rx_p                : in std_logic;
      rx_n                : in std_logic;
      led_link_l          : out std_logic;
      led_act_l           : out std_logic;
        
      -- Status
      status              : out std_logic_vector(8 downto 0)
    );
  end component;
  
  signal status             : std_logic_vector(8 downto 0);
  
begin

  -----------------------------------------------------------------
  -- Reset
  rst_proc : process(clk80,locked_out)
  begin
    if locked_out = '0' then
      rst_pipe <= (others => '1');
    elsif rising_edge(clk80) then
      rst_pipe <= '0' & rst_pipe(rst_pipe'high downto 1);
    end if;
  end process;
  rst80 <= rst_pipe(0);
  
  -----------------------------------------------------------------
  -- Clock
  mydcm : entity work.mydcm
    port map (
      clkin_in        => osc_in,
      rst_in          => '0',
      clkfx_out       => clk80,
      clkin_ibufg_out => open,
      clk0_out        => open,
      locked_out      => locked_out
    );

  ----------------------------------------------------------------
  -- This is the WebPHY_DATABUS.ngc instantiation.
  WebPHY_DATABUS_i : WebPHY_DATABUS
    port map (
      -- clk/reset
      clk80             => clk80,
      rst80             => rst80,
      
      -- Webpage RAM
      webram_rd_addr    => webram_rd_addr,
      webram_rd_dat     => webram_rd_dat,
      webram_rd         => webram_rd,
      webram_size       => webram_size,
      webram_wr_addr    => webram_wr_addr,
      webram_wr_dat     => webram_wr_dat,
      webram_wr         => webram_wr,
      
      -- Network params
      ip_address_src_1  => X"C0",
      ip_address_src_2  => X"A8",
      ip_address_src_3  => X"01",
      ip_address_src_4  => X"05",
      
      mac_address_src_1 => X"00",
      mac_address_src_2 => X"12",
      mac_address_src_3 => X"34",
      mac_address_src_4 => X"56",
      mac_address_src_5 => X"78",
      mac_address_src_6 => X"91",
      
      -- User Databus Interface
      rd                => databus_rd,
      rd_ack            => databus_rd_ack,
      rd_dat            => databus_rd_dat,
      wr                => databus_wr,
      wr_dat            => databus_wr_dat,
      addr              => databus_addr,
      
      -- Ethernet Interface
      tx_p              => tx_p,
      tx_n              => tx_n,
      rx_p              => rx_p,
      rx_n              => rx_n,
      led_link_l        => link_l,
      led_act_l         => act_l,
      
      -- Status
      status            => status
    );
    
  ----------------------------------------------------------------
  -- Instantiate webram generated by romgen.pl.
  webram : entity work.webram
    port map (
      clk     => clk80,
      rd_addr => webram_rd_addr,
      rd_dat  => webram_rd_dat,
      rd      => webram_rd,
      size    => webram_size,
      wr_addr => webram_wr_addr,
      wr_dat  => webram_wr_dat,
      wr      => webram_wr
    );

  ----------------------------------------------------------------
  -- Example user logic includes block ram and readback registers
  -- which drive a r/c servo interface.
  user_logic : entity work.user_logic
    port map (
      -- clk/rst
      clk       => clk80,
      rst       => rst80,
      -- databus interface
      rd        => databus_rd,
      rd_ack    => databus_rd_ack,
      rd_dat    => databus_rd_dat,
      wr        => databus_wr,
      wr_dat    => databus_wr_dat,
      addr      => databus_addr,
      -- IO
      status    => status,
      servo_out => servo_out,
      leds      => leds,
      seg7      => seg7,
      anode     => anode
    );

  --------------------------------------------------------------
  -- Bring out tx and rx testpoints for o-scope viewing.
  rx_tst <= status(7);
  tx_tst <= status(8);
  
  ----------------------------------------------------------------

end s3_digilent_arch;
