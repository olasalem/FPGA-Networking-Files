--Copyright or © or Copr. DENIS CARVIN
--dcarvin@laas.fr
--This software is a computer program whose purpose is to [describe
--functionalities and technical features of your software].
--
--This software is governed by the CeCILL  license under French law and
--abiding by the rules of distribution of free software.  You can  use, 
--modify and/ or redistribute the software under the terms of the CeCILL
--license as circulated by CEA, CNRS and INRIA at the following URL
--"http://www.cecill.info". 
--
--As a counterpart to the access to the source code and  rights to copy,
--modify and redistribute granted by the license, users are provided only
--with a limited warranty  and the software's author,  the holder of the
--economic rights,  and the successive licensors  have only  limited
--liability. 
--
--In this respect, the user's attention is drawn to the risks associated
--with loading,  using,  modifying and/or developing or reproducing the
--software by the user in light of its specific status of free software,
--that may mean  that it is complicated to manipulate,  and  that  also
--therefore means  that it is reserved for developers  and  experienced
--professionals having in-depth computer knowledge. Users are therefore
--encouraged to load and test the software's suitability as regards their
--requirements in conditions enabling the security of their systems and/or 
--data to be ensured and,  more generally, to use and operate it in the 
--same conditions as regards security. 
--
--The fact that you are presently reading this means that you have had
--knowledge of the CeCILL license and that you accept its terms.
----------------------------------------------------------------------------------
--Dependency eth_frame.vhd
--This entity is provided to illustrate the use of two components which are :
--1) ethcrc32.vhd
--2) mac2phy4IR
-- Its behavior is quite simple and has 3 states : Idle, receiving, transmitting.
--When Idle the entity wait for a frame to receive or the end of a timer.
--When Receiving the entity read the incoming frame and check if the crc is correct
--For a correct crc, the entity increment a counter that is cabled on the MS
--LEDS, for a bad crc, a second counter is used and linked to LS LEDS.
--When Transmitting, the entity transmit a frame defined in the package eth_frame
--Depending on the value of NUM (switches of the board) a frame is sent on the medium
--with the correct CRC.
-- When the frame is sent or received, the entity return in the Idle state.
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.BEMAC4RT.ALL;

entity hello_eth is
    Port ( 	  -- General purpose ports
				  RST : in  std_logic;
				  LED: out std_logic_vector(7 downto 0);
  				  NUM : in STD_LOGIC_VECTOR(7 downto 0);
				  --PHY ports
				  --General purpose
				  MDIO : inout  std_logic;
				  MDC : out  std_logic;
				  RESETN : out  std_logic;
				  COL : in  std_logic;
				  CRS : in  std_logic;
				  --TX
				  TXD :out  std_logic_vector (3 downto 0);
				  TXER : out  std_logic;
				  TXEN: out std_logic;
				  TXCLK : in  STD_LOGIC;
				  --RX
				  RXD : in  std_logic_vector (3 downto 0);
				  RXER : in  std_logic;
				  RXDV : in  std_logic;
				  RXCLK : in  std_logic);
end hello_eth;

architecture Behavioral of hello_eth is
	--Constants and type
	constant fin_timer:integer:=50000000;
	--constant fin_timer:integer:=8;
	Type possible_state is (Idle,Receiving,Decoding_crc,Transmitting);

	--Components
	component ethcrc32 is
	  port (	clk 		: in std_logic;
				rst		: in std_logic;
				en			: in std_logic;
				is_msb	: in std_logic;
				data_in 	: in std_logic_vector (7 downto 0);
				crc_out 	: out std_logic_vector (31 downto 0));
	end component;

	component mac2phy4IR is
		 Port ( 
				  -- General purpose ports
				  RSTN : in  std_logic;
				  --PHY ports
				  --General purpose
				  MDIO : inout  std_logic;
				  MDC : out  std_logic;
				  RESETN : out  std_logic;
				  COL : in  std_logic;
				  CRS : in  std_logic;
				  --TX
				  TXD :out  std_logic_vector (3 downto 0);
				  TXER : out  std_logic;
				  TXEN: out std_logic;
				  TXCLK : in  STD_LOGIC;
				  --RX
				  RXD : in  std_logic_vector (3 downto 0);
				  RXER : in  std_logic;
				  RXDV : in  std_logic;
				  RXCLK : in  std_logic;
				  --MAC Ports
				  --General purpose
				  COLLISION: out std_logic;
				  CARRIER: out std_logic;
  				  CLK : out std_logic;
				  --TX
				  TDATA: in std_logic_vector (7 downto 0);
				  TXVALID: in std_logic;
				  --RX
				  RDATA : out std_logic_vector (7 downto 0);
				  RXVALID: out std_logic);
	end component;


	signal my_frame : frame60 :=udp_frameA;

	--GP signals
	signal not_reset: std_logic:='1';
	signal local_clk: std_logic:='0';
	--Internal signals
	--Timer to wait for new transmission
	signal timer : integer range 0 to fin_timer:=0;
	--Counter of transmitted/received bytes
	signal byte_num: integer range 0 to my_frame'right+13:=0;
	--Keep the state of the entity
	signal state: possible_state:=Idle;
	--Shit register to bufferize the received data for crc computation purpose
	signal data_received : byte_array(3 downto 0):=(others=>x"00");
	--Received frame counter
	signal nb_received_frame: integer range 0 to 15 :=0;
	signal nb_error_frame: integer range 0 to 15 :=0;

	--crc_core signals
	signal crc: byte_array(0 to 3):=(others=>x"00");
	signal crc_crc_out: std_logic_vector(31 downto 0);
	signal crc_data_in : std_logic_vector(7 downto 0):=x"00";
	signal crc_en: std_logic:='0';
	signal crc_is_msb: std_logic:='1';
	signal crc_rst: std_logic:='1';
	signal crc_clk: std_logic:='0';

	--mac2phy4IR signals
	signal  m2p_COLLISION:  STD_LOGIC;
	signal  m2p_CARRIER:  STD_LOGIC;
	signal  m2p_CLK :  STD_LOGIC;
	signal  m2p_TDATA:  STD_LOGIC_VECTOR (7 downto 0):=x"00";
	signal  m2p_TXVALID:  STD_LOGIC:='0';
	signal  m2p_RDATA :  STD_LOGIC_VECTOR (7 downto 0);
	signal  m2p_RXVALID:  STD_LOGIC;
			
begin

	-- Component instantiation
	crc_core : ethcrc32 port map (crc_clk,crc_rst,crc_en,crc_is_msb,crc_data_in,crc_crc_out);
	
	m2p		: mac2phy4IR port map(not_reset,MDIO,MDC,RESETN,COL,CRS,
											 TXD,TXER,TXEN,TXCLK,
											 RXD,RXER,RXDV,RXCLK,
											 m2p_COLLISION,m2p_CARRIER,m2p_CLK,m2p_TDATA,m2p_TXVALID,
											 m2p_RDATA,m2p_RXVALID);
	--Trivial mapping
	not_reset<=not rst;
	local_clk<=m2p_CLK;
	crc(0)<= crc_crc_out(31 downto 24);
	crc(1)<= crc_crc_out(23 downto 16);
	crc(2)<= crc_crc_out(15 downto 8);
	crc(3)<= crc_crc_out(7 downto 0);
	LED(7 downto 4)<=std_logic_vector(to_unsigned(nb_error_frame,4));
	LED(3 downto 0)<=std_logic_vector(to_unsigned(nb_received_frame,4));
		
	--Frame mapping
	my_frame<=udp_frameA when unsigned(NUM)=0 else
				 udp_frameB;
	
	
	--Main transmission process

	process(RST,local_clk) is 

	begin

		if (RST='1') then
			state<=Idle;
			byte_num<=0;
			crc_en<='0';
			crc_is_msb<='1';
			crc_rst<='1';
			m2p_TDATA<=x"00";
			nb_received_frame<=0;
			nb_error_frame<=0;
			crc_clk<='0';
		elsif (rising_edge(local_clk)) then
			case state is
				when Idle =>
						-- Reception is starting
						if m2p_RXVALID='1' and m2p_RDATA=x"AB" then
							timer<=0;
							state<=Receiving;
							crc_rst<='0';
							crc_clk<='0';
						--Time to transmit
						elsif (timer=fin_timer)then
							timer<=0;
							state<=Transmitting;
							crc_clk<='0';
							crc_rst<='0';
						-- wait if no carrier sensed
						elsif (m2p_CARRIER='0') then
							timer<=timer+1;
						end if;
				when Receiving =>
						if crc_clk='1' then
							if byte_num<4 then
								data_received(3 downto 1)<=data_received(2 downto 0);
								data_received(0)<= not m2p_RDATA;
							end if;
							if byte_num>3 then
								data_received(3 downto 1)<=data_received(2 downto 0);
								data_received(0)<= m2p_RDATA;
								crc_data_in<=data_received(3);
								crc_en<='1';
								crc_is_msb<='0';
							end if;		
								
							if  m2p_RXVALID='1' then
								byte_num<=byte_num+1;
							else
								byte_num<=0;
								state<=Decoding_crc;
							end if;
						end if;
						crc_clk<=not crc_clk;
				when Decoding_crc =>
						if crc_clk='1' then
							crc_is_msb<='1';
							crc_data_in<= not data_received(3);
							data_received(3 downto 1)<=data_received(2 downto 0);
							data_received(0)<=m2p_RDATA;					
							if (byte_num=4) then
								byte_num<=0;
								state<=Idle;
								crc_en<='0';
								crc_rst<='1';
								if to_integer(unsigned(crc_crc_out))=0 then
									nb_received_frame<=nb_received_frame+1;
								else
									nb_error_frame<=nb_error_frame+1;
								end if;
							else 
								byte_num<=byte_num+1;
							end if;
						end if;
						crc_clk<=not crc_clk;
				 when Transmitting => 
						if crc_clk='1' then
							-- Manage TDATA values
							if byte_num<7 then -- Send preamble 			
								m2p_TDATA<=x"AA";
							end if;
							if byte_num=7 then -- Send SFD
								m2p_TDATA<=x"AB";
							end if;
							if byte_num>7 and byte_num<my_frame'right+9 then -- Send Data LSB first 
								for I in 0 to 7 loop
									m2p_TDATA(I)<=my_frame(byte_num-8)(7-I);
								end loop;
							end if;
							if byte_num>my_frame'right+8 and byte_num<my_frame'right+13 then --send CRC MSB first 
								m2p_TDATA<=not crc(byte_num-my_frame'right-9);
							end if;
										
							-- Manage CRC computation
							if byte_num>2 and byte_num<7 then 
								crc_en<='1';
								crc_is_msb<='1';
								crc_data_in<=not my_frame(byte_num-3);
							end if;
							
							if byte_num>6 and byte_num<my_frame'right+4 then
								crc_en<='1';
								crc_is_msb<='1';
								crc_data_in<= my_frame(byte_num-3);
							end if;
							
							if byte_num=my_frame'right+4 then
								crc_data_in<=x"00";
							end if;
							
							if byte_num=my_frame'right+8 then
								crc_en<='0';
							end if;
							
							-- Return to Idle or continue to send byte
							if (byte_num=my_frame'right+13) then
								byte_num<=0;
								state<=Idle;
								crc_rst<='1';
								m2p_TXVALID<='0';
							else
								byte_num<=byte_num+1;
								m2p_TXVALID<='1';
							end if;
						end if;
						crc_clk<=not crc_clk;
			end case;
		end if;
	end process;

end Behavioral;
