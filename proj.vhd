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
		o_mem_we : out std_logic;
		o_mem_en : out std_logic
	);	
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
	type state_type is (RESET, WAIT_START, READ_INPUT, DONE);
	signal current_state : state_type;
	signal next_state : state_type;
	--segnali per memorizzare i dati internamente, che vengono visualizzati solo quando done = 1
	signal internal_z0 : std_logic_vector(7 downto 0) := (others => '0');
	signal internal_z1 : std_logic_vector(7 downto 0) := (others => '0');
	signal internal_z2 : std_logic_vector(7 downto 0) := (others => '0');
	signal internal_z3 : std_logic_vector(7 downto 0) := (others => '0');
	
	signal channel : std_logic_vector(1 downto 0) := (others => '0');
	signal address : std_logic_vector(15 downto 0) := (others => '0'); 
	
	signal done_reg : std_logic := '0'; --Segnale per dire che ho finito di scrivere
	signal clock_counter : integer; --Quando = 2 allora inizio a leggere i bit dell'address

begin
	process (i_clk, i_rst)
	begin
		if i_rst = '1' then
			current_state <= RESET;
			
		elsif rising_edge(i_clk) then
		
			case current_state is
			
						when RESET =>
							internal_z0 <= (others => '0');
							internal_z1 <= (others => '0');
							internal_z2 <= (others => '0');
							internal_z3 <= (others => '0');
							done_reg <= '0';
							address <= (others => '0');

							if i_rst = '1' then
								next_state <= RESET;
							else
								next_state <= WAIT_START;
							end if;
			
						when WAIT_START =>
							clock_counter <= 0;
							done_reg <= '0';

							if i_start = '0' then
								next_state <= WAIT_START;
							else
								next_state <= READ_INPUT;
							end if;
			
						when READ_INPUT =>
							if clock_counter = 2 then
								--read address
								address <= address(14 downto 0) & i_w; 
							else
								--read channel
								channel <= channel(0) & i_w;
								clock_counter <= clock_counter + 1;
							end if;

							if i_start = '0' then
								next_state <= DONE;
							else
								next_state <= READ_INPUT;
							end if;
							
						when DONE =>
							o_mem_en <= '1';
							o_mem_we <= '1';
							o_mem_addr <= address;
							o_mem_we <= '0';
							case channel is
								when "00" => internal_z0 <= i_mem_data;
								when "01" => internal_z1 <= i_mem_data;
								when "10" => internal_z2 <= i_mem_data;
								when "11" => internal_z3 <= i_mem_data;
								when others =>
									internal_z0 <= (others => 'X');
									internal_z1 <= (others => 'X');
									internal_z2 <= (others => 'X');
									internal_z3 <= (others => 'X');

							end case;
							o_mem_en <= '0';
							done_reg <= '1';

							next_state <= WAIT_START;
					end case;

			current_state <= next_state;
		end if;
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
