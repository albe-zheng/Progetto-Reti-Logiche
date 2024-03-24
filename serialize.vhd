library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity serialize is
    port(
        i_rst   : in std_logic;
        i_clk   : in std_logic;
        i_start : in std_logic;
        i_offset: in std_logic_vector(0 to 2);
        
        o_mem_read : out std_logic;
        o_mem_addr : out std_logic_vector(0 to 7);
        i_mem_data : in std_logic_vector(0 to 15);
        i_mem_done : in std_logic;
        o_ser   : out std_logic;
        o_en    : out std_logic
        );
end serialize;

architecture serialize_arch of serialize is

    type S is (WAIT_START, ASK_MEM, READ_MEM, SERIALIZE);

    signal curr_state : S;
    signal counter_curr : std_logic_vector(0 to 3);
    signal counter_next : std_logic_vector(0 to 3);
    signal counter_ovf  : std_logic;
    signal counter_rst  : std_logic;
    
    signal data_reg_save : std_logic;
    signal data_reg : std_logic_vector(0 to 15);
    
    component inc4 is
    port( input    : in std_logic_vector(0 to 3);
          output   : out std_logic_vector(0 to 3);
          overflow : out std_logic
        );
    end component;
    
begin

    incrementer : inc4 port map(
        input => counter_curr,
        output => counter_next,
        overflow => counter_ovf        
    );

    mem_addr_calc : process(i_offset)   
    -- Processo combinatorio
    begin
        o_mem_addr <= "11000" & i_offset;
    end process;

    counter_reg : process(i_clk, counter_rst)
    -- Processo sequenziale
    begin
        if counter_rst = '1' then
            counter_curr <= "0000";
        elsif i_clk'event and i_clk = '1' then  -- Non dimenticarsi il 'event, altrimenti vengono
                                                -- generati dei latch
            counter_curr <= counter_next;
        end if;
    end process;

    data_reg_proc : process(data_reg_save)
    -- Processo sequenziale
    begin
        if data_reg_save'event and data_reg_save = '1' then
            data_reg <= i_mem_data;
        end if;
    end process;

    fsm : process(i_clk, i_rst)
    -- Processo sequenziale
    -- Poteva essere diviso in funzione delta (combinatoria)
    -- e parte di memoria (sequenziale)
    begin
        if i_rst = '1' then
            curr_state <= WAIT_START;
        elsif i_clk'event and i_clk = '1' then
            case curr_state is
                when WAIT_START =>
                    if i_start='1' then
                        curr_state <= ASK_MEM;
                    end if;
                when ASK_MEM =>
                    if i_mem_done = '1' then
                        curr_state <= READ_MEM;
                    end if;
                when READ_MEM =>
                    curr_state <= SERIALIZE;
                when SERIALIZE =>
                    if counter_ovf = '1' then
                        curr_state <= WAIT_START;
                    end if;
            end case;
        end if;
    end process;
    
    mux_counter : process(counter_curr, data_reg)
    -- Processo combinatorio
    begin
        case counter_curr is
            when "0000" => o_ser <= data_reg(0);
            when "0001" => o_ser <= data_reg(1);
            when "0010" => o_ser <= data_reg(2);
            when "0011" => o_ser <= data_reg(3);
            when "0100" => o_ser <= data_reg(4);
            when "0101" => o_ser <= data_reg(5);
            when "0110" => o_ser <= data_reg(6);
            when "0111" => o_ser <= data_reg(7);
            when "1000" => o_ser <= data_reg(8);
            when "1001" => o_ser <= data_reg(9);
            when "1010" => o_ser <= data_reg(10);
            when "1011" => o_ser <= data_reg(11);
            when "1100" => o_ser <= data_reg(12);
            when "1101" => o_ser <= data_reg(13);
            when "1110" => o_ser <= data_reg(14);
            when "1111" => o_ser <= data_reg(15);

            when others => o_ser <= 'X';    -- Non dimenticarsi il caso base
                                            -- alternativamente metterlo prima del case
        end case;
    end process;
    
    fsm_lambda : process(curr_state)
    -- Processo combinatorio
    begin
        -- Valori di default per tutte le uscite
        o_en <= '0';
        o_mem_read <= '0';
        counter_rst <= '1';
        data_reg_save <= '0';

        case curr_state is
            when WAIT_START =>                
            when ASK_MEM =>
                o_mem_read <= '1';
            when READ_MEM =>
                o_mem_read <= '0';
                data_reg_save <= '1';
            when SERIALIZE =>
                o_en <= '1';
                counter_rst <= '0';
                
        end case;    
    
    end process;
    
end architecture;
