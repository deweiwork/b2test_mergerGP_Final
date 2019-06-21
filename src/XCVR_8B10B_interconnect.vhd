--if you want to modify channel
--just modify component of transceiver(xcvr)

--!! warning !!
--user need to see "DataStruct_param_def_header.vhd"
--most important of typedef and parameter in here
--!! warning !!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.DataStruct_param_def_header.all;--invoke our defined type and parameter

entity XCVR_8B10B_interconnect is
    port (
        RST_N                       : in  std_logic := '0' ;

        TX_para_external_ch         : in  para_data_men;
        RX_para_external_ch         : out para_data_men;
        TX_para_external_clk_ch     : out ser_data_men;
        RX_para_external_clk_ch     : out ser_data_men;
        tx_traffic_ready_ext_ch     : out std_logic;
        rx_traffic_ready_ext_ch     : out std_logic;
        error_cnt_ch                : out para_data_men;

        XCVR_Ref_Clock              : in  std_logic;
        init_clk                    : in  std_logic;

        RX_ser                      : in  ser_data_men;
        TX_ser                      : out ser_data_men
    );
end entity XCVR_8B10B_interconnect ;


architecture Top of XCVR_8B10B_interconnect is
    component clk_buffer is
		port (
			inclk  : in  std_logic := 'X'; -- inclk
			outclk : out std_logic         -- outclk
		);
	end component clk_buffer;
    --clock
    signal XCVR_Tx_clk_out_ch                       : ser_data_men := (others =>'0');
    signal XCVR_Rx_clk_out_ch                       : ser_data_men := (others =>'0');
    signal tx_clk_buf_out               		    : ser_data_men := (others =>'0');
    signal rx_clk_buf_out              				: ser_data_men := (others =>'0');
    signal tx_clk_buf_out_to_ext                    : ser_data_men := (others =>'0');
    signal rx_clk_buf_out_to_ext                    : ser_data_men := (others =>'0');
    --==================--
    ----data gen/check----
    --==================--
    --loopback_en
    signal internal_loopback_en_ch       : ser_data_men := (others =>'0');

    --para data
    signal tx_Para_data_ch               : para_data_men;
    signal rx_Para_data_ch               : para_data_men;

    signal tx_Para_data_external_buf_ch  : para_data_men;
    signal rx_Para_data_external_buf_ch  : para_data_men;

    signal tx_Para_data_internal_buf_ch  : para_data_men;
    signal rx_Para_data_internal_buf_ch  : para_data_men;

    signal tx_Para_data_internal_ch      : para_data_men;
    signal rx_Para_data_internal_ch      : para_data_men;

    signal xcvr_tx_Para_data_ch          : para_data_men;
    signal xcvr_rx_Para_data_ch          : para_data_men;
    --ready
    signal lane_up                          : std_logic := '0';

    signal TX_traffic_ready_ch              : ser_data_men := (others =>'0');
    signal RX_traffic_ready_ch              : ser_data_men := (others =>'0');
    signal TX_traffic_ready_buf_ch          : std_logic := '0';
    signal RX_traffic_ready_buf_ch          : std_logic := '0';

    signal tx_traffic_ready_internal_ch  : std_logic;
    signal rx_traffic_ready_internal_ch  : std_logic;
    --===============--
    ----transceiver----
    --===============--
    --controlled data
    signal rx_disp_err_ch           : ctrl_code_8B10B;
    signal rx_err_detec_ch          : ctrl_code_8B10B;

    signal rx_data_k_ch             : ctrl_code_8B10B;
    signal tx_data_k_ch             : ctrl_code_8B10B;

    signal rx_patterndetect_ch      : ctrl_code_8B10B;
    signal rx_syncstatus_ch         : ctrl_code_8B10B;
    --===============--
    --for arria-2    --
    --===============--

    --reconfig
    signal reconfig_from_gxb        : std_logic_vector ((17 - 1) downto 0) := (others => '0');
    signal reconfig_to_gxb          : std_logic_vector ((4 - 1) downto 0) := (others => '0');
    --Xcvr
    signal XCVR_TxRx_rst            : std_logic;--ser_data_men := (others =>'0');

    signal rx_enapatternalign       : std_logic;

    signal pll_locked               : std_logic ;--stratix4
    signal rx_freqlocked_ch         : ser_data_men := (others =>'0');--stratix4
    --to XCVR Buffer (stratix-4 arria-2)
    signal pll_locked_from_XCVR         : std_logic_vector(0 downto 0) ;--stratix4

    signal tx_data_k_toXCVR             : std_logic_vector((ctrl_code_length_per_ch*num_of_xcvr_ch -1) downto 0);
    signal xcvr_tx_Para_data_to_XCVR    : std_logic_vector((para_data_length_per_ch*num_of_xcvr_ch -1) downto 0);

    signal rx_data_k_ch_from_XCVR       : std_logic_vector((ctrl_code_length_per_ch*num_of_xcvr_ch -1) downto 0);
    signal xcvr_rx_Para_data_from_XCVR  : std_logic_vector((para_data_length_per_ch*num_of_xcvr_ch -1) downto 0);
    signal rx_disp_err_from_XCVR        : std_logic_vector((ctrl_code_length_per_ch*num_of_xcvr_ch -1) downto 0);
    signal rx_err_detec_from_XCVR       : std_logic_vector((ctrl_code_length_per_ch*num_of_xcvr_ch -1) downto 0);
    signal rx_syncstatus_from_XCVR      : std_logic_vector((ctrl_code_length_per_ch*num_of_xcvr_ch -1) downto 0);
    signal rx_patterndetect_from_XCVR   : std_logic_vector((ctrl_code_length_per_ch*num_of_xcvr_ch -1) downto 0);
    --for grouping
    signal rx_Para_data_from_sync_buf_ch    : para_data_men ;
    signal rx_Para_data_to_sync_buf_ch      : para_data_men ;
    signal elastic_buf_sync_done            : ser_data_men := (others =>'0');
    signal elastic_can_start_sync           : ser_data_men := (others =>'0');
    signal sync_buf_overflow_ch_01          : std_logic := '0';
    signal sync_buf_sync_done_ch_01         : std_logic := '0';
    signal sync_buf_overflow_ch_23          : std_logic := '0';
    signal sync_buf_sync_done_ch_23         : std_logic := '0';
    signal elastic_buf_overflow             : std_logic := '0';

begin
    --connect loopback_en
    internal_loopback_en_ch <= (others =>'1') when xcvr_ser_internal_loopback_en = '1' else (others =>'0');

    --connecte para data with internal/external selector
    tx_Para_data_ch <= tx_Para_data_internal_ch when scr_para_Data_gen_check_form_this_module = '1';
    tx_Para_data_ch <= TX_para_external_ch      when scr_para_Data_gen_check_form_this_module = '0';

    rx_Para_data_ch <= rx_Para_data_from_sync_buf_ch;

    rx_Para_data_internal_ch <= rx_Para_data_ch when scr_para_Data_gen_check_form_this_module = '1';
    RX_para_external_ch      <= rx_Para_data_ch when scr_para_Data_gen_check_form_this_module = '0';

    TX_para_external_clk_ch <= tx_clk_buf_out when scr_para_Data_gen_check_form_this_module = '0';
    RX_para_external_clk_ch <= rx_clk_buf_out when scr_para_Data_gen_check_form_this_module = '0';
    
    RX_traffic_ready_buf_ch <= and_reduce(RX_traffic_ready_ch);
    TX_traffic_ready_buf_ch <= and_reduce(TX_traffic_ready_ch);
    --ready-ext
    rx_traffic_ready_ext_ch <= RX_traffic_ready_buf_ch when scr_para_Data_gen_check_form_this_module = '0';
    tx_traffic_ready_ext_ch <= TX_traffic_ready_buf_ch when scr_para_Data_gen_check_form_this_module = '0';
    --ready-int
    rx_traffic_ready_internal_ch <= RX_traffic_ready_buf_ch  when scr_para_Data_gen_check_form_this_module = '1';
    tx_traffic_ready_internal_ch <= TX_traffic_ready_buf_ch  when scr_para_Data_gen_check_form_this_module = '1';
    --to XCVR Buffer connect ( cast from <ctrl_code_8B10B> or <para_data_men> to std_logic_vector<(data_length*(i+1) -1) downto data_length*i> )
    XCVR_Buffer_connect : for i in 0 to (num_of_xcvr_ch - 1) generate
        --tx
        xcvr_tx_Para_data_to_XCVR(((i+1)*para_data_length_per_ch -1) downto (i*para_data_length_per_ch))  <= xcvr_tx_Para_data_ch(i) ;
        tx_data_k_toXCVR(((i+1)*ctrl_code_length_per_ch -1) downto (i*ctrl_code_length_per_ch))           <= tx_data_k_ch(i);
        --rx
        xcvr_rx_Para_data_ch(i)  <= xcvr_rx_Para_data_from_XCVR(((i+1)*para_data_length_per_ch -1) downto (i*para_data_length_per_ch));
        rx_data_k_ch(i)          <= rx_data_k_ch_from_XCVR(((i+1)*ctrl_code_length_per_ch -1) downto (i*ctrl_code_length_per_ch));
        rx_err_detec_ch(i)       <= rx_disp_err_from_XCVR(((i+1)*ctrl_code_length_per_ch -1) downto (i*ctrl_code_length_per_ch));
        rx_disp_err_ch(i)        <= rx_err_detec_from_XCVR(((i+1)*ctrl_code_length_per_ch -1) downto (i*ctrl_code_length_per_ch));
        rx_syncstatus_ch(i)      <= rx_syncstatus_from_XCVR(((i+1)*ctrl_code_length_per_ch -1) downto (i*ctrl_code_length_per_ch));
        rx_patterndetect_ch(i)   <= rx_patterndetect_from_XCVR(((i+1)*ctrl_code_length_per_ch -1) downto (i*ctrl_code_length_per_ch));

    end generate XCVR_Buffer_connect;
    --connect PLL locked (cast from <std_logic_vector(0 downto 0)> to <std_logic>)
    pll_locked <= pll_locked_from_XCVR(0);
    --XCVR module connect
    XCVR : entity work.XCVR_3125_4ch
        port map(
            cal_blk_clk		    => XCVR_Ref_Clock,
            pll_inclk		    => XCVR_Ref_Clock,
            reconfig_clk		=> XCVR_Ref_Clock,
            reconfig_togxb		=> reconfig_to_gxb,
            rx_coreclk		    => rx_clk_buf_out,
            rx_cruclk		    => (others => XCVR_Ref_Clock),
            rx_datain		    => RX_ser,
            rx_digitalreset		=> (others =>XCVR_TxRx_rst),
            rx_enapatternalign	=> (others => rx_enapatternalign),
            rx_seriallpbken		=> internal_loopback_en_ch,
            tx_coreclk		    => tx_clk_buf_out,
            tx_ctrlenable		=> tx_data_k_toXCVR,
            tx_datain		    => xcvr_tx_Para_data_to_XCVR,
            tx_digitalreset		=> (others =>XCVR_TxRx_rst),
            pll_locked		    => pll_locked_from_XCVR,
            reconfig_fromgxb	=> reconfig_from_gxb,
            rx_clkout		    => XCVR_Rx_clk_out_ch,
            rx_ctrldetect	    => rx_data_k_ch_from_XCVR,
            rx_dataout		    => xcvr_rx_Para_data_from_XCVR,
            rx_disperr		    => rx_disp_err_from_XCVR,
            rx_errdetect		=> rx_err_detec_from_XCVR,
            rx_freqlocked		=> rx_freqlocked_ch,
            rx_patterndetect	=> rx_patterndetect_from_XCVR,
            rx_syncstatus		=> rx_syncstatus_from_XCVR,
            tx_clkout		    => XCVR_Tx_clk_out_ch,
            tx_dataout		    => Tx_ser
        );
    XCVR_reconfig : entity work.XCVR_Reconfig_3125_4ch
    	port map(
            reconfig_clk		=> XCVR_Ref_Clock,
            reconfig_fromgxb	=> reconfig_from_gxb,
            busy		        => open,
            reconfig_togxb		=> reconfig_to_gxb
        );
    --others connect
    Data_gen_loop : for i in 0 to (num_of_xcvr_ch - 1) generate
        judg_if_data_is_internal : if scr_para_Data_gen_check_form_this_module = '1' generate
            Data_gen : entity work.frame_gen
                port map(
                    TX_D             => tx_Para_data_internal_ch(i),

                    TX_traffic_ready => tx_traffic_ready_internal_ch,

                    USER_CLK         => tx_clk_buf_out(i) ,
                    SYSTEM_RESET_N   => RST_N
                );
        end generate judg_if_data_is_internal;
    end generate Data_gen_loop;

    Data_check_loop : for i in 0 to (num_of_xcvr_ch - 1) generate
        judg_if_data_is_internal : if scr_para_Data_gen_check_form_this_module = '1' generate
            Data_check : entity work.frame_check
                port map(
                    RX_D              => rx_Para_data_internal_ch(i),

                    RX_traffic_ready  => rx_traffic_ready_internal_ch,

                    RX_errdetect      => rx_err_detec_ch(i),
                    RX_disperr        => rx_disp_err_ch(i),
                    rx_freq_locked    => rx_freqlocked_ch(i),

                    ERROR_COUNT       => error_cnt_ch(i),

                    USER_CLK          => rx_clk_buf_out(i),
                    SYSTEM_RESET_N    => RST_N
                );
        end generate judg_if_data_is_internal;
    end generate Data_check_loop;

    generate_traffic_loop : for i in 0 to (num_of_xcvr_ch - 1) generate
        traffic : entity work.traffic
            port map(
                Reset_n                  => RST_N,
                lane_up                  => lane_up,

                tx_traffic_ready         => TX_traffic_ready_ch(i),
                rx_traffic_ready         => RX_traffic_ready_ch(i),

                rx_elastic_buf_sync_done => elastic_buf_sync_done(i),
                gp_sync_can_start        => elastic_can_start_sync(i),

                Tx_K                     => tx_data_k_ch(i),
                Rx_K                     => rx_data_k_ch(i),
                TX_DATA_Xcvr             => xcvr_tx_Para_data_ch(i),
                RX_DATA_Xcvr             => xcvr_rx_Para_data_ch(i),
                Tx_DATA_client           => tx_Para_data_ch(i),
                Rx_DATA_client           => rx_Para_data_to_sync_buf_ch(i),

                Tx_Clk                   => tx_clk_buf_out(i),
                Rx_Clk                   => rx_clk_buf_out(i)
            );
    end generate generate_traffic_loop;

    rst_logic: entity work.reset_logic
    port map (
        Reset_n                 => RST_N,
        INIT_CLK                => init_clk,

        XCVR_rst_out            => XCVR_TxRx_rst,
        align_en                => rx_enapatternalign,
        lane_up                 => lane_up,

        RX_freq_locked          => rx_freqlocked_ch,
        XCVR_pll_locked         => pll_locked,

        RX_elastic_buf_overflow => elastic_buf_overflow,
        RX_sync_status          => rx_syncstatus_ch,
        RX_pattern_detected     => rx_patterndetect_ch,
        RX_errdetect            => rx_err_detec_ch,
        RX_disperr              => rx_disp_err_ch
    );

    ch_sync_buf_2ch_01 : entity work.ch_sync_buffer_2ch
    port map(
        ch_sync_buffer_data_In_ch0          => rx_Para_data_to_sync_buf_ch(0),
        ch_sync_buffer_data_In_ch1          => rx_Para_data_to_sync_buf_ch(1),

        ch_sync_buffer_data_Out_ch0         => rx_Para_data_from_sync_buf_ch(0),
        ch_sync_buffer_data_Out_ch1         => rx_Para_data_from_sync_buf_ch(1),

        ch_sync_buffer_sync_done            => sync_buf_sync_done_ch_01,
        ch_sync_buffer_overflow             => sync_buf_overflow_ch_01,

        sync_en                             => elastic_can_start_sync(0) and elastic_can_start_sync(1),

        ch_sync_buffer_directly_pass        => not(grouping_enable),
        
        CLK                                 => rx_clk_buf_out(0),
        Reset_n                             => RST_N
    );    
    ch_sync_buf_2ch_23 : entity work.ch_sync_buffer_2ch
    port map(
        ch_sync_buffer_data_In_ch0          => rx_Para_data_to_sync_buf_ch(2),
        ch_sync_buffer_data_In_ch1          => rx_Para_data_to_sync_buf_ch(3),

        ch_sync_buffer_data_Out_ch0         => rx_Para_data_from_sync_buf_ch(2),
        ch_sync_buffer_data_Out_ch1         => rx_Para_data_from_sync_buf_ch(3),

        ch_sync_buffer_sync_done            => sync_buf_sync_done_ch_23,
        ch_sync_buffer_overflow             => sync_buf_overflow_ch_23,

        sync_en                             => elastic_can_start_sync(2) and elastic_can_start_sync(3),

        ch_sync_buffer_directly_pass        => not(grouping_enable),
        
        CLK                                 => rx_clk_buf_out(2),
        Reset_n                             => RST_N
    );
    
    elastic_buf_sync_done(0) <= sync_buf_sync_done_ch_01;
    elastic_buf_sync_done(1) <= sync_buf_sync_done_ch_01;
    elastic_buf_sync_done(2) <= sync_buf_sync_done_ch_23;
    elastic_buf_sync_done(3) <= sync_buf_sync_done_ch_23;

    elastic_buf_overflow <= sync_buf_overflow_ch_01 or sync_buf_overflow_ch_23;

	generate_TX_BUFG_loop : for i in 0 to (num_of_xcvr_ch - 1) generate
        xcvr_tx_data_clk_buf_used_assert : if xcvr_tx_data_clk_buf_used = '1' generate
            gen_TX_BUFG : clk_buffer
                port map
                (
                    inclk                               =>      XCVR_Tx_clk_out_ch(i),
                    outclk                              =>      tx_clk_buf_out(i)
                );
        end generate xcvr_tx_data_clk_buf_used_assert;
        xcvr_tx_data_clk_buf_not_used_assert : if xcvr_tx_data_clk_buf_used = '0' generate
            tx_clk_buf_out(i) <= XCVR_Tx_clk_out_ch(i);
        end generate xcvr_tx_data_clk_buf_not_used_assert;
    end generate  generate_TX_BUFG_loop;

    generate_RX_BUFG_loop : for i in 0 to (num_of_xcvr_ch - 1) generate
        xcvr_rx_data_clk_buf_used_assert : if xcvr_rx_data_clk_buf_used = '1' generate
			  gen_RX_BUFG : clk_buffer
					port map
					(
						 inclk                                =>      XCVR_Rx_clk_out_ch(i),
						 outclk                               =>      rx_clk_buf_out(i)
					);
        end generate xcvr_rx_data_clk_buf_used_assert;
        xcvr_rx_data_clk_buf_not_used_assert : if xcvr_rx_data_clk_buf_used = '0' generate
            rx_clk_buf_out(i) <= XCVR_Rx_clk_out_ch(i);
        end generate xcvr_rx_data_clk_buf_not_used_assert;
    end generate generate_RX_BUFG_loop;
end architecture Top;
