library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.DataStruct_param_def_header.all;--invoke our defined type and parameter


entity ch_sync_buffer_2ch is   
    generic (
        constant grouped_ch                 : integer := 2;
        constant sync_pattern               : std_logic_vector((para_data_length_per_ch -1) downto 0) := x"1234"                
    );
    port (
        ch_sync_buffer_data_In_ch0          : in  std_logic_vector((para_data_length_per_ch -1) downto 0) ; 
        ch_sync_buffer_data_In_ch1          : in  std_logic_vector((para_data_length_per_ch -1) downto 0) ;

        ch_sync_buffer_data_Out_ch0         : out std_logic_vector((para_data_length_per_ch -1) downto 0) ; 
        ch_sync_buffer_data_Out_ch1         : out std_logic_vector((para_data_length_per_ch -1) downto 0) ; 

        ch_sync_buffer_sync_done            : out std_logic ;
        ch_sync_buffer_overflow             : out std_logic ;

        sync_en                             : in  std_logic ;

        ch_sync_buffer_directly_pass        : in  std_logic ;
        
        CLK                                 : in  std_logic ;       
        Reset_n                             : in  std_logic 
    );
end ch_sync_buffer_2ch;

architecture top of ch_sync_buffer_2ch is 
    constant ch_sync_buffer_Length : integer := 2**ch_sync_buffer_Length_power;--ch_sync_buffer_Length_power def in DataStruct_param_def_header.vhd
  
    type sync_buf_ch_type is array (grouped_ch -1 downto 0) of 
        sync_buf_data_type;
    signal sync_buf_ch : sync_buf_ch_type := (others => (others => (others => '0')));

    type int_4ch_t is array (grouped_ch -1 downto 0) of integer range 0 to (2**ch_sync_buffer_Length_power -1);
    signal cnt_ch           : int_4ch_t := (others => 0);    
    signal out_mux_sel_ch   : int_4ch_t := (others => ch_sync_buffer_Length_power - 1);  
    
    type syncing_status_type is (sync_start, sync_done);
    signal sync_status      : syncing_status_type := sync_start;

    type output_buf_type is array ((grouped_ch -1) downto 0) of 
        std_logic_vector((para_data_length_per_ch -1) downto 0);
    signal output_buf : output_buf_type := (others => (others => '0'));
  

    signal ch_sync_buffer_sync_done_r   : std_logic := '0';
    signal ch_sync_buffer_overflow_r    : std_logic := '0';

begin

        sync_buf_ch(0)(0) <= ch_sync_buffer_data_In_ch0;
        sync_buf_ch(1)(0) <= ch_sync_buffer_data_In_ch1;

    shift_reg_gen_loop : for i in 0 to (ch_sync_buffer_Length -2) generate        
        ch_loop : for j in 0 to (grouped_ch -1) generate
            shift_reg : entity work.D_FF_sync_buf
                port map(
                    Q           => sync_buf_ch(j)(i+1),    
                    Clk         => CLK,
                    RST_N       => Reset_n and sync_en ,  
                    D           => sync_buf_ch(j)(i) 
                ); 
        end generate ch_loop;     
    end generate shift_reg_gen_loop;

    sync_process: process(Reset_n,CLK,sync_en)
    begin
        if (Reset_n = '0' and sync_en = '0') then
            cnt_ch          <= (others => 0);
            sync_status     <= sync_start;
            out_mux_sel_ch  <= (others => ch_sync_buffer_Length_power - 1); 
               
            ch_sync_buffer_sync_done_r  <= '0';
            ch_sync_buffer_overflow_r   <= '0';
            ch_sync_buffer_sync_done    <= '0';
            ch_sync_buffer_overflow     <= '0';

        elsif (rising_edge(CLK)) then
            ch_sync_buffer_sync_done <= ch_sync_buffer_sync_done_r;
            ch_sync_buffer_overflow  <= ch_sync_buffer_overflow_r;
            case sync_status is                    
                when sync_start =>
                    ch_sync_buffer_sync_done_r <= '0';
                    for i in 0 to (grouped_ch-1) loop
                        if (cnt_ch(i) /= 0) then
                            sync_status <= sync_done;
                        elsif (sync_buf_ch(i)(0) = sync_pattern) then
                            if (cnt_ch(i) = (2**ch_sync_buffer_Length_power -2)) then
                                ch_sync_buffer_overflow_r   <= '1';
                            else
                                cnt_ch(i)   <= cnt_ch(i)+1;
                                ch_sync_buffer_overflow_r   <= '0';
                                sync_status <= sync_start;
                            end if ;
                        end if;
                    end loop;

                when sync_done =>
                    for i in 0 to (grouped_ch-1) loop
                        out_mux_sel_ch(i) <= cnt_ch(i) -1;
                    end loop;
                    ch_sync_buffer_sync_done_r <= '1';
                    ch_sync_buffer_overflow_r  <= '0';
                when others =>        
            
            end case;
        end if;
    end process sync_process;

    Out_mux_ch_gen_loop : for j in 0 to (grouped_ch -1) generate
        Out_Mux : entity work.ch_sync_buf_out_mux
            port map(
                Data_Out    => output_buf(j),  
                sel         => conv_std_logic_vector(out_mux_sel_ch(j),ch_sync_buffer_Length_power),
                Data_In     => sync_buf_ch(j)
            );
    end generate Out_mux_ch_gen_loop; 

    ch_sync_buffer_data_Out_ch0 <= ch_sync_buffer_data_In_ch0 when ch_sync_buffer_directly_pass = '1' else output_buf(0);
    ch_sync_buffer_data_Out_ch1 <= ch_sync_buffer_data_In_ch1 when ch_sync_buffer_directly_pass = '1' else output_buf(1);

end architecture top;