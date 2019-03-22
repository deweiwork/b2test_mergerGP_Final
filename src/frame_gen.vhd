library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.DataStruct_param_def_header.all;--invoke our defined type and parameter

entity FRAME_GEN is    
    port (
        TX_D             : out std_logic_vector ((para_data_length_per_ch -1) downto 0 ):= (others => '0'); 

        TX_traffic_ready : in std_logic := '0';

        USER_CLK         : in  std_logic := '0';
        SYSTEM_RESET_N   : in  std_logic := '0'
    ); 
end FRAME_GEN;


architecture RTL of FRAME_GEN is
    signal tx_d_r         : std_logic_vector ((para_data_length_per_ch -1) downto 0);
begin
    TxData_cnt : process( USER_CLK,SYSTEM_RESET_N, TX_traffic_ready)
    begin
        if(SYSTEM_RESET_N = '0' or TX_traffic_ready = '0') then
            tx_d_r <= (others => '0'); 
        else
            if( rising_edge(USER_CLK) ) then  
                    if src_data_is_counter = '1' then         
                        tx_d_r <= tx_d_r + 1 ;
                            if tx_d_r = (2**(para_data_length_per_ch) -1)-1 then
                                tx_d_r <= (others => '0'); 
                            end if;
                    else
                        tx_d_r((para_data_length_per_ch -1) downto para_data_length_per_ch/2) <=  (others => '0');  
                        tx_d_r((para_data_length_per_ch/2 -1) downto 0) <=  (others => '1');     
                    end if;        
            end if;             
        end if;
    end process TxData_cnt;              
           
    TX_D         <= tx_d_r;
end RTL;