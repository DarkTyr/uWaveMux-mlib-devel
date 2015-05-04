--------------------------------------------------------------------------------
--    This file is owned and controlled by Xilinx and must be used solely     --
--    for design, simulation, implementation and creation of design files     --
--    limited to Xilinx devices or technologies. Use with non-Xilinx          --
--    devices or technologies is expressly prohibited and immediately         --
--    terminates your license.                                                --
--                                                                            --
--    XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" SOLELY    --
--    FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY    --
--    PROVIDING THIS DESIGN, CODE, OR INFORMATION AS ONE POSSIBLE             --
--    IMPLEMENTATION OF THIS FEATURE, APPLICATION OR STANDARD, XILINX IS      --
--    MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION IS FREE FROM ANY      --
--    CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE FOR OBTAINING ANY       --
--    RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY       --
--    DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE   --
--    IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR          --
--    REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF         --
--    INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A   --
--    PARTICULAR PURPOSE.                                                     --
--                                                                            --
--    Xilinx products are not intended for use in life support appliances,    --
--    devices, or systems.  Use in such applications are expressly            --
--    prohibited.                                                             --
--                                                                            --
--    (c) Copyright 1995-2015 Xilinx, Inc.                                    --
--    All rights reserved.                                                    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- You must compile the wrapper file fifo_64bitIn_64bitOut.vhd when simulating
-- the core, fifo_64bitIn_64bitOut. When compiling the wrapper file, be sure to
-- reference the XilinxCoreLib VHDL simulation library. For detailed
-- instructions, please refer to the "CORE Generator Help".

-- The synthesis directives "translate_off/translate_on" specified
-- below are supported by Xilinx, Mentor Graphics and Synplicity
-- synthesis tools. Ensure they are correct for your synthesis tool(s).

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY fifo_64bitIn_64bitOut_wrapper IS
  PORT (
    clk 	: IN STD_LOGIC;
	ce		: IN STD_LOGIC;
    rst 	: IN STD_LOGIC;
    din 	: IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    wr_en 	: IN STD_LOGIC;
    rd_en 	: IN STD_LOGIC;
    dout 	: OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    full 	: OUT STD_LOGIC;
    empty 	: OUT STD_LOGIC;
    valid 	: OUT STD_LOGIC
  );
END fifo_64bitIn_64bitOut_wrapper;

ARCHITECTURE fifo_64bitIn_64bitOut_wrapper_a OF fifo_64bitIn_64bitOut_wrapper IS

COMPONENT fifo_64to64_2k
  PORT (
    rst 	: IN STD_LOGIC;
    wr_clk 	: IN STD_LOGIC;
    rd_clk 	: IN STD_LOGIC;
    din 	: IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    wr_en 	: IN STD_LOGIC;
    rd_en 	: IN STD_LOGIC;
    dout 	: OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    full 	: OUT STD_LOGIC;
    empty 	: OUT STD_LOGIC;
    valid 	: OUT STD_LOGIC
  );
END COMPONENT;

BEGIN

U0 : fifo_64to64_2k
  PORT MAP (
    rst 	=> rst,
    wr_clk 	=> clk,
    rd_clk 	=> clk,
    din 	=> din,
    wr_en 	=> wr_en,
    rd_en 	=> rd_en,
    dout 	=> dout,
    full 	=> full,
    empty 	=> empty,
    valid 	=> valid
  );

END fifo_64bitIn_64bitOut_wrapper_a;
