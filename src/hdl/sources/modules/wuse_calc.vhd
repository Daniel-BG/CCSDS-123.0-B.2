----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.03.2021 14:21:06
-- Design Name: 
-- Module Name: wuse_calc - Behavioral
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
use ieee.numeric_std.all;

entity wuse_calc is
	Port ( 
		cfg_samples			: in std_logic_vector(CONST_MAX_SAMPLES_BITS - 1 downto 0);
		cfg_tinc			: in std_logic_vector(CONST_TINC_BITS - 1 downto 0);
		cfg_vmax, cfg_vmin	: in std_logic_vector(CONST_VMINMAX_BITS - 1 downto 0);
		cfg_depth			: in std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
		cfg_omega			: in std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0);
		axis_coord_t		: in std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
		axis_coord_valid	: in std_logic;
		axis_coord_ready	: out std_logic;
		axis_wuse_ready		: in std_logic;
		axis_wuse_valid		: out std_logic;
		axis_wuse_d			: out std_logic_vector(CONST_WUSE_BITS - 1 downto 0)
	);
end wuse_calc;

architecture Behavioral of wuse_calc is
	signal t_minus_samples: std_logic_vector(CONST_MAX_T_VALUE_BITS downto 0);
	signal t_minus_samples_shifted_plus_vmin: std_logic_vector(CONST_MAX_T_VALUE_BITS downto 0);
	
	signal t_clipped: std_logic_vector(CONST_VMINMAX_BITS - 1 downto 0);
begin
	
	t_minus_samples <= std_logic_vector(signed("0" & axis_coord_t) - signed("0" & cfg_samples));
	t_minus_samples_shifted_plus_vmin <= std_logic_vector(signed(cfg_vmin) + shift_right(signed(t_minus_samples), to_integer(unsigned(cfg_tinc))));
	
	t_clipped <= 
		std_logic_vector(resize(signed(cfg_vmin), t_clipped'length)) when signed(t_minus_samples_shifted_plus_vmin) < signed(cfg_vmin) else
		std_logic_vector(resize(signed(cfg_vmax), t_clipped'length)) when signed(t_minus_samples_shifted_plus_vmin) > signed(cfg_vmax) else
		std_logic_vector(resize(signed(t_minus_samples_shifted_plus_vmin), t_clipped'length));
		
	axis_wuse_d <= std_logic_vector(
		signed("00" & t_clipped) + signed("00" & cfg_depth) + signed("00" & cfg_omega) 
	);
	axis_wuse_valid <= axis_coord_valid;
	axis_coord_ready <= axis_wuse_ready;
	
end Behavioral;








