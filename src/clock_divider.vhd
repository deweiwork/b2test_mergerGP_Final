library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.DataStruct_param_def_header.all;--invoke our defined type and parameter


entity clock_divider is    
    generic (
        divider_rate : integer
    );
    port (
        RST_N        : in  std_logic; 
        clk_in       : in  std_logic;
        clk_out      : out std_logic
    ); 
end clock_divider;

architecture clock_divider_RTL of clock_divider is
    signal clk_out_buf : std_logic := '0';
begin
frequency_divider: process (RST_N, clk_in) 
    variable counter : integer range 0 to 200000000 := 0;
begin
  if (RST_N = '0') then
        clk_out_buf <= '0';
        counter := 0;
  elsif rising_edge(clk_in) then
      if (counter = ((divider_rate/2)-1)) then
            clk_out_buf <= NOT(clk_out_buf);
            counter := 0;
      else
            counter := counter + 1;
      end if;
  end if;
end process frequency_divider;
    clk_out <= clk_out_buf ;
end architecture clock_divider_RTL;