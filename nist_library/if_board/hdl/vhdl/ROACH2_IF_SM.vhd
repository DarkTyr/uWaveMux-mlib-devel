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

Entity ROACH2_IF_SM Is
	Port (
		rst					: in std_logic;
		ce					: in std_logic;
		clk					: in std_logic;
		Data_In				: in std_logic_vector (31 downto 0);
		start				: in std_logic;
		--Control input bit order(msb to lsb)
		--(SWAT_SLE, CK_SLE, LO_SLE, Strobe)
		control				: in std_logic_vector (3 downto 0);
		--output_port bit order(msb to lsb)
		--(SWAT_SLE, CK_SLE, LO_SLE, Ser_DI, Ser_CK, Strobe)
		output_port			: out std_logic_vector (5 downto 0) := (Others => '0')
	);
End ROACH2_IF_SM;


Architecture Behavioral Of ROACH2_IF_SM Is 
	Type sm1 Is (Idle, Load, Shift, Delay, Latch, SM_Reset);
	Signal State 			: sm1;
	Type sm2 Is (Latch_Idle, Latch_wait);
	Signal latch_sm 		: sm2;
	Signal Shiftreg		    : std_logic_vector (31 downto 0);
	Signal bit_count		: unsigned (6 downto 0); -- 32 bit counter (10_0000)
	Signal SPI_clk			: std_logic;
	Signal SPI_clk_count	: unsigned (7 downto 0);
	Signal we_Strobe		: std_logic;
	Signal we_LO_SLE		: std_logic;
	Signal we_CK_SLE		: std_logic;
	Signal we_SWAT_SLE	    : std_logic;
	Signal ser_clk			: std_logic;
	Signal ser_DI			: std_logic;
	Signal spi_ck_en		: std_logic;
	Signal start_latch	    : std_logic;
	Signal control_latch    : std_logic_vector (3 downto 0);
    Signal spi_ck_hold      : std_logic;
	
	
	Begin

	------------------------------------------------------------------------------
	-- SPI Clock generator
	------------------------------------------------------------------------------
	SPI_clk_Gen : process (rst, clk, SPI_clk_count)
	Begin
		If (rst = '1') Then
			SPI_clk 		<= '0';
			SPI_clk_count 	<= (Others => '0');
			ser_clk			<= '0';
		Elsif(Rising_Edge(clk)) Then
			SPI_clk_count 	<= SPI_clk_count + 1;
			SPI_clk 		<= std_logic(SPI_clk_count(7));
			ser_clk 		<= (SPI_clk and spi_ck_en) or spi_ck_hold;
		End If;
	End Process SPI_clk_gen;
	
	------------------------------------------------------------------------------
	-- Data Shifter
	------------------------------------------------------------------------------
	DataShifter : Process (rst, SPI_clk, Data_In, Shiftreg, State)
	Begin 
		If (rst = '1') Then
			Shiftreg <= (Others => '0');
			ser_DI 	<= '0';			
		Elsif (Rising_Edge(SPI_clk)) Then
			If (State = Load) Then -- Use for sim in ModelSim
				Shiftreg(31 downto 0) <= Data_In(31 downto 0);
			Elsif (State = Shift) Then
				Shiftreg(31 downto 0) <= Shiftreg(30 downto 0) & '0';
				ser_DI 	<= Shiftreg(31);
			Else
				ser_DI	<= '0';
			End If;
		End If;							  
	End Process DataShifter;
	
	------------------------------------------------------------------------------
	-- Start Latching State Machine
	------------------------------------------------------------------------------
	
	Latch_inputs_sm : Process (rst, clk, Start, State, control, latch_sm)
	Begin 
		If (rst = '1') Then
			start_latch 	<= '0';
			latch_sm		<= Latch_Idle;
			control_latch	<= "0000";
		Elsif (Rising_Edge(clk)) Then
			Case latch_sm is
			
				When Latch_Idle =>
					start_latch			<= '0';
					control_latch		<= "0000";
					If (Start = '1') Then
						start_latch 	<= '1';
						control_latch 	<= control;
						latch_sm		<= Latch_wait;
					End If;
					
				When Latch_wait =>
					If (State = SM_Reset) Then
						If (Start = '0') Then
							latch_sm 	<= Latch_Idle;
						End If;
					End If;
			End Case;
		End If;							  
	End Process Latch_inputs_sm;
	
	
	------------------------------------------------------------------------------
	-- Overall governing sate machine
	------------------------------------------------------------------------------
	StateMachine : Process (rst, SPI_clk, State, bit_count, control, start_latch)
	Begin
		If (rst = '1') Then
			we_Strobe		<= '0';
			we_LO_SLE		<= '1';
			we_CK_SLE		<= '1';
			we_SWAT_SLE		<= '1';
			spi_ck_en 		<= '0';
            spi_ck_hold     <= '0';
			State 			<= Idle;
			bit_count 		<= (Others => '0');
		Elsif (Rising_Edge(SPI_clk)) Then
			Case State is
			
				When Idle =>
					we_Strobe		<= '0';
					we_LO_SLE		<= '1';
					we_CK_SLE		<= '1';
					we_SWAT_SLE		<= '1';
					spi_ck_en 		<= '0';
                    spi_ck_hold     <= '0';
					bit_count 		<= (Others => '0');
					If (start_latch = '1') Then
						State 		<= Load;
					End If;
					
				When Load =>
					State 			<= Shift;
                    we_LO_SLE		<= not(control_latch(1));
					we_CK_SLE		<= not(control_latch(2));
					we_SWAT_SLE		<= not(control_latch(3));
					
				When Shift =>
					spi_ck_en 		<= '1';
					bit_count 		<= bit_count + 1;
					If (bit_count = 31) Then
						State 		<= Delay;
						
					End If;
	
                When Delay =>
                    spi_ck_en 		<= '0';
                    State <= Latch;
                    If (control_latch(3) = '1') Then
                        spi_ck_hold <= '1';
                    Else
                        spi_ck_hold <= '0';
                    End If;
					
				When Latch =>
					spi_ck_en 		<= '0';
					we_Strobe		<= control_latch(0);
					we_LO_SLE		<= not(control_latch(1));
					we_CK_SLE		<= not(control_latch(2));
					we_SWAT_SLE		<= not(control_latch(3));
					State 			<= SM_Reset;
								
				When SM_Reset =>
					we_Strobe		<= '0';
					we_LO_SLE		<= '1';
					we_CK_SLE		<= '1';
					we_SWAT_SLE		<= '1';
					If (start_latch = '0') Then
						State 		<= Idle;
					End If;
					
				When Others =>
					State 			<= Idle;
					
			End Case;
		End If;
	End Process StateMachine;
	
	------------------------------------------------------------------------------
	-- Register Outputs w/ clk and assemble the output vector
	------------------------------------------------------------------------------
	output_register : Process(rst, clk, we_SWAT_SLE, we_CK_SLE, we_LO_SLE, ser_DI, ser_clk, we_Strobe)
	Begin
		If (rst = '1') Then
			output_port 	<= (Others => '0');
		Elsif (Rising_Edge(clk)) Then
			output_port		<= we_SWAT_SLE & we_CK_SLE & we_LO_SLE & ser_DI & ser_clk & we_Strobe;
		End If;
	End Process output_register;
	
	
End Architecture Behavioral;
