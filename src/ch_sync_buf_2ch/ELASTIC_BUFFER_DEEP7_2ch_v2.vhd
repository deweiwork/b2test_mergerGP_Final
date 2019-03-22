library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ELASTIC_BUFFER_DEEP7_2ch_v2 is
    port (
				MGT_initover	  : in std_logic;
				LANE_UP : in std_logic;
				EN_CHAN_SYNC : in std_logic;
				CH_BOND_DONE : out std_logic_vector(1 downto 0);
				GOT_A	: in std_logic_vector(3 downto 0);
				GOT_V	: in std_logic_vector(1 downto 0);
				LANE0_DATA	: in std_logic_vector(24 downto 0);
				LANE1_DATA	: in std_logic_vector(24 downto 0);
				CLK 	: in std_logic;
				CLK_OUT : out std_logic;
				RESET : in std_logic;
				LANE0_Q		: out std_logic_vector(24 downto 0);
				LANE1_Q		: out std_logic_vector(24 downto 0)
         );	
end ELASTIC_BUFFER_DEEP7_2ch_v2;

architecture MAIN of ELASTIC_BUFFER_DEEP7_2ch_v2 is

	constant DLY : time := 0 ns;
	
	component elastic_mux
	PORT
	(
		clock			: IN STD_LOGIC ;
		data0x		: IN STD_LOGIC_VECTOR (24 DOWNTO 0);
		data1x		: IN STD_LOGIC_VECTOR (24 DOWNTO 0);
		data2x		: IN STD_LOGIC_VECTOR (24 DOWNTO 0);
		data3x		: IN STD_LOGIC_VECTOR (24 DOWNTO 0);
		data4x		: IN STD_LOGIC_VECTOR (24 DOWNTO 0);
		data5x		: IN STD_LOGIC_VECTOR (24 DOWNTO 0);
		data6x		: IN STD_LOGIC_VECTOR (24 DOWNTO 0);
		sel		: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (24 DOWNTO 0)
	);
	END component;

	--store space
	type memory_space is record
		data : std_logic_vector(24 downto 0);
	end record;
	type rx_fifo_space is array(6 downto 0) of memory_space;
	type pipeline is array(1 downto 0) of memory_space;
	signal rx_elastic_buf_lane0 : rx_fifo_space;
	signal rx_elastic_buf_lane1 : rx_fifo_space;
	signal elastic_input_pipeline_0 : pipeline;
	signal elastic_input_pipeline_1 : pipeline;
	signal pipeline_align_0 : std_logic;
	signal pipeline_align_1 : std_logic;
	signal pipeline_output_0 : std_logic_vector(24 downto 0);
	signal pipeline_output_1 : std_logic_vector(24 downto 0);
	
	signal lane0_left_align_ex_high : std_logic;
	signal lane1_left_align_ex_high : std_logic;
	
	signal elastic_buf_out_sp_lane0 : integer range 0 to 6 :=6;
	signal elastic_buf_out_sp_lane1 : integer range 0 to 6 :=6;
	signal elastic_buf_out_sp_lane0_trans : std_logic_vector(2 downto 0) := "110";
	signal elastic_buf_out_sp_lane1_trans : std_logic_vector(2 downto 0) := "110";
	
begin

	CLK_OUT <= CLK after DLY;
	
--20120205 Alan command
--Altera transceiver can't do word align position control
--so we have to detect "BC" is in low byte position
	--pipeline input data detect
	process(CLK)
	begin
		if CLK='1' and CLK'event then
			if MGT_initover='1' then
				case LANE_UP is
					when '0' =>
						case LANE0_DATA(15 downto 0) is
							when x"4ABC" =>
								pipeline_align_0 <='0' after DLY;
							when x"BC4A" =>
								pipeline_align_0 <='1' after DLY;
							when others=>
						end case;
						case LANE1_DATA(15 downto 0) is
							when x"4ABC" =>
								pipeline_align_1 <='0' after DLY;
							when x"BC4A" =>
								pipeline_align_1 <='1' after DLY;
							when others=>
						end case;
					when others =>
				end case;
			else
			end if;
		end if;
	end process;
	
	--pipeline
	process(CLK)
	begin
		if CLK='1' and CLK'event then
			elastic_input_pipeline_0(0).data <= LANE0_DATA  after DLY;
			elastic_input_pipeline_1(0).data <= LANE1_DATA  after DLY;
			elastic_input_pipeline_0(1) <= elastic_input_pipeline_0(0) after DLY;
			elastic_input_pipeline_1(1) <= elastic_input_pipeline_1(0) after DLY;
		end if;
	end process;

--20120205 Alan command
--according "BC" detect result to change the output data, make "BC" at low byte
	--pipeline output 0
	process(CLK)
	begin
		if CLK='1' and CLK'event then
			case pipeline_align_0 is
				when '0' =>
					pipeline_output_0 <= elastic_input_pipeline_0(1).data after DLY;
				when '1' =>
					pipeline_output_0 <= elastic_input_pipeline_0(1).data(24) &
												elastic_input_pipeline_0(1).data(23) & elastic_input_pipeline_0(0).data(22)&
												elastic_input_pipeline_0(1).data(21) & elastic_input_pipeline_0(0).data(20)&
												elastic_input_pipeline_0(1).data(19) & elastic_input_pipeline_0(0).data(18)&
												elastic_input_pipeline_0(1).data(17) & elastic_input_pipeline_0(0).data(16)&
												elastic_input_pipeline_0(1).data(15 downto 8) & elastic_input_pipeline_0(0).data(7 downto 0) after DLY;
				when others =>
			end case;
		end if;
	end process;
	--pipeline output 1
	process(CLK)
	begin
		if CLK='1' and CLK'event then
			case pipeline_align_1 is
				when '0' =>
					pipeline_output_1 <= elastic_input_pipeline_1(1).data after DLY;
				when '1' =>
					pipeline_output_1 <= elastic_input_pipeline_1(1).data(24) &
												elastic_input_pipeline_1(1).data(23) & elastic_input_pipeline_1(0).data(22)&
												elastic_input_pipeline_1(1).data(21) & elastic_input_pipeline_1(0).data(20)&
												elastic_input_pipeline_1(1).data(19) & elastic_input_pipeline_1(0).data(18)&
												elastic_input_pipeline_1(1).data(17) & elastic_input_pipeline_1(0).data(16)&
												elastic_input_pipeline_1(1).data(15 downto 8) & elastic_input_pipeline_1(0).data(7 downto 0) after DLY;
				when others =>
			end case;
		end if;
	end process;
	
	
--20120205 Alan command
--this process is used to check GOT_A and GOT_V position,
--and make these signal sync
--deskew FIFO control
	elastic_delay_process : process(CLK,RESET)
		variable cb_sp : integer range 0 to 6 := 0;
		variable lane0_got_cb_save : integer range 0 to 6 := 0;
		variable lane1_got_cb_save : integer range 0 to 6 := 0;
		variable start_dec : std_logic;
		variable lane0_got_cb : std_logic;
		variable lane1_got_cb : std_logic;
		variable cb_over : std_logic;
	begin
		if RESET='1' then
			start_dec := '0';
			cb_sp := 0;
			cb_over := '0';
			lane0_got_cb := '0';
			lane1_got_cb := '0';
			elastic_buf_out_sp_lane0 <= 6 after DLY;
			elastic_buf_out_sp_lane1 <= 6 after DLY;
			CH_BOND_DONE <= "00";	
		elsif CLK='1' and CLK'event then
			if EN_CHAN_SYNC='1' then
				if start_dec='0' then
					if GOT_A/="0000" then
						if GOT_A(3 downto 0)="0101" then
							CH_BOND_DONE <= "11"  after DLY;
							cb_over := '1';
						else
							cb_sp := 0;
							if GOT_A(1 downto 0)/="00" then
								lane0_got_cb := '1';
								CH_BOND_DONE(0) <= '1';
							end if;
							if GOT_A(3 downto 2)/="00" then
								lane1_got_cb := '1';
								CH_BOND_DONE(1) <= '1';
							end if;
							start_dec := '1';
						end if;						
					end if;
				else
					cb_sp := cb_sp +1;
					if lane0_got_cb='0' then
						if GOT_A(1 downto 0)/="00" then
							lane0_got_cb := '1';
							elastic_buf_out_sp_lane0 <= elastic_buf_out_sp_lane0 - cb_sp after DLY;
							CH_BOND_DONE(0) <= '1';
						end if;
					end if;
					if lane1_got_cb='0' then
						if GOT_A(3 downto 2)/="00" then
							lane1_got_cb := '1';
							elastic_buf_out_sp_lane1 <= elastic_buf_out_sp_lane1 - cb_sp after DLY;
							CH_BOND_DONE(1) <= '1';
						end if;
					end if;
					if (lane0_got_cb='1' and lane1_got_cb='1') then
						CH_BOND_DONE <= "11"  after DLY;
						cb_sp := 0;
						cb_over := '1';
						lane0_got_cb := '0';
						lane1_got_cb := '0';
						start_dec :='0';
					else
						if cb_sp = 6 then
							cb_sp := 0;
							lane0_got_cb := '0';
							lane1_got_cb := '0';
							elastic_buf_out_sp_lane0 <= 6  after DLY;
							elastic_buf_out_sp_lane1 <= 6  after DLY;
							CH_BOND_DONE <= "00"  after DLY;
							start_dec := '0';
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
	

	
	process(CLK)
	begin
		if CLK='1' and CLK'event then
			--lane0 input
			rx_elastic_buf_lane0(0).data <= pipeline_output_0 after DLY;
			--lane1 input
			rx_elastic_buf_lane1(0).data <= pipeline_output_1 after DLY;
		end if;
	end process;

--space shift
elastic_buffer_shift0to1 : process(CLK)
begin
	if CLK='1' and CLK'event then
		rx_elastic_buf_lane0(1) <= rx_elastic_buf_lane0(0) after DLY;
		rx_elastic_buf_lane1(1) <= rx_elastic_buf_lane1(0) after DLY;
	end if;
end process;
elastic_buffer_shift1to2 : process(CLK)
begin
	if CLK='1' and CLK'event then
		rx_elastic_buf_lane0(2)  <= rx_elastic_buf_lane0(1) after DLY;
		rx_elastic_buf_lane1(2)  <= rx_elastic_buf_lane1(1) after DLY;
	end if;
end process;
elastic_buffer_shift2to3 : process(CLK)
begin
	if CLK='1' and CLK'event then
		rx_elastic_buf_lane0(3) <= rx_elastic_buf_lane0(2) after DLY;
		rx_elastic_buf_lane1(3)  <= rx_elastic_buf_lane1(2) after DLY;	
	end if;
end process;
elastic_buffer_shift3to4 : process(CLK)
begin
	if CLK='1' and CLK'event then
		rx_elastic_buf_lane0(4) <= rx_elastic_buf_lane0(3) after DLY;
		rx_elastic_buf_lane1(4)  <= rx_elastic_buf_lane1(3) after DLY;
	end if;
end process;
elastic_buffer_shift4to5 : process(CLK)
begin
	if CLK='1' and CLK'event then
		rx_elastic_buf_lane0(5) <= rx_elastic_buf_lane0(4) after DLY;
		rx_elastic_buf_lane1(5)  <= rx_elastic_buf_lane1(4) after DLY;
	end if;
end process;
elastic_buffer_shift5to6 : process(CLK)
begin
	if CLK='1' and CLK'event then
		rx_elastic_buf_lane0(6) <= rx_elastic_buf_lane0(5) after DLY;
		rx_elastic_buf_lane1(6)  <= rx_elastic_buf_lane1(5) after DLY;
	end if;
end process;



	lane0_mux : elastic_mux
	PORT map
	(
		clock			=> CLK,
		data0x		=> rx_elastic_buf_lane0(0).data,
		data1x		=> rx_elastic_buf_lane0(1).data,
		data2x		=> rx_elastic_buf_lane0(2).data,
		data3x		=> rx_elastic_buf_lane0(3).data,
		data4x		=> rx_elastic_buf_lane0(4).data,
		data5x		=> rx_elastic_buf_lane0(5).data,
		data6x		=> rx_elastic_buf_lane0(6).data,
		sel			=> conv_std_logic_vector(elastic_buf_out_sp_lane0,3),
		result		=> LANE0_Q
	);
	lane1_mux : elastic_mux
	PORT map
	(
		clock			=> CLK,
		data0x		=> rx_elastic_buf_lane1(0).data,
		data1x		=> rx_elastic_buf_lane1(1).data,
		data2x		=> rx_elastic_buf_lane1(2).data,
		data3x		=> rx_elastic_buf_lane1(3).data,
		data4x		=> rx_elastic_buf_lane1(4).data,
		data5x		=> rx_elastic_buf_lane1(5).data,
		data6x		=> rx_elastic_buf_lane1(6).data,
		sel			=> conv_std_logic_vector(elastic_buf_out_sp_lane1,3),
		result		=> LANE1_Q
	);

end MAIN;