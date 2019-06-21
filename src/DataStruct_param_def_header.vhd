library ieee;
use ieee.std_logic_1164.all;

package DataStruct_param_def_header is
--====================
--define global const
--====================

    constant MAX_XCVR_BANK_OF_THIS_FPGA               : integer := 8;--max defined by FPGA-10AX066 ,We use 1 bank in this file
    constant MAX_XCVR_CHANNEL_OF_THIS_FPGA            : integer := 6;--max defined by FPGA-10AX066 ,We use 1ch in this file

    constant num_of_xcvr_bank_used                    : integer range 1 to MAX_XCVR_BANK_OF_THIS_FPGA := 1;
    constant num_of_xcvr_ch                           : integer range 1 to MAX_XCVR_CHANNEL_OF_THIS_FPGA := 4;

    constant grouping_enable                          : std_logic := '1';--if grouping is enabled , then must set it as '1'

    constant src_data_is_counter                      : std_logic := '1';--when 1 , src data use counter data

    constant scr_para_Data_gen_check_form_this_module : std_logic := '1';--when 1 , data gen and data check use internal defaulted

    constant ref_clock_from_ext                       : std_logic := '1';--when 1, ref_clock from external(LEMO connector), else use board OSC.

    constant xcvr_tx_data_clk_buf_used                : std_logic := '1';--clock buffer is not very sufficient, so if you use multi-channel (>12), you must cautiously estimate to used.If responsibility for adding clock buffer is user, then set it as '0'.
    constant xcvr_rx_data_clk_buf_used                : std_logic := '1';--clock buffer is not very sufficient, so if you use multi-channel (>12), you must cautiously estimate to used.If responsibility for adding clock buffer is user, then set it as '0'.
    ---------
    --paramenter of xcvr module
    ---------
    constant xcvr_ser_internal_loopback_en           : std_logic := '1';

    constant para_data_length_per_ch                 : integer range 1 to 64 := 16;

    constant ctrl_code_length_per_ch                 : integer range 1 to 64 := 2;
    ---------
    --Grouping
    ---------
    constant ch_sync_buffer_Length_power : integer := 4;

--====================
--define global data type
--====================

    subtype ser_data_men is std_logic_vector((num_of_xcvr_ch - 1) downto 0) ;
    type ser_data_men_bank is array ((num_of_xcvr_bank_used - 1) downto 0) of
            ser_data_men;

    type para_data_men is array ((num_of_xcvr_ch - 1) downto 0) of
            std_logic_vector ((para_data_length_per_ch - 1) downto 0);
    type para_data_men_bank is array ((num_of_xcvr_bank_used - 1)downto 0) of
            para_data_men;

    type ctrl_code_8B10B is array ((num_of_xcvr_ch - 1) downto 0) of
        std_logic_vector((ctrl_code_length_per_ch - 1) downto 0);
    --Grouping
    type sync_buf_data_type is array (2**ch_sync_buffer_Length_power -1 downto 0) of 
        std_logic_vector((para_data_length_per_ch -1) downto 0);

end package DataStruct_param_def_header;
