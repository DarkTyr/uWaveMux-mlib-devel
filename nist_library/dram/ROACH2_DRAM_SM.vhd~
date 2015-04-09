------------------------------------------------------------------------------
-- This module takes in 64 bits of data times 5 from the CASPER 10Gbe IP core and 
-- writes it to the DDR3 DRAM IP Interface. The purpose of this block is to
-- write a large look up table to the ram. the inputs to this SM are the size 
-- of the LUT and what port it is expecting the information on. 
--
-- DRAM interface is 288 bits wide which takes five reads from the 10Gbe core
-- to write all of the bits. 
------------------------------------------------------------------------------
-- Intended target: CASPER ROACH2 Virtex 6
-- Development tools: Altera Quartus, Altera Modelsim, Xilinx ISE, Simulink 
-- Author:  Johnathon Gard
-- Notes: 
-- Date:     03/02/2015
-- Revision: 1.0
------------------------------------------------------------------------------ 
-- ===========================================================================
-- DISCLAIMER: This code is FREEWARE which is provided on an “as is” basis, 
-- YOU MAY USE IT ON YOUR OWN RISK, WITHOUT ANY WARRANTY. 
-- ===========================================================================

Library IEEE;
Use IEEE.STD_LOGIC_1164.All;
Use IEEE.STD_LOGIC_ARITH.All;

Entity ROACH2_DRAM_SM Is
	Port (
		rst					: in std_logic;
		ce					: in std_logic;
		clk					: in std_logic;

		--Control signals
		arm					: in std_logic;
		size				: in std_logic_vector (31 downto 0);
		cmd_port			: in std_logic_vector (15 downto 0);
		sm_state			: out std_logic;

		--10GbE Interface
		eth_data_in			: in std_logic_vector (63 downto 0);
		eth_valid_in		: in std_logic;
		eth_port_in			: in std_logic_vector(15 downto 0);
		eth_ack_out			: out std_logic;

		--DRAM interface
		dram_data_out		: out std_logic_vector (287 downto 0);
		dram_address_out	: out std_logic_vector (31 downto 0);
		dram_read_nwrite_out: out std_logic;
		dram_cmd_valid_out	: out std_logic
	);
End ROACH2_DRAM_SM;


Architecture Behavioral Of ROACH2_DRAM_SM Is 
	Type sm2 Is (Latch_Idle, Latch_wait);
	Signal latch_sm 		: sm2;
	Signal latch_size		: std_logic_vector (31 downto 0);
	Signal latch_cmd_port	: std_logic_vector (15 downto 0);

    Type sm1 Is (Idle, EmptyFIFO, 
				EthRead1, Wait1, Grab1, 
				EthRead2, Wait2, Grab2, 
				EthRead3, Wait3, Grab3, 
				EthRead4, Wait4, Grab4,
				EthRead5, Wait5, Grab5,
				DramSetup,
				DramWrite1,
				DramWrite2, 
				IncAddr, 
				Reset);
	Signal State 			: sm1;
	Signal count			: unsigned (31 downto 0);
	
	Begin

	------------------------------------------------------------------------------
	-- Latching State Machine to hold variables constant
	------------------------------------------------------------------------------
	
	Latch_inputs_sm : Process (rst, clk, State, latch_sm)
	Begin 
		If (rst = '1') Then
			latch_sm		<= Latch_Idle;
			latch_size		<= x"0000_0000";
			latch_cmd_port 	<= x"0000";
		Elsif (Rising_Edge(clk)) Then
			Case latch_sm is
			
				When Latch_Idle =>
					latch_size			<= x"0000_0000";
					latch_cmd_port 		<= x"0000";
					If (arm = '1') Then
						latch_size		<= size;
						latch_cmd_port 	<= cmd_port;
						latch_sm		<= Latch_wait;
					End If;
					
				When Latch_wait =>
					If (State = Reset) Then
						If (arm = '0') Then
							latch_sm 	<= Latch_Idle;
						End If;
					End If;
			End Case;
		End If;							  
	End Process Latch_inputs_sm;
	
	
	------------------------------------------------------------------------------
	-- Overall governing sate machine
	------------------------------------------------------------------------------
	StateMachine : Process (rst, clk, State)
	Begin
		If (rst = '1') Then
			dram_data_out			<= (Others => '0');
			dram_address_out		<= (Others => '0');
			dram_read_nwrite_out	<= '0';
			dram_cmd_valid_out		<= '0';
			eth_ack_out				<= '0';
			dram_cmd_valid_out		<= '0';
			sm_state				<= '0';
			State 					<= Idle;
			count					<= (Others => '0');
		Elsif (Rising_Edge(clk)) Then
			Case State is
			
				When Idle =>
					dram_read_nwrite_out	<= '0';
					dram_cmd_valid_out		<= '0';
					dram_read_nwrite_out	<= '0';
					eth_ack_out				<= '0';
					dram_cmd_valid_out		<= '0';
					sm_state				<= '0';
					count					<= (Others => '0');
					dram_address_out		<= (Others => '0');
					If (arm = '1') Then
						State 				<= EmptyFIFO;
					End If;
				
				When EmptyFIFO =>
					sm_state				<= '1';
					count					<= (Others => '0');
					If(eth_valid_in = '1') Then
						eth_ack_out 		<= '1';
					Else
						eth_ack_out 		<= '0';
						State 				<= EthRead1;
					End If;

                When EthRead1 =>
					eth_ack_out 		<= '0';
                    If (eth_valid_in = '1') Then
						If (eth_port_in = latch_cmd_port) Then
		                    eth_ack_out     <= '1';
		                    State           <= Wait1;
						End If;
                    End If;

				When Wait1 =>
					eth_ack_out				<= '0';
					State 					<= Grab1;

				When Grab1 =>
					dram_data_out(287 downto 224)  <= eth_data_in;
					State               	<= EthRead2;

                When EthRead2 =>
					eth_ack_out 			<= '0';
                    If (eth_valid_in = '1') Then
						If (eth_port_in = latch_cmd_port) Then
		                    eth_ack_out     <= '1';
		                    State           <= Wait2;
						End If;
                    End If;

				When Wait2 =>
					eth_ack_out				<= '0';
					State 					<= Grab2;

				When Grab2 =>
					dram_data_out(223 downto 160)  <= eth_data_in;
					State               	<= EthRead3;

                When EthRead3 =>
					eth_ack_out 			<= '0';
                    If (eth_valid_in = '1') Then
						If (eth_port_in = latch_cmd_port) Then
		                    eth_ack_out     <= '1';
		                    State           <= Wait3;
						End If;
                    End If;

				When Wait3 =>
					eth_ack_out				<= '0';
					State 					<= Grab3;

				When Grab3 =>
					dram_data_out(159 downto 96)  <= eth_data_in;
					State               	<= EthRead4;

                When EthRead4 =>
					eth_ack_out 			<= '0';
                    If (eth_valid_in = '1') Then
						If (eth_port_in = latch_cmd_port) Then
		                    eth_ack_out     <= '1';
		                    State           <= Wait4;
						End If;
                    End If;

				When Wait4 =>
					eth_ack_out				<= '0';
					State 					<= Grab4;

				When Grab4 =>
					dram_data_out(95 downto 32)  <= eth_data_in;
					State               	<= EthRead5;

                When EthRead5 =>
					eth_ack_out 			<= '0';
                    If (eth_valid_in = '1') Then
						If (eth_port_in = latch_cmd_port) Then
		                    eth_ack_out     <= '1';
		                    State           <= Wait5;
						End If;
                    End If;

				When Wait5 =>
					eth_ack_out				<= '0';
					State 					<= Grab5;

				When Grab5 =>
					dram_data_out(31 downto 0)  <= eth_data_in(63 downto 32);
					State               	<= DramSetup;


				When DramSetup =>
					dram_read_nwrite_out 	<= '0';
                	dram_address_out 		<= std_logic_vector(count);
					State 					<= DramWrite1;

				When DramWrite1 =>
					dram_cmd_valid_out		<= '1';
					State					<= DramWrite2;
 
				When DramWrite2 =>
					State                   <= IncAddr;

                When IncAddr =>
                    dram_cmd_valid_out		<= '0';
					If (count < unsigned(latch_size)) Then
						count 				<= count + 1;
						State 				<= EthRead1;
					Else
						State 				<= Reset;
					End If;


                When Reset =>
					sm_state				<= '0';
					eth_ack_out				<= '0';
					dram_cmd_valid_out		<= '0';
					If (arm = '0') Then
						State 				<= Idle;
					End If;

				When Others =>
					State 					<= Idle;
					
			End Case;
		End If;
	End Process StateMachine;

End Architecture Behavioral;
