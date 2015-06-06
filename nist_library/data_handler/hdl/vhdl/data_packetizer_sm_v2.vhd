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

Entity data_packetizer_sm_v2 Is
	Port (
		rst						: in std_logic;
		ce						: in std_logic;
		clk						: in std_logic;
		--Control and Packet Signals
		data_output_en			: in std_logic;
		packet_type				: in std_logic_vector (7 downto 0);
		packet_version			: in std_logic_vector (7 downto 0);
		channel_count			: in std_logic_vector (15 downto 0);
		samples_per_channel		: in std_logic_vector (15 downto 0);
		flags					: in std_logic_vector (15 downto 0);
		--Frame information(typically d999 ~ d1000)
		frame_size				: in std_logic_vector(15 downto 0);
		frame_increment			: in std_logic_vector(15 downto 0);
		--Data in FIFO interface (assumed non-FWFT w/ Valid and Data Count out)
		data_in_valid			: in std_logic;
		data_in_grab_frame		: in std_logic;
		data_in					: in std_logic_vector (63 downto 0);
		data_in_rd_en			: out std_logic := '0';
		--10GbE Data Interface
		data_out				: out std_logic_vector (63 downto 0) := (Others => '0');
		data_out_valid			: out std_logic := '0';
		end_of_frame			: out std_logic := '0'
	);
End data_packetizer_sm_v2;


Architecture Behavioral Of data_packetizer_sm_v2 Is
	------------------------------------------------------------------------------
	-- Signal Definitions
	------------------------------------------------------------------------------

	Type sm1 Is (Idle, DataWait, Header1, Header2, Data);
	Signal State 			: sm1 := Idle;
	Signal frame_count		: unsigned(63 downto 0) := (Others => '0');
	Signal packet_count		: unsigned(15 downto 0) := (Others => '0');

	Begin
	------------------------------------------------------------------------------
	-- Overall governing sate machine
	------------------------------------------------------------------------------
	StateMachine : Process (rst, clk, State)
	Begin
		If (rst = '1') Then
			packet_count 				<= (Others => '0');
			data_in_rd_en				<= '0';
			data_out_valid 				<= '0';
			end_of_frame				<= '0';
			data_out 					<= (Others => '0');
			State						<= Idle;

		Elsif (Rising_Edge(clk)) Then
			Case State is

				When Idle =>
					data_in_rd_en		<= '0';
					data_out_valid 		<= '0';
					end_of_frame		<= '0';
					packet_count 		<= (Others => '0');
					data_out 			<= (Others => '0');
					frame_count		    <= (Others => '0');
					If (data_output_en = '1') Then
						State <= DataWait;
			        Else
			            State <= Idle;
					End If;

				When DataWait =>
					data_in_rd_en		<= '0';
					end_of_frame		<= '0';
					data_Out_valid 		<= '0';
					If (data_output_en = '0') Then
					    State           <= Idle;
					Elsif (data_in_grab_frame = '1') Then
						State           <= Header1;
					End IF;

				When Header1 =>
					packet_count		<= (Others => '0');
					frame_count			<= frame_count + unsigned(frame_increment);
					data_Out_Valid 		<= '1';
					data_Out			<= packet_type &
										   packet_version &
										   channel_count &
										   samples_per_channel &
										   flags;
					State 				<= Header2;

				When Header2 =>
					data_Out			<= std_logic_vector(frame_count);
					State 				<= Data;

				When Data =>

				    If(packet_count >= (unsigned(frame_size) - 4)) Then
				        data_in_rd_en <= '0';
				    Else
				       data_in_rd_en <= '1';
				    End If;

				    If(packet_count >= (unsigned(frame_size) - 1)) Then
				        State <= DataWait;
				        end_of_frame <= '1';
				    Else
				        State <= Data;
				    End If;

                    If(data_in_valid = '1') Then
                        data_Out_valid <= '1';
                        data_out <= data_in;
                        packet_count <= packet_count + 1;
					Else
						data_Out_valid <= '0';
                    End If;

				When Others =>
					State 				<= Idle;

			End Case;
		End If;
	End Process StateMachine;

End Architecture Behavioral;
