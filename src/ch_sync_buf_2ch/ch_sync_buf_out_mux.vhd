Library IEEE;
USE IEEE.Std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.DataStruct_param_def_header.all;--invoke our defined type and parameter

entity ch_sync_buf_out_mux is 
    port(
        Data_Out    : out std_logic_vector((para_data_length_per_ch -1) downto 0);   
        sel         : in  std_logic_vector((ch_sync_buffer_Length_power -1) downto 0);  
        Data_In     : in  sync_buf_data_type  
    );
end ch_sync_buf_out_mux;

architecture Behavioral of ch_sync_buf_out_mux is  
begin 
    Data_Out <= Data_In(conv_integer(sel));
end Behavioral; 