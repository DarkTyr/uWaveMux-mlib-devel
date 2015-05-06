# uWaveMux-mlib-devel
Quantum Sensors Project - Microwave Mux ROACH2 Firmware

This repository is intended to hold the firmware portion
of the ROACH2 efforts. This mlib-devel was based on the 
CASPER consortium mlib-devel-master from January 2015.

List of fixes:
Yellow Block
	-MKID ADC and DAC x2 blocks for external clocking
	
List of added code:
	nist_library
	- MUSIC IF_Board control State Machine
	- 10GbE to DRAM State Machine
	- Data Packetizer State Machine
	- First In First Out Xilinx 2k entry deep
		+ 32 bit to 64 bit by 2k deep on the 64 bit side
		+ 64 bit to 64 bit by 2k deep

Example Model Files for State Machines:
	These example model files should be copied to a higher 
	directory outside of the mlib-devel.When you copy the 
	.mdl files, you should also copy the .m files for the 
	black box vhdl code. The .m files are setup so that 
	the .mdl file is in its own directory at the same level
	as the mlib-devel. For example:
		-uWaveMux-mlib-devel
			+startsg.local
			+{other files}
		-ProjectDirectory
			+example_**.mdl

List of Example Model Files
	nist_library
	- None yet :(

