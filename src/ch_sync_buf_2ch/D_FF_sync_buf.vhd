--ref : VHDL code for Rising Edge D Flip-Flop with Asynchronous Reset Low Level:
--http://www.fpga4student.com/2017/02/vhdl-code-for-d-flip-flop.html

Library IEEE;
USE IEEE.Std_logic_1164.all;

library work;
use work.DataStruct_param_def_header.all;--invoke our defined type and parameter

entity D_FF_sync_buf is 
    port(
        Q           : out std_logic_vector((para_data_length_per_ch -1) downto 0);    
        Clk         : in  std_logic;  
        RST_N       : in  std_logic;  
        D           : in  std_logic_vector((para_data_length_per_ch -1) downto 0)    
    );
end D_FF_sync_buf;

architecture Behavioral of D_FF_sync_buf is  
begin  
    process(Clk,RST_N)
    begin 
        if(RST_N='0') then 
            Q <= (others => '0');
        elsif(rising_edge(Clk)) then
            Q <= D; 
        end if;      
    end process;  
end Behavioral; 
