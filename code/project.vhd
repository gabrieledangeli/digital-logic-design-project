----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Engineer: Gabriele D'Angeli, Francesco Di Stefano
-- 
-- Create Date: 28.12.2020
-- Design Name: 
-- Module Name: project
-- Project Name: digital_design_logic
-- Target Devices: 
-- Tool Versions: 
-- Description: Final Project for Digital Design Logic Course A.Y. 2020-2021
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_data : in STD_LOGIC_VECTOR (7 downto 0);
           o_address : out STD_LOGIC_VECTOR (15 downto 0);
           o_done : out STD_LOGIC;
           o_en : out STD_LOGIC;
           o_we : out STD_LOGIC;
           o_data : out STD_LOGIC_VECTOR (7 downto 0));
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type state is (init_state, rst_state, dimension_state, delta_state, shift_state, tmp_pixel_state, read_state, write_state, end_state);
    signal curr_state : state := init_state;
    signal writing : STD_LOGIC;
    signal mem_read_position, mem_write_position, img_dimension : STD_LOGIC_VECTOR(15 downto 0);
    signal img_width, img_height, max_pixel_value, min_pixel_value, delta_value : STD_LOGIC_VECTOR(7 downto 0);
    signal tmp_pixel : STD_LOGIC_VECTOR(15 downto 0);
    signal shift_level: STD_LOGIC_VECTOR(3 downto 0);
begin
    process(i_clk)
       variable tmp1, tmp2 : STD_LOGIC_VECTOR(15 downto 0);
    begin
        if falling_edge(i_clk) then
            if (i_rst = '1') then
                curr_state <= rst_state;
            else
				case curr_state is
					when init_state =>
                
					when rst_state =>
						o_address <= (others => '0');
						o_done <= '0';
						o_en <= '0';
						o_we <= '0';
						o_data <= (others => '0');
						writing <= '0';
						mem_read_position <= (others => '0');
						mem_write_position <= (others => '0');
						img_width <= (others => '0');
						img_height <= (others => '0');
						img_dimension <= (others => '0');
						max_pixel_value <= (others => '0');
						min_pixel_value <= (others => '1');
						delta_value <= (others => '0');
						tmp_pixel <= (others => '0');
						shift_level <= (others => '0');
						if (i_start = '1') then
							o_en <= '1';
							curr_state <= dimension_state;
						end if;          
				
					when dimension_state =>
						if (to_integer(unsigned(mem_read_position)) = 0) then
							img_width <= i_data;
							mem_read_position <= std_logic_vector(unsigned(mem_read_position) + 1);
							o_address <= std_logic_vector(unsigned(mem_read_position) + 1);
						elsif (to_integer(unsigned(mem_read_position)) = 1) then
							img_height <= i_data;
							mem_read_position <= std_logic_vector(unsigned(mem_read_position) + 1);
							o_address <= std_logic_vector(unsigned(mem_read_position) + 1);
						elsif (to_integer(unsigned(img_height)) > 0) then
							img_dimension <= std_logic_vector(unsigned(img_dimension) + unsigned(img_width));
							img_height <= std_logic_vector(unsigned(img_height) - 1);
						else
							curr_state <= delta_state;
						end if;
				
					when delta_state =>
						if (to_integer(unsigned(mem_read_position)) <= to_integer(unsigned(img_dimension)) + 1) then
							if (to_integer(unsigned(max_pixel_value)) < to_integer(unsigned(i_data))) then
								max_pixel_value <= i_data;
							end if;
							if (to_integer(unsigned(min_pixel_value)) > to_integer(unsigned(i_data))) then
								min_pixel_value <= i_data;
							end if;
							mem_read_position <= std_logic_vector(unsigned(mem_read_position) + 1);
							o_address <= std_logic_vector(unsigned(mem_read_position) + 1);
						else 
							delta_value <= std_logic_vector(unsigned(max_pixel_value) - unsigned(min_pixel_value));
							curr_state <= shift_state;
						end if;
                    
					when shift_state =>
						case to_integer(unsigned(delta_value)) is
							when 0 =>
								shift_level <= "1000";
							
							when 1 to 2 =>
								shift_level <= "0111";
							
							when 3 to 6 =>
								shift_level <= "0110";
							
							when 7 to 14 =>
								shift_level <= "0101";
							
							when 15 to 30 =>
								shift_level <= "0100";
							
							when 31 to 62 =>
								shift_level <= "0011";
							
							when 63 to 126 =>
								shift_level <= "0010";
							
							when 127 to 254 =>
								shift_level <= "0001";
							
							when 255 =>
								shift_level <= "0000";
							
							when others =>
						end case; 
						mem_write_position <= mem_read_position;
						mem_read_position <= (1 => '1', others => '0');
						o_address <= (1 => '1', others => '0');
						curr_state <= tmp_pixel_state;
                
					when tmp_pixel_state =>
						if (to_integer(unsigned(mem_write_position)) <= to_integer(shift_left(unsigned(img_dimension), 1)) + 1) then
							tmp1 := "00000000" & i_data;
							tmp2 := "00000000" & min_pixel_value;
							tmp_pixel <= std_logic_vector(shift_left(unsigned(tmp1) - unsigned(tmp2), to_integer(unsigned(shift_level))));
							curr_state <= write_state;
							mem_read_position <= std_logic_vector(unsigned(mem_read_position) + 1);
						else    
							o_done <= '1';
							curr_state <= end_state;         
						end if;
                
					when write_state =>
						if (to_integer(unsigned(tmp_pixel)) > 255) then
							o_data <= (others => '1');
						else
							o_data <= tmp_pixel(7 downto 0);
						end if;
						o_address <= mem_write_position;
						o_we <= '1';
						mem_write_position <= std_logic_vector(unsigned(mem_write_position) + 1);
						curr_state <= read_state;
                    
					when read_state =>
						o_address <= mem_read_position;
						o_we <= '0';
						curr_state <= tmp_pixel_state;
                                
					when end_state =>
						if(i_start = '0') then
							curr_state <= rst_state;
						end if;
				end case;
            end if;
			end if;
    end process;
end Behavioral;