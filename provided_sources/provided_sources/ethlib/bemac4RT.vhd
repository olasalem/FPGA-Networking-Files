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


---------------------------------------------------------------------------
--This package contains usefull definitions to handle Ethernet frames when 
--manipulating byte.
--TO BE COMPLETED (with other frames for example)
---------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

package BEMAC4RT is
	-- Function which reverts the sens of an std_logic_vector (from MSB to LSB)
	function bit_reverse (s: std_logic_vector) return std_logic_vector;
	-- Array type and subtype usefull to define static ethernet frame
	type byte_array is array (integer range <> ) of std_logic_vector(7 downto 0);
	
	-- Define frames of fixed size
	-- Frame of 60 bytes 
	subtype frame60 is byte_array(integer range 0 to 59);
	subtype frame48 is byte_array(integer range 0 to 47);
	
	type frame is record
		bytes: frame48;
		len: integer range 0 to 500;
	end record;
	
		constant zero_frame : frame :=((others=>x"00"),0);
	
	type frame_array is array (integer range <> ) of frame;
	
	-- Definition of usefull MAC_ADDR
	constant mac_broad: STD_LOGIC_VECTOR (47 downto 0):= x"FFFFFFFFFFFF";
	constant mac_remote: STD_LOGIC_VECTOR (47 downto 0) := x"001b21a73683";
	constant mac_local: STD_LOGIC_VECTOR (47 downto 0) := x"001b21a73688";
	constant mac_x: STD_LOGIC_VECTOR (47 downto 0)  := x"0010A47BEA80";
	constant mac_y: STD_LOGIC_VECTOR (47 downto 0) := x"001234567890";

---------------------------------------------------------------------------------
 -- Predefined Applicative frame 
---------------------------------------------------------------------------------
-- Arp request from 192.168.0.2 (00:00:00:00:00:00) to get the hardware address
-- of 192.168.0.1
constant arp_req0:frame48 :=
	  (x"08",x"06",x"00",x"01",
		x"08",x"00",x"06",x"04",
		x"00",x"01",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"C0",x"A8",x"00",x"02",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"C0",x"A8",
		x"00",x"01",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00");
-- Arp request from 192.168.0.2 (01:01:01:01:01:01) to get the hardware address
-- of 192.168.0.1
constant arp_req1:frame48 :=
	  (x"08",x"06",x"00",x"01",
		x"08",x"00",x"06",x"04",
		x"00",x"01",x"00",x"01",
		x"01",x"01",x"01",x"01",
		x"C0",x"A8",x"00",x"02",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"C0",x"A8",
		x"00",x"01",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00");
-- Arp request from 192.168.0.2 (10:10:10:10:10:10) to get the hardware address
-- of 192.168.0.1
 constant arp_req2:frame48 :=
	  (x"08",x"06",x"00",x"01",
		x"08",x"00",x"06",x"04",
		x"00",x"01",x"10",x"10",
		x"10",x"10",x"10",x"10",
		x"C0",x"A8",x"00",x"02",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"C0",x"A8",
		x"00",x"01",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00");
		
constant f1:frame:=(arp_req0,47);
constant f2:frame:=(arp_req0,47);
constant f3:frame:=(arp_req0,47);
constant frame_set:frame_array(0 to 2):=(f1,f2,f3);

 ---------------------------------------------------------------------------------
 -- Predefined ethernet frame 
 ---------------------------------------------------------------------------------
	-- Arp request from 192.168.0.2 (00:1B:21:A7:36:88) to get the hardware address
	-- of 192.168.0.1
	constant arp_request :frame60:=
	  (x"FF",x"FF",x"FF",x"FF",
		x"FF",x"FF",x"00",x"1B",
		x"21",x"A7",x"36",x"88",
		x"08",x"06",x"00",x"01",
		x"08",x"00",x"06",x"04",
		x"00",x"01",x"00",x"1B",
		x"21",x"A7",x"36",x"88",
		x"C0",x"A8",x"00",x"02",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"C0",x"A8",
		x"00",x"01",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00",
		x"00",x"00",x"00",x"00");	

	--Udp broadcast (255.255.255.255) packet to port 20698 from a imaginary source
	--MAC source=00:00:00:04:14:13, Ip source=0.0.0.0 port source=0

	--UDP payload AAAAA ... 
	constant udp_frameA :frame60:=
	  (x"FF",x"FF",x"FF",x"FF", -- mac dest
		x"FF",x"FF",x"00",x"00", 
		x"00",x"04",x"14",x"13", -- mac src
		x"08",x"00",x"45",x"00", -- IP header
		x"00",x"2E",x"00",x"00",
		x"00",x"00",x"40",x"11",
		x"7A",x"C0",x"00",x"00", -- IP src
		x"00",x"00",x"FF",x"FF", -- IP dest
		x"FF",x"FF",x"00",x"00", -- port src
		x"50",x"DA",x"00",x"12", -- port dest + len 
		x"00",x"00",x"41",x"41", -- checksum udp + data "A"
		x"41",x"41",x"41",x"41",
		x"41",x"41",x"41",x"41",
		x"41",x"41",x"41",x"41",
		x"41",x"41",x"41",x"41");	

	--UDP payload BBBB ... 
	constant udp_frameB :frame60:=
	  (x"FF",x"FF",x"FF",x"FF", -- mac dest
		x"FF",x"FF",x"00",x"00", 
		x"00",x"04",x"14",x"13", -- mac src
		x"08",x"00",x"45",x"00", -- IP header
		x"00",x"2E",x"00",x"00",
		x"00",x"00",x"40",x"11",
		x"7A",x"C0",x"00",x"00", -- IP src
		x"00",x"00",x"FF",x"FF", -- IP dest
		x"FF",x"FF",x"00",x"00", -- port src
		x"50",x"DA",x"00",x"12",-- port dest + len 
		x"00",x"00",x"42",x"42", -- checksum udp + data "B"
		x"42",x"42",x"42",x"42",
		x"42",x"42",x"42",x"42",
		x"42",x"42",x"42",x"42",
		x"42",x"42",x"42",x"42");
		
type disp_digit is record
		enable: std_logic;
		value: integer range 0 to 31;
		dot: std_logic;
end record;
type disp_digit_array is array(integer range 3 downto 0) of disp_digit;
		
		
----------------------------------------------------------------------------
end BEMAC4RT;
----------------------------------------------------------------------------


----------------------------------------------------------------------------
package body BEMAC4RT is
----------------------------------------------------------------------------
	function bit_reverse (s: std_logic_vector) return std_logic_vector is
		variable r: std_logic_vector(s'range);
	begin 
		for I in s'range loop
			r(I):=s(s'high-I);
		end loop;
		return r;
	end bit_reverse;
----------------------------------------------------------------------------
end BEMAC4RT;
----------------------------------------------------------------------------