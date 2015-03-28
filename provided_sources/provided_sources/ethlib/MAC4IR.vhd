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
--This is the snippet code of the entity that student should provide.
--IMPORTANT Modification from previous years:
--0)Interface with the real nexys3 ethernet PHY is provided to fit this entity
--1)Clock is 25Mhz --> student should divide clock by 2 and not by 8 when retrieving data
--2)Signal RXVALID and TXVALID have been added
--3)CRC core has been provided to compute FCS at reception and transmission
--4)Signal to manage collision have been added (carrier and collision)
--6)Hello_eth.vhd entity has been provided to explain the use of the new PHY interface
-- and the use of crc_core it sends udp packet in broadcast mode.
--7)Basic software has been provided to receive udp packet from the board on 
-- a real pc without root privileges.

----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mac4IR is
    Port ( 
			  -- General purpose ports
			  RSTN : in  STD_LOGIC;
			  CLK25 : in STD_LOGIC;
			  NOADDR: in STD_LOGIC_VECTOR(47 downto 0);
  			  --Toward Net Layer
			  --TX
			  TDATAI: in STD_LOGIC_VECTOR (7 downto 0);
			  TAVAILP: in STD_LOGIC;
			  TLASTP: in STD_LOGIC;
			  TFINISHP: in STD_LOGIC;
			  TABORTP: in STD_LOGIC;
			  TSTARTP: out STD_LOGIC;
			  TRNSMTP: out STD_LOGIC;
			  TREADDP: out STD_LOGIC;
			  TDONEP: out STD_LOGIC;
			  TSOCOLP: out STD_LOGIC;
			  --RX
			  RENABP: in STD_LOGIC;
			  RSTARTP: out STD_LOGIC;
			  RCVNGP: out STD_LOGIC;
			  RSMATIP: out STD_LOGIC;
			  RBYTEP: out STD_LOGIC;
			  RDONEP: out STD_LOGIC;
			  RCLEANP: out STD_LOGIC;
			  RDATAO: out STD_LOGIC_VECTOR (7 downto 0);		  
			  --Toward PHY layer
			  --TX
			  TDATAO: out STD_LOGIC_VECTOR (7 downto 0);
			  TXVALID: out STD_LOGIC;
			  --RX
			  RDATAI : in STD_LOGIC_VECTOR (7 downto 0);
			  RXVALID: in STD_LOGIC;
			  --Collision purpose
			  COLLISION: in STD_LOGIC;
			  CARRIER: in STD_LOGIC		  
			  );
end mac4IR;

architecture Behavioral of mac4IR is

	--Components
	component ethcrc32 is
	  port (	clk 		: in std_logic;
				rst		: in std_logic;
				en			: in std_logic;
				is_msb	: in std_logic;
				data_in 	: in std_logic_vector (7 downto 0);
				crc_out 	: out std_logic_vector (31 downto 0));
	end component;
	
	--INSERT OTHER DECLARATION HERE
	
begin

process is 
	begin
		wait until rising_edge(CLK25);
				TXVALID<='0';
end process;
end Behavioral;