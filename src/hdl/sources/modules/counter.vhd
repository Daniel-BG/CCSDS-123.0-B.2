----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.03.2021 14:11:06
-- Design Name: 
-- Module Name: counter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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
use work.ccsds_constants.all;
use work.ccsds_data_structures.all;
use ieee.numeric_std.all;

entity counter is
	generic (
		USER_WIDTH: integer := 1
	);
	Port (
		clk, rst				: in std_logic;
		cfg_initial_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_final_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		axis_in_mqi_d			: in std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_in_mqi_ready		: out std_logic;
		axis_in_mqi_valid		: in std_logic;
		axis_in_mqi_coord		: in coordinate_bounds_array_t;
		axis_in_mqi_user		: in std_logic_vector(USER_WIDTH - 1 downto 0) := (others => '0');
		axis_out_mqi			: out std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_out_coord			: out coordinate_bounds_array_t;
		axis_out_counter		: out std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		axis_out_ready			: in std_logic;
		axis_out_valid			: out std_logic;
		axis_out_user			: out std_logic_vector(USER_WIDTH - 1 downto 0) := (others => '0')
	);
end counter;

architecture Behavioral of counter is
	signal counter: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
begin
	
	axis_out_mqi <= axis_in_mqi_d;
	axis_in_mqi_ready <= axis_out_ready;
	axis_out_valid <= axis_in_mqi_valid;
	axis_out_coord <= axis_in_mqi_coord;
	axis_out_counter <= counter;
	axis_out_user <= axis_in_mqi_user;
	
	seq: process(clk, rst, cfg_initial_counter)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				counter <= cfg_initial_counter;
			else
				if axis_out_ready = '1' and axis_in_mqi_valid = '1' and F_STDLV2CB(axis_in_mqi_coord).last_z = '1' then 
					--current pixel is done as well as the transaction, update counter for next pixel
					if unsigned(counter) < unsigned(cfg_final_counter) then
						counter <= std_logic_vector(unsigned(counter) + 1);
					else
						counter <= std_logic_vector((unsigned(counter) + 1) / 2);
					end if;
				end if;
			end if;
		end if;
	end process;
	

end Behavioral;
