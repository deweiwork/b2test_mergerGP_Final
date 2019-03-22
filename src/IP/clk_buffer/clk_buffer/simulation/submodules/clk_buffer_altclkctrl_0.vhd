--altclkctrl CBX_SINGLE_OUTPUT_FILE="ON" CLOCK_TYPE="AUTO" DEVICE_FAMILY="Arria II GX" USE_GLITCH_FREE_SWITCH_OVER_IMPLEMENTATION="OFF" ena inclk outclk
--VERSION_BEGIN 18.0 cbx_altclkbuf 2018:04:18:06:50:44:SJ cbx_cycloneii 2018:04:18:06:50:44:SJ cbx_lpm_add_sub 2018:04:18:06:50:44:SJ cbx_lpm_compare 2018:04:18:06:50:44:SJ cbx_lpm_decode 2018:04:18:06:50:44:SJ cbx_lpm_mux 2018:04:18:06:50:44:SJ cbx_mgl 2018:04:18:07:37:08:SJ cbx_nadder 2018:04:18:06:50:44:SJ cbx_stratix 2018:04:18:06:50:44:SJ cbx_stratixii 2018:04:18:06:50:44:SJ cbx_stratixiii 2018:04:18:06:50:44:SJ cbx_stratixv 2018:04:18:06:50:44:SJ  VERSION_END


-- Copyright (C) 2018  Intel Corporation. All rights reserved.
--  Your use of Intel Corporation's design tools, logic functions 
--  and other software and tools, and its AMPP partner logic 
--  functions, and any output files from any of the foregoing 
--  (including device programming or simulation files), and any 
--  associated documentation or information are expressly subject 
--  to the terms and conditions of the Intel Program License 
--  Subscription Agreement, the Intel Quartus Prime License Agreement,
--  the Intel FPGA IP License Agreement, or other applicable license
--  agreement, including, without limitation, that your use is for
--  the sole purpose of programming logic devices manufactured by
--  Intel and sold by Intel or its authorized distributors.  Please
--  refer to the applicable agreement for further details.



 LIBRARY arriaii;
 USE arriaii.all;

--synthesis_resources = clkctrl 1 
 LIBRARY ieee;
 USE ieee.std_logic_1164.all;

 ENTITY  clk_buffer_altclkctrl_0_sub IS 
	 PORT 
	 ( 
		 ena	:	IN  STD_LOGIC := '1';
		 inclk	:	IN  STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
		 outclk	:	OUT  STD_LOGIC
	 ); 
 END clk_buffer_altclkctrl_0_sub;

 ARCHITECTURE RTL OF clk_buffer_altclkctrl_0_sub IS

	 ATTRIBUTE synthesis_clearbox : natural;
	 ATTRIBUTE synthesis_clearbox OF RTL : ARCHITECTURE IS 1;
	 SIGNAL  wire_sd1_outclk	:	STD_LOGIC;
	 SIGNAL  clkselect	:	STD_LOGIC_VECTOR (1 DOWNTO 0);
	 COMPONENT  arriaii_clkena
	 GENERIC 
	 (
		clock_type	:	STRING;
		ena_register_mode	:	STRING := "falling edge";
		lpm_type	:	STRING := "arriaii_clkena"
	 );
	 PORT
	 ( 
		ena	:	IN STD_LOGIC;
		enaout	:	OUT STD_LOGIC;
		inclk	:	IN STD_LOGIC;
		outclk	:	OUT STD_LOGIC
	 ); 
	 END COMPONENT;
 BEGIN

	clkselect <= (OTHERS => '0');
	outclk <= wire_sd1_outclk;
	sd1 :  arriaii_clkena
	  GENERIC MAP (
		clock_type => "AUTO",
		ena_register_mode => "falling edge"
	  )
	  PORT MAP ( 
		ena => ena,
		inclk => inclk(0),
		outclk => wire_sd1_outclk
	  );

 END RTL; --clk_buffer_altclkctrl_0_sub
--VALID FILE -- (C) 2001-2018 Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions and other 
-- software and tools, and its AMPP partner logic functions, and any output 
-- files from any of the foregoing (including device programming or simulation 
-- files), and any associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License Subscription 
-- Agreement, Intel FPGA IP License Agreement, or other applicable 
-- license agreement, including, without limitation, that your use is for the 
-- sole purpose of programming logic devices manufactured by Intel and sold by 
-- Intel or its authorized distributors.  Please refer to the applicable 
-- agreement for further details.




LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY clk_buffer_altclkctrl_0 IS
    PORT
    (
        inclk       : IN STD_LOGIC;
        outclk       : OUT STD_LOGIC
    );
END clk_buffer_altclkctrl_0;


ARCHITECTURE RTL OF clk_buffer_altclkctrl_0 IS

    SIGNAL sub_wire0    : STD_LOGIC ;
    SIGNAL sub_wire1    : STD_LOGIC ;
    SIGNAL sub_wire2    : STD_LOGIC ;
    SIGNAL sub_wire3    : STD_LOGIC_VECTOR  (3 DOWNTO 0);
    SIGNAL sub_wire4_bv : BIT_VECTOR (2 DOWNTO 0);
    SIGNAL sub_wire4    : STD_LOGIC_VECTOR  (2 DOWNTO 0);


    COMPONENT  clk_buffer_altclkctrl_0_sub
    PORT (
            ena : IN STD_LOGIC;
            inclk   : IN STD_LOGIC_VECTOR  (3 DOWNTO 0);
            outclk  : OUT STD_LOGIC
    );
    END COMPONENT;


BEGIN
    outclk     <= sub_wire0;
    sub_wire1     <= '1';
    sub_wire2     <= inclk;
    sub_wire3     <= sub_wire4 &  sub_wire2;
    sub_wire4_bv(2 DOWNTO 0)  <= "000";
    sub_wire4   <= To_stdlogicvector(sub_wire4_bv);

    clk_buffer_altclkctrl_0_sub_component : clk_buffer_altclkctrl_0_sub
    PORT MAP (
        ena => sub_wire1,
        inclk => sub_wire3,
        outclk => sub_wire0
    );



END RTL;