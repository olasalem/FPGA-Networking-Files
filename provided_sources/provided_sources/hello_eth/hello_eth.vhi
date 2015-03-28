
-- VHDL Instantiation Created from source file hello_eth.vhd -- 17:19:38 05/28/2013
--
-- Notes: 
-- 1) This instantiation template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the instantiated module
-- 2) To use this template to instantiate this entity, cut-and-paste and then edit

	COMPONENT hello_eth
	PORT(
		RST : IN std_logic;
		NUM : IN std_logic_vector(7 downto 0);
		COL : IN std_logic;
		CRS : IN std_logic;
		TXCLK : IN std_logic;
		RXD : IN std_logic_vector(3 downto 0);
		RXER : IN std_logic;
		RXDV : IN std_logic;
		RXCLK : IN std_logic;    
		MDIO : INOUT std_logic;      
		LED : OUT std_logic_vector(7 downto 0);
		MDC : OUT std_logic;
		RESETN : OUT std_logic;
		TXD : OUT std_logic_vector(3 downto 0);
		TXER : OUT std_logic;
		TXEN : OUT std_logic
		);
	END COMPONENT;

	Inst_hello_eth: hello_eth PORT MAP(
		RST => ,
		LED => ,
		NUM => ,
		MDIO => ,
		MDC => ,
		RESETN => ,
		COL => ,
		CRS => ,
		TXD => ,
		TXER => ,
		TXEN => ,
		TXCLK => ,
		RXD => ,
		RXER => ,
		RXDV => ,
		RXCLK => 
	);


