------------------------------------------------------------------------------
--
--
--
--
--
------------------------------------------------------------------------------
-- Intended target: CASPER ROACH2 Virtex 6
-- Development tools: Xilinx ISE/Vivado, text editor
-- Author:  Johnathon Gard
-- Notes:
-- Date:     01/20/2015
-- Revision: 1.0
------------------------------------------------------------------------------
-- ===========================================================================
-- DISCLAIMER: This code is FREEWARE which is provided on an ??as is? basis,
-- YOU MAY USE IT ON YOUR OWN RISK, WITHOUT ANY WARRANTY.
-- ===========================================================================

Library IEEE;
Use IEEE.STD_LOGIC_1164.All;
Use IEEE.STD_LOGIC_ARITH.All;
--Use IEEE.STD_LOGIC_UNSIGNED.All;
--Use IEEE.Numeric_STD.ALL;

Entity acc_sm Is
	Port (
		rst						: in std_logic;
		ce						: in std_logic;
		clk						: in std_logic;
		--Control inputs Signals
		blanking_start			: in std_logic_vector (15 downto 0);
		blanking_stop			: in std_logic_vector (15 downto 0);
		channel_count			: in std_logic_vector (7 downto 0);
		--Data in interface
		valid_in				: in std_logic;
		sync_pulse_in			: in std_logic;
		chan_in					: in std_logic_vector (7 downto 0);
		--Data out interface
		data_out_valid			: out std_logic := '0';
		acc_valid				: out std_logic := '0';
		add_reset				: out std_logic := '0';
		chan_out				: out std_logic_vector (7 downto 0) := (Others => '0')
	);
End acc_sm;


Architecture Behavioral Of acc_sm Is
	------------------------------------------------------------------------------
	-- Signal Definitions
	------------------------------------------------------------------------------

	Type sm1 Is (Idle, Accumulate, pause0, pause1, Send_ACC_Data, Blank_ACC, Blanking_Wait);
	Signal State 			: sm1 := Idle;
	Signal start_count		: unsigned(15 downto 0) := (Others => '0');
	Signal stop_count		: unsigned(15 downto 0) := (Others => '0');
	Signal chan_count		: unsigned(07 downto 0) := (Others => '0');

	Begin
	------------------------------------------------------------------------------
	-- Overall governing sate machine
	------------------------------------------------------------------------------
	StateMachine : Process (rst, clk, State)
	Begin
		If (rst = '1') Then
			start_count 				<= (Others => '0');
			stop_count					<= (Others => '0');
			chan_count					<= (Others => '0');
			chan_out					<= (Others => '0');
			data_out_valid				<= '0';
			acc_valid					<= '0';
			add_reset					<= '0';
			State						<= Idle;

		Elsif (Rising_Edge(clk)) Then
			Case State is

				When Idle =>
					start_count 				<= (Others => '0');
					stop_count					<= (Others => '0');
					chan_count					<= (Others => '0');
					chan_out					<= (Others => '0');
					data_out_valid				<= '0';
					add_reset					<= '0';
					acc_valid					<= '0';
					If (sync_pulse_in = '1') Then
						State <= Send_ACC_Data;
			        Else
			            State <= Idle;
					End If;

				When Send_ACC_Data =>
					chan_count					<= chan_count + 1;
					stop_count					<= stop_count + 1;
					start_count					<= start_count + 1;
					chan_out					<= std_logic_vector(chan_count);
					data_out_valid				<= '1';
					add_reset					<= '1';
					If (chan_count >= unsigned(channel_count) - 1) Then
					    State           		<= Pause0;
					Else
						State					<= Send_ACC_Data;
					End IF;

				When Pause0 =>
					stop_count					<= stop_count + 1;
					start_count					<= start_count + 1;
					chan_out					<= (Others => '0');
					chan_count					<= (Others => '0');
					data_out_valid				<= '0';
					State           			<= Blank_ACC;

				When Blank_ACC =>
					stop_count					<= stop_count + 1;
					start_count					<= start_count + 1;
					chan_count					<= chan_count + 1;
					chan_out					<= std_logic_vector(chan_count);
					data_out_valid				<= '0';
					acc_valid					<= '1';

					If (chan_count >= unsigned(channel_count) - 1) Then
					    State           		<= Blanking_Wait;
					Else
						State					<= Blank_ACC;
					End IF;

				When Blanking_Wait =>
					stop_count					<= stop_count + 1;
					start_count					<= start_count + 1;
					chan_count					<= (Others => '0');
					chan_out					<= (Others => '0');
					add_reset					<= '0';
					acc_valid					<= '0';
					If (stop_count >= unsigned(blanking_stop) - 1) Then
						If(unsigned(chan_in) >= unsigned(channel_count) - 1) Then
					    	State           	<= Accumulate;
						Else
							State				<= Blanking_Wait;
						End If;
					End IF;

				When Accumulate =>
					start_count 				<= start_count + 1;
					chan_out					<= chan_in;
					data_out_valid				<= '0';
					add_reset					<= '0';
					acc_valid					<= valid_in;
					If (start_count >= unsigned(blanking_start) - 1) Then
						If(unsigned(chan_in) >= unsigned(channel_count) - 1) Then
					    	State           	<= Idle;
						Else
							State				<= Accumulate;
						End If;
					End IF;

				When Others =>
					State 				<= Idle;

			End Case;
		End If;
	End Process StateMachine;

End Architecture Behavioral;
