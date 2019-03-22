library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.DataStruct_param_def_header.all;--invoke our defined type and parameter

entity XCVR_TOP is
    port (
        RST_N_in                : in  std_logic := '1' ;

        XCVR_Ref_Clock_external : in  std_logic;
        XCVR_Ref_Clock_internal : in  std_logic;
        init_clk                : in  std_logic;

        RX_ser_bank             : in  ser_data_men_bank;
        TX_ser_bnak             : out ser_data_men_bank;

        tx_Para_data_bank             : in  para_data_men_bank;
        rx_Para_data_bank             : out para_data_men_bank;
        ext_tx_para_data_clk_bank     : out ser_data_men_bank;
        ext_rx_para_data_clk_bank     : out ser_data_men_bank;
        tx_traffic_ready_ext_bank     : out std_logic_vector((num_of_xcvr_bank_used - 1) downto 0);
        rx_traffic_ready_ext_bank     : out std_logic_vector((num_of_xcvr_bank_used - 1) downto 0);

        Ref_clock_ckh_LED			 : out std_logic;
        clk_div_out                  : out std_logic;

        RJ45_CLK_BUF_EN_0_N 	      :	out std_logic;
        RJ45_CLK_BUF_EN_1_N 	      :	out std_logic;

		opt0_en				          : out std_logic;
		opt1_en				          :	out std_logic;
		opt0_dis				      :	out std_logic;
		opt1_dis				      :	out std_logic;
		opt0_reset_n		          :	out std_logic;
		opt1_reset_n		          :	out std_logic;

        error_cnt_ch_bank             : out para_data_men_bank

    );
end entity XCVR_TOP ;

architecture XCVR_TOP_connect of XCVR_TOP is
    component clk_buffer is
		port (
			inclk  : in  std_logic := 'X'; -- inclk
			outclk : out std_logic         -- outclk
		);
	end component clk_buffer;
    --Ref_Clock
    signal XCVR_Ref_Clock   	     : std_logic;
	--normal test port
	signal RST_N_out_buf			 : std_logic;
    signal test_Clock   			 : std_logic;
    signal test_Clock_2   			 : std_logic;
    --ser data

    signal Tx_ser_buf             : ser_data_men_bank ;
    signal Rx_ser_buf             : ser_data_men_bank ;

    --para data
    signal tx_Para_data_bank_buf  : para_data_men_bank := (others=> (others => (others => '0')));
    signal rx_Para_data_bank_buf  : para_data_men_bank := (others=> (others => (others => '0')));

    signal error_cnt_ch_bank_buf  : para_data_men_bank := (others=> (others => (others => '0')));
    --ext clock
    signal ext_tx_para_data_clk_bank_buf     : ser_data_men_bank ;
    signal ext_rx_para_data_clk_bank_buf     : ser_data_men_bank ;

    signal tx_traffic_ready_ext_bank_buf     : std_logic_vector((num_of_xcvr_bank_used - 1) downto 0) ;
    signal rx_traffic_ready_ext_bank_buf     : std_logic_vector((num_of_xcvr_bank_used - 1) downto 0) ;

begin
    --ref_clock in/ext selector
    XCVR_Ref_Clock <= XCVR_Ref_Clock_external when ref_clock_from_ext = '1' else XCVR_Ref_Clock_internal;
    --connect ser data
    TX_ser_bnak  <= TX_ser_buf ;
    RX_ser_buf   <= RX_ser_bank;
    --connect ext para data
    tx_Para_data_bank_buf <=  tx_Para_data_bank  ;
    rx_Para_data_bank     <=  rx_Para_data_bank_buf;
    --connect ext para data clk
    ext_tx_para_data_clk_bank  <= ext_tx_para_data_clk_bank_buf ;
    ext_rx_para_data_clk_bank  <= ext_rx_para_data_clk_bank_buf ;
    tx_traffic_ready_ext_bank  <= tx_traffic_ready_ext_bank_buf ;
    rx_traffic_ready_ext_bank  <= rx_traffic_ready_ext_bank_buf ;

    error_cnt_ch_bank  <= error_cnt_ch_bank_buf ;

    --connect XCVR
    Connect_XVCR_Module_loop : for i in 0 to (num_of_xcvr_bank_used - 1) generate
    XCVR_Module_gen : entity work.XCVR_8B10B_interconnect
        port map (
            RST_N                       => RST_N_in,

            XCVR_Ref_Clock              => XCVR_Ref_Clock,
            init_clk                    => XCVR_Ref_Clock,

            TX_para_external_ch         => tx_Para_data_bank_buf(i),
            RX_para_external_ch         => rx_Para_data_bank_buf(i),
            TX_para_external_clk_ch     => ext_tx_para_data_clk_bank_buf(i),
            RX_para_external_clk_ch     => ext_rx_para_data_clk_bank_buf(i),
            tx_traffic_ready_ext_ch     => tx_traffic_ready_ext_bank_buf(i),
            rx_traffic_ready_ext_ch     => rx_traffic_ready_ext_bank_buf(i),
            error_cnt_ch                => error_cnt_ch_bank_buf(i),

            RX_ser                      => Rx_ser_buf(i),
            TX_ser                      => Tx_ser_buf(i)
        );
    end generate Connect_XVCR_Module_loop;

    RJ45_CLK_BUF_EN_0_N     <= '0';
    RJ45_CLK_BUF_EN_1_N     <= '0';

	opt0_en				    <= '1';
	opt1_en				    <= '1';
	opt0_dis				<= '0';
	opt1_dis				<= '0';
	opt0_reset_n		    <= '1';
	opt1_reset_n		    <= '1';

end architecture XCVR_TOP_connect;
