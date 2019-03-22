library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.DataStruct_param_def_header.all;--invoke our defined type and parameter

entity traffic is
generic (
    --counting until value
    constant sent_k_until_clks    : integer := 2**16 -1;
    --K flag setting
    constant flag_of_k_ctrl      : std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := "01";
    constant flag_of_k_data      : std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := "00";
    constant flag_of_k_ctrl_swap : std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := "10";
    constant flag_of_k_err_2     : std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := "11";
    --pattern
    constant pattern_k0      : std_logic_vector((para_data_length_per_ch -1) downto 0) := X"02BC";
    constant pattern_K1      : std_logic_vector((para_data_length_per_ch -1) downto 0) := X"00BC";
    constant pattern_K0_swap : std_logic_vector((para_data_length_per_ch -1) downto 0) := X"BC02";
	constant pattern_B       : std_logic_vector((para_data_length_per_ch -1) downto 0) := X"5678";
    constant gp_data         : std_logic_vector((para_data_length_per_ch -1) downto 0) := X"1234"
);
port (
    Reset_n                  : in  std_logic;

    tx_traffic_ready         : out std_logic;
    rx_traffic_ready         : out std_logic;

    rx_elastic_buf_sync_done : in  std_logic;
    gp_sync_can_start        : out std_logic;

    lane_up                  : in  std_logic;

    TX_K                     : out std_logic_vector((ctrl_code_length_per_ch -1) downto 0) ;
    RX_K                     : in  std_logic_vector((ctrl_code_length_per_ch -1) downto 0) ;
    Tx_DATA_Xcvr             : out std_logic_vector((para_data_length_per_ch -1) downto 0) ;
    Rx_DATA_Xcvr             : in  std_logic_vector((para_data_length_per_ch -1) downto 0) ;
    Tx_DATA_client           : in  std_logic_vector((para_data_length_per_ch -1) downto 0) ;
    Rx_DATA_client           : out std_logic_vector((para_data_length_per_ch -1) downto 0) ;

    Tx_Clk                   : in  std_logic;
    Rx_Clk                   : in  std_logic

);
end traffic;


architecture top of traffic is
    type Tx_status_type is(
        idle,sent_pattern_k0_wait_rx_obtain,
        sent_pattern_k1_wait_rx_obtain,
        sent_pattern_B_wait_rx_obtain,
        sent_sync_patterns,
        sent_client_data
    );
    signal tx_status                 : Tx_status_type := sent_pattern_k0_wait_rx_obtain ;

    type Rx_status_type is(
        idle,wait_pattern_k0,
        wait_pattern_k1,
        wait_pattern_B,
        sync_align,
        wait_client_data
    );
    signal rx_status                 : Rx_status_type := wait_pattern_k0 ;

    signal lane_up_r_tx              : std_logic := '0';
    signal lane_up_r_rx              : std_logic := '0';
    signal XCVR_Manual_rst_r         : std_logic := '0';
    signal rx_freq_locked_r          : std_logic := '0';
    signal all_locked_r              : std_logic := '0';
    signal all_locked_o              : std_logic := '0';
    signal flag_swap                 : std_logic := '0';
    signal flag_swap_r               : std_logic := '0';

    signal RX_disperr_o              : std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := (others => '0');
    signal RX_errdetect_o            : std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := (others => '0');

    signal tx_traffic_ready_r        : std_logic := '0';--arria10
    signal rx_traffic_ready_r        : std_logic := '0';--arria10

    signal rx_sync_status_r          : std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := (others =>'0');--arria10
    signal rx_sync_status_o          : std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := (others =>'0');--arria10

    signal rx_pattern_detected_r     : std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := (others =>'0');--arria10
    signal rx_pattern_detected_o     : std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := (others =>'0');--arria10

    signal rx_align_en_r             : std_logic := '0';
    -- signal rx_can_sync_r             : std_logic := '0';--for grouping

    signal Rx_DATA_client_r          : std_logic_vector((para_data_length_per_ch -1) downto 0) := (others => '0');
    signal Rx_DATA_Xcvr_r            : std_logic_vector((para_data_length_per_ch -1) downto 0) := (others => '0');
    signal Rx_DATA_Xcvr_i            : std_logic_vector((para_data_length_per_ch -1) downto 0) := (others => '0');

    signal Tx_DATA_Xcvr_r            : std_logic_vector((para_data_length_per_ch -1) downto 0) := (others => '0');
    signal Tx_DATA_client_r          : std_logic_vector((para_data_length_per_ch -1) downto 0) := (others => '0');
    signal Tx_K_r                    : std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := (others =>'0');
    signal Rx_K_i                    : std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := (others =>'0');
    signal Rx_K_r                    : std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := (others =>'0');
    
    signal gp_sync_can_start_r       : std_logic := '0';

begin
    Tx_procedure : process(Tx_Clk,Reset_n,lane_up)
        variable rx_wait_cnt         : integer range 0 to sent_k_until_clks  := 0;
    begin
        if (Reset_n = '0' or lane_up = '0') then
            tx_status       <= idle;

            Tx_DATA_Xcvr    <= (others => '0');
            TX_K_r          <= flag_of_k_data;

            rx_wait_cnt    := 0;

            tx_traffic_ready    <= '0';
        else
            if (rising_edge(Tx_Clk)) then
                Tx_DATA_client_r <= Tx_DATA_client ;
                Tx_DATA_Xcvr     <= Tx_DATA_Xcvr_r ;
                TX_K   <= TX_K_r ;    
                
                lane_up_r_tx <= lane_up;
                tx_traffic_ready <= tx_traffic_ready_r ;

                case tx_status is
                    when idle =>
                        Tx_DATA_Xcvr_r <= (others => '0');
                        TX_K_r <= flag_of_k_data;
                        tx_traffic_ready_r  <= '0';
                        
                        if (lane_up_r_tx = '1') then
                            tx_status <= sent_pattern_k0_wait_rx_obtain;
                        else
                            tx_status <= idle;
                        end if;
                    when sent_pattern_k0_wait_rx_obtain =>
                        Tx_DATA_Xcvr_r <= pattern_k0;
                        TX_K_r         <= flag_of_k_ctrl;

                        if (rx_status = wait_pattern_k1) then
                            tx_status <= sent_pattern_k1_wait_rx_obtain ;
                        else
                            tx_status <= sent_pattern_k0_wait_rx_obtain ;
                        end if ;
                    when sent_pattern_k1_wait_rx_obtain =>
                        Tx_DATA_Xcvr_r <= pattern_K1;
                        TX_K_r         <= flag_of_k_ctrl;

                        if (rx_status = wait_pattern_B) then --rx received pattern_k1 , and go next status "wait_pattern_B"
                            rx_wait_cnt := 0 ;
                            tx_status <= sent_pattern_B_wait_rx_obtain;
                        else
                            if (rx_wait_cnt = sent_k_until_clks) then --watch dog
                                rx_wait_cnt := 0;
                                tx_status      <= idle;
                            else
                                rx_wait_cnt := rx_wait_cnt +1 ;
                                tx_status      <= sent_pattern_k1_wait_rx_obtain;
                            end if ;
                        end if ;

                    when sent_pattern_B_wait_rx_obtain =>
                        Tx_DATA_Xcvr_r <= pattern_B;
                        TX_K_r         <= flag_of_k_data;

                        if (rx_status = sync_align) then --rx received pattern_b , and go next status "wait_client_data"
                            rx_wait_cnt := 0 ;
                            tx_status     <= sent_sync_patterns;
                        else
                            if (rx_wait_cnt = sent_k_until_clks) then --watch dog
                                rx_wait_cnt := 0;
                                tx_status     <= idle;
                            else
                                rx_wait_cnt := rx_wait_cnt +1;
                                tx_status     <= sent_pattern_B_wait_rx_obtain;
                            end if ;
                        end if ;
                    when sent_sync_patterns =>
                        Tx_DATA_Xcvr_r <= gp_data;
                        TX_K_r         <= flag_of_k_data;

                        if (rx_elastic_buf_sync_done = '1') then
                            tx_status <= sent_client_data;
                        else         
                            if (rx_wait_cnt = sent_k_until_clks) then --watch dog
                                rx_wait_cnt := 0;
                                tx_status     <= idle;
                            else
                                rx_wait_cnt := rx_wait_cnt +1;
                                tx_status     <= sent_sync_patterns;
                            end if ;
                        end if;

                    when sent_client_data =>
                        Tx_DATA_Xcvr_r <= Tx_DATA_client_r;
                        TX_K_r         <= flag_of_k_data;

                        tx_traffic_ready_r <= '1';

                        tx_status      <= sent_client_data;

                    when others =>
                end case;
            end if ;
        end if ;
    end process Tx_procedure;

    Rx_procedure : process(Rx_Clk,Reset_n,lane_up)
        variable wait_k1_cnt     : integer range 0 to sent_k_until_clks  := 0;
        variable wait_B_cnt      : integer range 0 to sent_k_until_clks  := 0;
    begin
        if (Reset_n = '0' or lane_up = '0') then
            rx_status        <= idle;

            Rx_DATA_client   <= (others => '0');

            rx_traffic_ready <= '0';
            
            gp_sync_can_start   <= '0';

        else
            if (rising_edge(Rx_Clk)) then
                Rx_DATA_client   <=  Rx_DATA_client_r;

                Rx_DATA_Xcvr_i   <= Rx_DATA_Xcvr;
                
                RX_K_i <= RX_K ;

                lane_up_r_rx <= lane_up;
                rx_traffic_ready <= rx_traffic_ready_r ;
                flag_swap <= flag_swap_r;
            
                gp_sync_can_start   <= gp_sync_can_start_r;

                case( rx_status ) is
                    when idle =>
                        Rx_DATA_client_r <= (others => '0');
                        rx_traffic_ready_r <= '0';
                        
                        gp_sync_can_start_r    <= '0';

                        if (lane_up_r_rx = '1') then
                            rx_status <= wait_pattern_k0 ;
                        else
                            rx_status <= idle;
                        end if;

                    when wait_pattern_k0 =>
                        Rx_DATA_client_r <= (others => '0');

                        if (Rx_DATA_Xcvr_r = pattern_K0 and RX_K_r = flag_of_k_ctrl) then
                            rx_status        <= wait_pattern_k1;
                        elsif (Rx_DATA_Xcvr_r = pattern_K0_swap and RX_K_r = flag_of_k_ctrl_swap) then
                            flag_swap_r <= '1' ;
                            rx_status        <= wait_pattern_k1;
                        else
                            rx_status        <= wait_pattern_k0;
                        end if;

                    when wait_pattern_k1 =>
                        Rx_DATA_client_r <= (others => '0');

                        if (Rx_DATA_Xcvr_r = pattern_K1 and RX_K_r = flag_of_k_ctrl) then
                            rx_status        <= wait_pattern_B;
                        else
                            if (tx_status = idle) then--watch dog
                                rx_status   <= idle;
                            else
                                rx_status   <= wait_pattern_k1;
                            end if ;
                        end if;

                    when wait_pattern_B =>
                        Rx_DATA_client_r <= (others => '0');

                        if ((Rx_DATA_Xcvr_r = pattern_B and RX_K_r = flag_of_k_data) )then--watch dog
                            rx_status       <= sync_align;
                        else
                            if (tx_status = idle) then
                                rx_status  <= idle;
                            else
                                rx_status  <= wait_pattern_B;
                            end if ;
                        end if;

                    when sync_align =>    
                        Rx_DATA_client_r <= Rx_DATA_Xcvr_r;

                        gp_sync_can_start_r <= '1';

                        if (rx_elastic_buf_sync_done = '1') then
                            rx_status  <= wait_client_data;
                        else
                            rx_status  <= sync_align;

                            if (tx_status = idle) then--watch dog
                                rx_status   <= idle;
                            else
                                rx_status   <= sync_align;
                            end if ;
                        end if;

                    when wait_client_data =>
                        Rx_DATA_client_r <= Rx_DATA_Xcvr_r;

                        rx_traffic_ready_r <= '1';

                        rx_status        <= wait_client_data;

                    when others =>
                end case ;
            end if ;
        end if ;
    end process Rx_procedure;
    Rx_DATA_Xcvr_r   <= Rx_DATA_Xcvr_i((para_data_length_per_ch - 1) downto 0) when flag_swap = '0'
                            else Rx_DATA_Xcvr_i((para_data_length_per_ch/2 - 1) downto 0) & Rx_DATA_Xcvr_i((para_data_length_per_ch - 1) downto (para_data_length_per_ch/2));                            
    Rx_K_r <= RX_K_i((ctrl_code_length_per_ch-1) downto 0) when flag_swap = '0'
                            else RX_K_i(0) & RX_K_i(ctrl_code_length_per_ch-1);
end architecture top;
