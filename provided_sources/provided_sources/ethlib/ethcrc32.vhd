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
--This file defines an entity that compute a CRC for 802.3 procotol
--The computation is done by group of 8 bits.
--The reset is asynchronous.
--Computation are synchronous to clk and enabled when 'en' equals 1
--data_in is an 8bits input port for data to consider for a crc computation
--is_msb equals '1' indicates that data_in need to be reverted (msb to lsb) before computation.
------------------------------------------------------------------------------
--IMPORTANT :
--To be used in a real Ethernet case, user must take considerations 
--which are:
--1) The four first byte must be Ones' complemented
--2) data_in only considers some fields (ie not the preamble nor the SFD, see norm)
--3) data_in must be given in the same sens than transmission:
--		* LSB first for data
--		* MSB first for CRC in the case of reception
--		* ALL zero for CRC in the case of transmission
--4a) crc_out must be complemented before transmission
--4b) received crc must be complemented before given to data_in for
--    error checking in reception
--5) In the case of error checking in reception, if the received frame is correct
-- crc_out equals x"00000000"
------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity ethcrc32 is
	port (clk: in STD_LOGIC;					-- Input clock
         rst: in STD_LOGIC;					-- Asynchronous reset
         en : in STD_LOGIC;		   		-- Assert to compute calculations
         is_msb: in STD_LOGIC;				-- Assert to indicate the sens of data_in
		   data_in: in STD_LOGIC_VECTOR(7 downto 0);		-- Data to compute
         crc_out: out STD_LOGIC_VECTOR (31 downto 0)	-- CRC output
    );
end ethcrc32;
------------------------------------------------------------------------------
architecture nano of ethcrc32 is
-- The Generator polynomial is
--  32   26   23   22   16   12   11   10   8   7   5   4   2   
-- x  + x  + x  + x  + x  + x  + x  + x  + x + x + x + x + x + x + 1
constant GENERATOR : STD_LOGIC_VECTOR := X"04C11DB7";
begin
	process (clk,rst) is
		variable crc_buf : STD_LOGIC_VECTOR (31 downto 0):=x"00000000";
	begin
		if rst = '1' then	-- reset signals to values
			crc_buf := (others => '0');
		elsif rising_edge(clk) then  -- operate on positive edge
			if (en='1') then
				if is_msb='1' then
						for I in data_in'reverse_range loop
							crc_buf := (crc_buf(30 downto 0) & data_in(I)) XOR (GENERATOR AND (0 to 31=>crc_buf(31)));
						end loop;
				else
						for I in data_in'range loop
							crc_buf := (crc_buf(30 downto 0) & data_in(I)) XOR (GENERATOR AND (0 to 31=>crc_buf(31)));
						end loop;
				end if;
			end if;
		end if;
		crc_out<=crc_buf;
	end process;
end nano;
