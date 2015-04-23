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
		clk_1				: in std_logic;

		data_out_en			: in std_logic;
		--Data in FIFO interface (assumed first word fall through FIFO)
		data_In_valid		: in std_logic;
		data_In				: in std_logic_vector (63 downto 0);
		--10GbE Data Interface
		data_Out			: out std_logic_vector (63 downto 0);
		data_Out_Valid		: out std_logic;
		end_of_Frame		: out std_logic
	);
End data_packetizer;


Architecture Behavioral Of data_packetizer Is 


	------------------------------------------------------------------------------
	-- Component Declarations
	------------------------------------------------------------------------------
	Component data_packetizer_sm Is
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
	End Component;
	
	-- Component fifo_generator_0 Is
		-- Port (
			-- wr_clk 		: IN STD_LOGIC;
			-- rd_clk 		: IN STD_LOGIC;
			-- din 		: IN STD_LOGIC_VECTOR(63 DOWNTO 0);
			-- wr_en 		: IN STD_LOGIC;
			-- rd_en 		: IN STD_LOGIC;
			-- dout 		: OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
			-- full 		: OUT STD_LOGIC;
			-- empty 		: OUT STD_LOGIC;
			-- valid 		: OUT STD_LOGIC
		-- );
	-- END Component;
	
	Component fifo_generator_0 IS
	PORT
		(
			data		: IN STD_LOGIC_VECTOR (63 DOWNTO 0);
			rdclk		: IN STD_LOGIC ;
			rdreq		: IN STD_LOGIC ;
			wrclk		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (63 DOWNTO 0);
			rdempty		: OUT STD_LOGIC ;
			wrfull		: OUT STD_LOGIC 
		);
	End Component fifo_generator_0;

	------------------------------------------------------------------------------
	-- Signal Definitions
	------------------------------------------------------------------------------	
	Signal fifo_sm_data		: std_logic_vector(63 downto 0);
	Signal fifo_sm_Empty	: std_logic;
	Signal fifo_sm_rdEn		: std_logic;
	Signal fifo_sm_full		: std_logic;
	Signal fifo_sm_valid	: std_logic;

	Begin
	
	------------------------------------------------------------------------------
	-- Component Instantiations 
	------------------------------------------------------------------------------
	packet_sm : data_packetizer_sm
	Port Map(
		rst					=> rst,
		ce					=> ce,
		clk					=> clk,
		data_output_en		=> data_out_en,
		packet_type			=> x"01",
		packet_version		=> x"02",
		channel_count		=> x"0304",
		samples_per_channel	=> x"0506",
		flags				=> x"0708",
		
		frame_size			=> x"00FF",
		
		data_In_valid		=> fifo_sm_valid,
		data_In_Empty		=> fifo_sm_Empty,
		data_In				=> fifo_sm_data,
		data_In_Rd_En		=> fifo_sm_rdEn,
		--10GbE Data Interface
		data_Out			=> data_Out,
		data_Out_Valid		=> data_Out_Valid,
		end_of_Frame		=> end_of_Frame);
		
	-- Data_in_FIFO : fifo_generator_0
	-- Port Map(
		-- wr_clk				=> clk_1,
		-- rd_clk				=> clk,
		-- wr_en 				=> data_In_valid,
		-- rd_en 				=> fifo_sm_rdEn,
		-- din					=> data_In,
		-- dout 				=> fifo_sm_data,
		-- full 				=> fifo_sm_full,
		-- empty 				=> fifo_sm_Empty,
		-- valid 				=> fifo_sm_valid);
		
	Data_in_FIFO : fifo_generator_0
	Port Map(
		wrclk				=> clk_1,
		rdclk				=> clk,
		wrreq 				=> data_In_valid,
		rdreq 				=> fifo_sm_rdEn,
		data				=> data_In,
		q 					=> fifo_sm_data,
		rdempty 			=> fifo_sm_Empty,
		wrfull 				=> fifo_sm_full);
		
		
	fifo_sm_valid <= not(fifo_sm_Empty);
	
End Architecture Behavioral;
