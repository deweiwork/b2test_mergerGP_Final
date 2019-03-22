library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.DataStruct_param_def_header.all;--invoke our defined type and parameter

entity FRAME_CHECK is  
    port (
        RX_D                  : in  std_logic_vector((para_data_length_per_ch -1) downto 0) := (others => '0'); 

        RX_errdetect          : in  std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := (others => '0');    
        RX_disperr            : in  std_logic_vector((ctrl_code_length_per_ch -1) downto 0) := (others => '0'); 
        rx_freq_locked        : in  std_logic := '0';

        RX_traffic_ready      : in  std_logic := '0';
        
        -- Error Monitoring
        ERROR_COUNT           : out std_logic_vector((para_data_length_per_ch -1) downto 0) := (others => '0');
        -- System Interface
        USER_CLK              : in  std_logic := '0';       
        SYSTEM_RESET_N        : in  std_logic := '1'
    );
end FRAME_CHECK;


architecture RTL of FRAME_CHECK is    
    signal rx_pattern_r : std_logic_vector ((para_data_length_per_ch -1) downto 0);
    signal err_count_r  : std_logic_vector ((para_data_length_per_ch -1) downto 0) := (others => '0');
begin
    error_cnt : process( USER_CLK ,RX_traffic_ready,SYSTEM_RESET_N)
    begin
        if (SYSTEM_RESET_N = '0') then
            err_count_r <= (others => '0');
        elsif(RX_traffic_ready = '1' and rising_edge(USER_CLK)) then 
            if (RX_errdetect /= (RX_errdetect'range =>'0') or RX_disperr /= (RX_disperr'range  =>'0') or rx_freq_locked = '0') then
                err_count_r <= err_count_r + 1;     
                
                if err_count_r = (2**(para_data_length_per_ch) -1)-1 then
                    err_count_r <= null; 
                end if;       
            end if;    
        end if;
    end process error_cnt;

    ERROR_COUNT <= err_count_r;

end RTL;           