
-- VHDL Instantiation Created from source file mac4IR.vhd -- 10:09:47 05/29/2013
--
-- Notes: 
-- 1) This instantiation template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the instantiated module
-- 2) To use this template to instantiate this entity, cut-and-paste and then edit

	COMPONENT mac4IR
	PORT(
		RSTN : IN std_logic;
		CLK25 : IN std_logic;
		NOADDR : IN std_logic_vector(47 downto 0);
		TDATAI : IN std_logic_vector(7 downto 0);
		TAVAILP : IN std_logic;
		TLASTP : IN std_logic;
		TFINISHP : IN std_logic;
		TABORTP : IN std_logic;
		RENABP : IN std_logic;
		RDATAI : IN std_logic_vector(7 downto 0);
		RXVALID : IN std_logic;
		COLLISION : IN std_logic;
		CARRIER : IN std_logic;          
		TSTARTP : OUT std_logic;
		TRNSMTP : OUT std_logic;
		TREADP : OUT std_logic;
		TDONEP : OUT std_logic;
		TSOCOLP : OUT std_logic;
		RSTARTP : OUT std_logic;
		RCVNGP : OUT std_logic;
		RSMATIP : OUT std_logic;
		RBYTEP : OUT std_logic;
		RDONEP : OUT std_logic;
		RCLEANP : OUT std_logic;
		RDATAO : OUT std_logic_vector(7 downto 0);
		TDATAO : OUT std_logic_vector(7 downto 0);
		TXVALID : OUT std_logic
		);
	END COMPONENT;

	Inst_mac4IR: mac4IR PORT MAP(
		RSTN => ,
		CLK25 => ,
		NOADDR => ,
		TDATAI => ,
		TAVAILP => ,
		TLASTP => ,
		TFINISHP => ,
		TABORTP => ,
		TSTARTP => ,
		TRNSMTP => ,
		TREADP => ,
		TDONEP => ,
		TSOCOLP => ,
		RENABP => ,
		RSTARTP => ,
		RCVNGP => ,
		RSMATIP => ,
		RBYTEP => ,
		RDONEP => ,
		RCLEANP => ,
		RDATAO => ,
		TDATAO => ,
		TXVALID => ,
		RDATAI => ,
		RXVALID => ,
		COLLISION => ,
		CARRIER => 
	);


