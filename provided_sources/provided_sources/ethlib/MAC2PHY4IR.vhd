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


----------------------------------------------------------------------------------
--This file defines an entity that simplifies the MII interface 
--with an Ethernet Physical layer. It particularly fits with the 
--Nexys3 developpment board from Digilent. 
--The entity have several types of ports:
--General purposes (RSTN)
--Physical ports to manage the communication with the MII Interface on 
--the physical layer side
--Mac ports to communicate with MAC layer
---------------------------------------------------------------------------------
--IMPORTANT:

--Because the physical interface has two clocks domains (RXCLK, TXCLK)
--This entity uses a FIFO component specific to the SPARTAN6 FPGA of NEXYS3 board
--As a result, the entity provide only one clock signal (CLK) to the mac layer.

---------------------------------------------------------------------------------
--MAC PORTS/INTERFACE COMMUNICATION:

-- COLLISION is set to '1' by the entity when the PHY layer has detected a collision
-- CARRIER is set to '1' by the entity when the PHY layer has detected a carrier
-- CLK clock given to the mac layer, based on the TXCLK of the PHY layer (25Mhz)
-- TDATA: 8 bits std_logic_vector that the MAC layer must provide to be transmitted
--			 TDATA value must be hold for 80 ns (2 periods clock)
-- TXVALID: A pulse of 40ns (1 period clock) must be hold when valid data is available on TDATA
-- RDATA: 8 bits std_logic_vector that the entity provide to the mac layer
--			 its value changes every 40ns (1 period clock). The mac layer must look for
--			 the SFD by checking every clock rising edge. Once the SFD is found, the 
--			 MAC layer only needs to check every two clock rising edges to have a valid value.
-- RXVALID: The entity set this flag to '1' when the receiver is synchronized, (ie) SFD is
--				about to be visible on RDATA.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mac2phy4IR is
    Port ( 
			  -- General purpose ports
			  RSTN : in  STD_LOGIC;
			  --PHY ports
			  --General purpose
			  MDIO : inout  STD_LOGIC;
           MDC : out  STD_LOGIC;
           RESETN : out  STD_LOGIC;
           COL : in  STD_LOGIC;
           CRS : in  STD_LOGIC;
			  --TX
           TXD :out  STD_LOGIC_VECTOR (3 downto 0);
           TXER : out  STD_LOGIC;
			  TXEN: out STD_LOGIC;
           TXCLK : in  STD_LOGIC;
			  --RX
           RXD : in  STD_LOGIC_VECTOR (3 downto 0);
           RXER : in  STD_LOGIC;
           RXDV : in  STD_LOGIC;
           RXCLK : in  STD_LOGIC;
			  --MAC Ports
			  --General purpose
			  COLLISION: out STD_LOGIC;
			  CARRIER: out std_logic;
			  CLK: out STD_LOGIC;
			  --TX
			  TDATA: in STD_LOGIC_VECTOR (7 downto 0);
			  TXVALID: in STD_LOGIC;
			  --RX
			  RDATA : out STD_LOGIC_VECTOR (7 downto 0);
			  RXVALID: out STD_LOGIC);
end mac2phy4IR;

architecture Behavioral of mac2phy4IR is
	signal first_nibble: Boolean :=true;
	signal nTXD : std_logic_vector(3 downto 0) :=(others=>'0');
	signal RXDbuf: std_logic_vector(7 downto 0):=(others=>'0');
	signal noDATA: std_logic:='1';
	signal fifoOUT : std_logic_vector(3 downto 0);
	signal rst : std_logic:='1';
	signal RXen : std_logic:='0';

	component fifo_core is 
		Port (
		 rst : IN STD_LOGIC;
		 wr_clk : IN STD_LOGIC;
		 rd_clk : IN STD_LOGIC;
		 din : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 wr_en : IN STD_LOGIC;
		 rd_en : IN STD_LOGIC;
		 dout : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 full : OUT STD_LOGIC;
		 empty : OUT STD_LOGIC);
	end component;
	
begin

	-- General purpose signals
	RESETN<=RSTN;
	COLLISION<=COL;
	CARRIER<=CRS;
	CLK<=TXCLK;
	--Pre cabled signals
	MDIO	 <='1';
	MDC	 <='0';
	TXER	 <='0';
	--Rx signals
	RDATA<= RXDbuf;
	RXVALID<=RXDV;
	--fifo signals
	RXen<= not noDATA;
	rst<= not RSTN;
	fifoRX : fifo_core port map (rst,RXCLK,TXCLK,RXD,RXDV,RXen,fifoOUT,open,noDATA);

	--Interfacing process
	process(TXCLK,RSTN) is begin
		if (RSTN='0') then
				first_nibble<=true;
				TXD<=(others=>'0');
				RXDbuf<= (others=>'0');
		elsif (rising_edge(TXCLK)) then
				RXDbuf<= RXDbuf(3 downto 0) & fifoOUT;
				TXEN	<= TXVALID;
				if first_nibble and TXVALID='1' then
					TXD<= TDATA(7 downto 4);
					nTXD<= TDATA(3 downto 0);
					first_nibble<=false;
				elsif first_nibble=false then
					TXD<=nTXD;
					first_nibble<=true;
				end if;
		end if;
		
	end process;	
	
end Behavioral;