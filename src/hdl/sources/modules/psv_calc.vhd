----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2021 10:35:38
-- Design Name: 
-- Module Name: psv_calc - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity psv_calc is
	generic (
		PSV_WIDTH: integer := 16;
		DRPSV_WIDTH: integer := 16 + 1
	);
	Port (
		axis_in_drpsv_d 	: in std_logic_vector(DRPSV_WIDTH - 1 downto 0);
		axis_in_drpsv_ready	: out std_logic;
		axis_in_drpsv_valid	: in std_logic;
		axis_out_psv_d 	: out std_logic_vector(DRPSV_WIDTH - 1 downto 0);
		axis_out_psv_ready: in std_logic;
		axis_out_psv_valid: out std_logic
	);
end psv_calc;

architecture Behavioral of psv_calc is
begin
	
	assert PSV_WIDTH = DRPSV_WIDTH - 1 report "ERROR" severity failure;
	
	axis_in_drpsv_ready <= axis_out_psv_ready;
	axis_out_psv_valid <= axis_in_drpsv_valid;
	axis_out_psv_d <= axis_in_drpsv_d(axis_out_psv_d'high - 1 downto 0);

end Behavioral;
