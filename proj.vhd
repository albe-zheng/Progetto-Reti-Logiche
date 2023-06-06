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
	type state_type is (RESET, WAIT_START, READ_INPUT_A, READ_INPUT_B, WRITE_ADDRESS, READ_MEMORY, DONE);
	signal current_state : state_type := RESET;
	signal next_state : state_type;
	--segnali per memorizzare i dati internamente, che vengono visualizzati solo quando done = 1
	signal internal_z0 : std_logic_vector(7 downto 0) := (others => '0');
	signal internal_z1 : std_logic_vector(7 downto 0) := (others => '0');
	signal internal_z2 : std_logic_vector(7 downto 0) := (others => '0');
	signal internal_z3 : std_logic_vector(7 downto 0) := (others => '0');
	
	signal channel : std_logic_vector(1 downto 0) := (others => '0');
	signal address : std_logic_vector(15 downto 0) := (others => '0');
	
	signal done_reg : std_logic := '0'; --Segnale per dire che ho finito di scrivere
	signal clock_counter : integer range 0 to 2 := 0; --Quando = 2 allora inizio a leggere i bit dell'address
	signal data_reg : std_logic_vector(7 downto 0);

begin
	o_mem_we <= '0';

	process (i_clk, i_rst)
	begin
		if i_rst = '1' then
			current_state <= RESET;
			
		elsif rising_edge(i_clk) then
		
			case current_state is
				when RESET =>
					if i_rst = '1' then
						current_state <= RESET;
					else
						if i_start = '1' then
							current_state <= READ_INPUT_A;
						else
							current_state <= WAIT_START;
						end if;
					end if;
	
				when WAIT_START =>
					
					if i_start = '0' then
						current_state <= WAIT_START;
					else
						current_state <= READ_INPUT_A;
					end if;
	
				when READ_INPUT_A =>
					if i_start = '0' then
						current_state <= WRITE_ADDRESS;
					else
						current_state <= READ_INPUT_B;
					end if;
				
				when READ_INPUT_B =>
					if i_start = '0' then
					
						current_state <= WRITE_ADDRESS;
					else
						current_state <= READ_INPUT_A;
					end if;

				when WRITE_ADDRESS =>
					current_state <= READ_MEMORY;


				when READ_MEMORY =>
					current_state <= DONE;

				when DONE =>
					current_state <= WAIT_START;
			end case;

			
		end if;
	end process;

	process(current_state, clock_counter, done_reg)
	begin
		
			case current_state is
				when RESET =>
					internal_z0 <= (others => '0');
					internal_z1 <= (others => '0');
					internal_z2 <= (others => '0');
					internal_z3 <= (others => '0');
					done_reg <= '0';
					clock_counter <= 0;
					channel <= (others => '0');
					address <= (others => '0');
					o_mem_addr <= (others => '0');
					o_mem_en <= '0';

				when WAIT_START =>
					done_reg <= '0';
					clock_counter <= 0;
					channel <= (others => '0');
					address <= (others => '0');
					o_mem_addr <= (others => '0');

				when READ_INPUT_A =>
					
					
						if clock_counter = 2 then
							--read address
							address <= address(14 downto 0) & i_w; 
							clock_counter <= 2;
						else
							--read channel
							channel <= channel(0 downto 0) & i_w;
							clock_counter <= clock_counter + 1;
						end if;
				
				when READ_INPUT_B =>
					
						if clock_counter = 2 then
							--read address
							address <= address(14 downto 0) & i_w; 
						else
							--read channel
							channel <= channel(0 downto 0) & i_w;
							clock_counter <= clock_counter + 1;
						end if;


				when WRITE_ADDRESS =>
					o_mem_en <= '1';
					o_mem_addr <= address;		

				when READ_MEMORY =>
					o_mem_en <= '0';

				when DONE =>
					
					case channel is
							when "00" => internal_z0 <= data_reg;

							when "01" => internal_z1 <= data_reg;

							when "10" => internal_z2 <=  data_reg;
								
							when "11" => internal_z3 <= data_reg;
							when others => null;
						end case;
									
					done_reg <= '1';
			end case;

	end process;
	
	process (i_clk)
	begin
		if(i_rst = '0') then
			if falling_edge(i_clk) then
				if current_state = READ_MEMORY then
				data_reg <= std_logic_vector(unsigned(i_mem_data));
				elsif current_state = DONE then
					data_reg <= (others => '0');
				end if;
			end if;
		end if;
	end process;
	
	process (done_reg)
	begin
		if done_reg = '1' then
			o_z0 <= internal_z0;
			o_z1 <= internal_z1;
			o_z2 <= internal_z2;
			o_z3 <= internal_z3;
			o_done <= '1';
		else
			o_z0 <= (others => '0');
			o_z1 <= (others => '0');
			o_z2 <= (others => '0');
			o_z3 <= (others => '0');
			o_done <= '0';
		end if;
		
	end process;

end Behavioral;
