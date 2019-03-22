library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.DataStruct_param_def_header.all;--invoke our defined type and parameter


entity ch_sync_buffer is  
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
        RST_N                               : in  std_logic 
    );
end ch_sync_buffer;

architecture top of ch_sync_buffer is 
    constant ch_sync_buffer_Length : integer := 2**ch_sync_buffer_Length_power;--ch_sync_buffer_Length_power def in DataStruct_param_def_header.vhd
    
    signal ch_sync_buffer_data_Out_r : std_logic_vector((para_data_length_per_ch -1) downto 0) := (others => '0');   
    
    type sync_buf_ch_type is array (grouped_ch -1 downto 0) of 
        sync_buf_data_type;
    signal sync_buf_ch : sync_buf_ch_type := (others => (others => (others => '0')));

    type out_mux_sel_ch_type is array ((grouped_ch -1) downto 0) of 
        integer range 0 to (ch_sync_buffer_Length_power -1) ;
    signal out_mux_sel_ch : out_mux_sel_ch_type := (others => ch_sync_buffer_Length_power - 1);

    type output_buf_type is array ((grouped_ch -1) downto 0) of 
        std_logic_vector((para_data_length_per_ch -1) downto 0);
    signal output_buf : output_buf_type := (others => (others => '0'));
    
    type syncing_status_type is 
        (wait_1st_sync_pattern,estimate_distance,sync_done);
    signal syncing_status : syncing_status_type := wait_1st_sync_pattern;

    signal ch_sync_buffer_overflow_r  : std_logic := '0';
    signal ch_sync_buffer_sync_done_r : std_logic := '0';
begin

    sync_buf_ch(0)(0) <= ch_sync_buffer_data_In_ch0;                
    sync_buf_ch(1)(0) <= ch_sync_buffer_data_In_ch1;

    shift_reg_gen_loop : for i in 0 to (ch_sync_buffer_Length -2) generate        
        ch_loop : for j in 0 to (grouped_ch -1) generate
            shift_reg : entity work.D_FF_sync_buf
                port map(
                    Q           => sync_buf_ch(j)(i+1),    
                    Clk         => CLK,
                    RST_N       => RST_N and sync_en ,  
                    D           => sync_buf_ch(j)(i) 
                ); 
        end generate ch_loop;     
    end generate shift_reg_gen_loop;
    
    sync_buf_syncing_algorithm : process(RST_N,CLK,sync_en)
        variable ch0_got_sync_pattern              : std_logic := '0';
        variable ch1_got_sync_pattern              : std_logic := '0';
        variable got_sync_pattern_sametime         : std_logic := '0';
        variable distance                          : integer range 0 to (2**ch_sync_buffer_Length_power -1) := 0;
    begin
        if (RST_N = '0' and sync_en = '0') then
            ch0_got_sync_pattern := '0';
            ch1_got_sync_pattern := '0';

            syncing_status <= wait_1st_sync_pattern;
            ch_sync_buffer_overflow_r  <= '0';
            ch_sync_buffer_sync_done_r <= '0';

            out_mux_sel_ch(0) <= (ch_sync_buffer_Length_power -1);
            out_mux_sel_ch(1) <= (ch_sync_buffer_Length_power -1);

            distance := 0 ;

        elsif (rising_edge(CLK)) then
            case (syncing_status) is        
                when wait_1st_sync_pattern =>
                    if (sync_en = '1') then
                        if (sync_buf_ch(0)(0) = sync_pattern and sync_buf_ch(1)(0) = sync_pattern) then
                            out_mux_sel_ch(0) <= 0;
                            out_mux_sel_ch(1) <= 0;
                            distance := 0;

                            syncing_status <= sync_done;
                            ch_sync_buffer_sync_done_r <= '1';
                        elsif (sync_buf_ch(0)(0) = sync_pattern and sync_buf_ch(1)(0) /= sync_pattern) then
                            ch0_got_sync_pattern := '1' ;
                            distance := distance +1;

                            syncing_status <= estimate_distance;
                            ch_sync_buffer_overflow_r <= '0';
                        elsif (sync_buf_ch(1)(0) = sync_pattern and sync_buf_ch(0)(0) /= sync_pattern) then
                            ch1_got_sync_pattern := '1' ;          
                            distance := distance +1;

                            syncing_status <= estimate_distance;
                            ch_sync_buffer_overflow_r <= '0';
                        else
                            ch0_got_sync_pattern := '0' ; 
                            ch1_got_sync_pattern := '0' ;    
                            distance := 0;

                            syncing_status <= wait_1st_sync_pattern;
                            ch_sync_buffer_overflow_r <= '0';
                        end if;
                    end if;

                when estimate_distance =>
                    if (ch0_got_sync_pattern = '1') then
                        if (sync_buf_ch(1)(0) = sync_pattern) then 
                            syncing_status <= sync_done ;
                            ch_sync_buffer_sync_done_r <= '1';

                            out_mux_sel_ch(0) <= distance;
                            out_mux_sel_ch(1) <= 0;
                        else
                            if (distance = (2**ch_sync_buffer_Length_power -1)) then
                                syncing_status   <= sync_done;
                                distance := 0;
                                ch_sync_buffer_overflow_r <= '1';
                            else
                                syncing_status   <= estimate_distance ;
                                distance := distance +1;
                                ch_sync_buffer_overflow_r <= '0';
                            end if ;
                        end if;
                        
                    elsif (ch1_got_sync_pattern = '1') then
                        if (sync_buf_ch(0)(0) = sync_pattern) then 
                            syncing_status <= sync_done ;
                            ch_sync_buffer_sync_done_r <= '1';

                            out_mux_sel_ch(0) <= 0;
                            out_mux_sel_ch(1) <= distance;
                        else
                            if (distance = (2**ch_sync_buffer_Length_power -1)) then
                                syncing_status   <= sync_done;
                                distance := 0;
                                ch_sync_buffer_overflow_r <= '1';
                            else
                                syncing_status   <= estimate_distance ;
                                distance := distance +1;
                                ch_sync_buffer_overflow_r <= '0';
                            end if ;
                        end if;                        
                    else
                        syncing_status <= estimate_distance;
                    end if;

                when sync_done =>

                    syncing_status <= sync_done ;

                when others =>
            
            end case ;
        end if;        
    end process sync_buf_syncing_algorithm;

    ch_sync_buffer_sync_done   <= ch_sync_buffer_sync_done_r;
    ch_sync_buffer_overflow    <= ch_sync_buffer_overflow_r;

    Out_mux_ch_gen_loop : for j in 0 to (grouped_ch -1) generate
        Mux : entity work.ch_sync_buf_out_mux
            port map(
                Data_Out    => output_buf(j),  
                sel         => conv_std_logic_vector(out_mux_sel_ch(j),ch_sync_buffer_Length_power),
                Data_In     => sync_buf_ch(j)
            );
    end generate Out_mux_ch_gen_loop;                  

    ch_sync_buffer_data_Out_ch0  <= output_buf(0) when ch_sync_buffer_directly_pass = '0' else ch_sync_buffer_data_In_ch0;
    ch_sync_buffer_data_Out_ch1  <= output_buf(1) when ch_sync_buffer_directly_pass = '0' else ch_sync_buffer_data_In_ch1;
end architecture top;