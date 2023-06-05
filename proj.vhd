library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
	port(
  	i_clk : in std_logic; 
		i_rst : in std_logic; 
		i_start : in std_logic;
		i_w : in std_logic;

		o_z0 : out std_logic_vector(7 downto 0); 
		o_z1 : out std_logic_vector(7 downto 0); 
		o_z2 : out std_logic_vector(7 downto 0); 
		o_z3 : out std_logic_vector(7 downto 0);

		o_done : out std_logic; 
		o_mem_addr : out std_logic_vector(15 downto 0); 
		i_mem_data : in std_logic_vector(7 downto 0); 
		o_mem_we : out std_logic; o_mem_en : out std_logic 	
	);	
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
	type state_type is (RESET, WAIT_START, READ, DONE);
	signal current_state : state_type;
	signal next_state : state_type;
	--segnali per memorizzare i dati internamente, che vengono visualizzati solo quando done = 1
	signal internal_z0 : std_logic_vector(7 downto 0) := (others => '0');
	signal internal_z1 : std_logic_vector(7 downto 0) := (others => '0');
	signal internal_z2 : std_logic_vector(7 downto 0) := (others => '0');
	signal internal_z3 : std_logic_vector(7 downto 0) := (others => '0');
	
	signal channel : unsigned(1 downto 0) := (others => '0');
	signal address : unsigned(15 downto 0) := (others => '0'); 
	
	signal done_reg : std_logic := '0'; --Segnale per dire che ho finito di scrivere

begin
	process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      -- Inizializzazione
      current_state <= RESET;
      o_z0 <= (others => '0');
      o_z1 <= (others => '0');
      o_z2 <= (others => '0');
      o_z3 <= (others => '0');
      done_reg <= '0';
      address <= (others => '0');
    elsif rising_edge(i_clk) then
    	if current_state = RESET then
    	-- Reset dei canali e del segnale DONE
      	o_z0 <= (others => '0');
        o_z1 <= (others => '0');
        o_z2 <= (others => '0');
        o_z3 <= (others => '0');
        o_done <= '0';
        done_reg <= '0';
        if i_start = '1' then
        	next_state <= WAIT_START;
        else
        	next_state <= RESET;
        end if;
        
			end if;

		end if;
  end process;

	lambda: process(current_state, i)
		begin
			case current_state is
				when S0 =>
					if i='0' then
						next_state <= S1;
					else
						next_state <= S0;
					end if;
				when S1 =>
					if i='0' then
						next_state <= S2;
					else
						next_state <= S0;
					end if;
				when S2 =>
					if i='0' then
						next_state <= S2;
					else
						next_state <= S3;
					end if;
				when S3 =>
					if i='1' then
						next_state <= S1;
					else
						next_state <= S0;
					end if;
				end case;
	end process;

	process (current_state)
	begin
	case current_state is
			when RESET => 
				o_z0 <= (others => '0');
      	o_z1 <= (others => '0');
      	o_z2 <= (others => '0');
      	o_z3 <= (others => '0');
      	done_reg <= '0';
      	address <= (others => '0');
      when WAIT_START_STATE =>
        o_mem_en <= '0';
        o_mem_we <= '0';

    end case;
	end process;

  process (done_reg)
  begin
		o_done <= done_reg;
    if done_reg = '1' then
			o_z0 <= internal_z0;
			o_z1 <= internal_z1;
			o_z2 <= internal_z2;
			o_z3 <= internal_z3;
    else
			o_z0 <= (others => '0');
      o_z1 <= (others => '0');
      o_z2 <= (others => '0');
      o_z3 <= (others => '0');
		end if;
  end process;

end Behavioral;
