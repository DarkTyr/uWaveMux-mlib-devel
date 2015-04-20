------------------------------------------------------------------------------
-- This module takes in 32 bits of data, and a 4 control signals (vectored for
--	memory integration) then serializes the data and pulses the control signals
-- accordingly as if writing to memory. In this case IF board components.
-- The comunication between this module and the outputs occurs at clk/256. This
-- has been done to meet timing on the IF board. The clock out is asserted on 
-- the falling edge of the generated clock amd the data is asserted on the rising
-- edge of the generated clock. Once the state machine is kicked off with the
-- start bit, it latches all of the data at the master clock frequency (clk).
-- This ensures that a pulsed start bit will be grabed and that the data will
-- not change inside of this module. 
------------------------------------------------------------------------------
-- Intended target: CASPER ROACH2 Virtex 6
-- Development tools: Notepad++, Altera Quartus, Altera Modelsim,
-- Author:  Johnathon Gard
-- Notes: 
-- Date:     01/20/2015
-- Revision: 1.0
------------------------------------------------------------------------------ 
-- ===========================================================================
-- DISCLAIMER: This code is FREEWARE which is provided on an “as is” basis, 
-- YOU MAY USE IT ON YOUR OWN RISK, WITHOUT ANY WARRANTY. 
-- ===========================================================================

Library IEEE;
Use IEEE.STD_LOGIC_1164.All;
Use IEEE.STD_LOGIC_ARITH.All;
--Use IEEE.STD_LOGIC_UNSIGNED.All;
--Use IEEE.Numeric_STD.ALL;

Entity data_packetizer Is
	Port (
		rst					: in std_logic;
		ce					: in std_logic;
		clk					: in std_logic;
		--Control and Packet Signals
		data_output_en		: in std_logic;
		packet_type			: in std_logic_vector (7 downto 0);
		packet_version		: in std_logic_vector (7 downto 0);
		channel_count		: in std_logic_vector (15 downto 0);
		samples_per_channel	: in std_logic_vector (15 downto 0);
		flags				: in std_logic_vector (15 downto 0);
		--Number of 64bit chunks of data in a frame (typically d999 ~ d1000)
		frame_size			: in std_logic_vector(15 downto 0);
		--Data in FIFO interface (assumed first word fall through FIFO)
		data_In_valid		: in std_logic;
		data_In_Empty		: in std_logic;
		data_In				: in std_logic_vector (63 downto 0);
		data_In_Rd_En		: out std_logic;
		--10GbE Data Interface
		data_Out			: out std_logic_vector (63 downto 0);
		data_Out_Valid		: out std_logic;
		end_of_Frame		: out std_logic
	);
End data_packetizer;


Architecture Behavioral Of data_packetizer Is 
	------------------------------------------------------------------------------
	-- Signal Definitions
	------------------------------------------------------------------------------

	Type sm1 Is (Idle, Header1, Header2, DataWait, Data);
	Signal State 			: sm1;
	Signal frame_count		: unsigned(63 downto 0);
	Signal packet_count		: unsigned(15 downto 0);

	Begin

	------------------------------------------------------------------------------
	-- Overall governing sate machine
	------------------------------------------------------------------------------
	StateMachine : Process (rst, clk, State)
	Begin
		If (rst = '1') Then
			packet_count 				<= (Others => '0');
			frame_count 				<= (Others => '0');

		Elsif (Rising_Edge(clk)) Then
			Case State is
			
				When Idle =>
					packet_count 		<= (Others => '0');
					If (data_output_en = '1') Then
						State <= Header1;
					End If;						
					
				When Header1 =>
					frame_count			<= frame_count + 1;
					data_Out_Valid 		<= '1';
					data_Out			<= packet_type & 
										   packet_version & 
										   channel_count & 
										   samples_per_channel & 
										   flags;
					State 				<= Header2;

				When Header2 =>
					data_Out_Valid 		<= '1';
					data_Out			<= std_logic_vector(frame_count);
					State 				<= Data;

				When DataWait =>
					If (data_In_valid = '1') Then
						data_In_Rd_En	<= '1';
						State			<= Data;
					End If;

                When Data =>
					
					If (packet_count >= unsigned(frame_size)) Then
						data_Out_Valid 	<= '0';
						end_of_Frame 	<= '1';
						packet_count	<= (Others => '0');
						If (data_output_en = '1') Then
							State 		<= Header1;
						Elsif (data_In_valid = '0') Then
							State		<= DataWait;
						Else
							State		<= Idle;
						End If;
					Else
						If (data_In_valid = '1') Then
							data_out		<= data_In;
							data_out_valid	<= '1';
							data_In_Rd_En	<= '1';
							packet_count	<= packet_count + 1;
						Else
							data_Out_Valid 	<= '0';
						End If;
					End If;


				When Others =>
					State 				<= Idle;
					
			End Case;
		End If;
	End Process StateMachine;
	
	
End Architecture Behavioral;
