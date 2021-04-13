----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.04.2021 17:22:41
-- Design Name: 
-- Module Name: hybrid_encoder_code_gen_stage - Behavioral
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

entity hybrid_encoder_code_gen_stage is
--  Port ( );
end hybrid_encoder_code_gen_stage;

architecture Behavioral of hybrid_encoder_code_gen_stage is

begin


end Behavioral;

--	--fourth stage processing
--	generate_output_code: process
--		variable bits: integer range 0 to 86;
--		variable code: unsigned(85 downto 0);
--	begin
--		if (cs_flush_bit(1) = '1') then
--			bits := 1;
--			code := (0 => '1', others => '0');
--		else
--			bits := 0;
--			code := (others => '0');
--		end if;	
--		if (cs_ihe = '1') then
--			if shift_right(unsigned(cs_mqi), to_integer(unsigned(cs_k))) < unsigned(cfg_u_max) then
--				bits := bits + 1 + to_integer(unsigned(cs_k)) + to_integer(shift_right(unsigned(cs_mqi), to_integer(unsigned(cs_k))));
--				--TODO
--				code := 
--			else
--				bits := bits + CONST_MAX_CODE_LENGTH;
--				code := shift_left(shift_left(code, to_integer(unsigned(cfg_depth))) + unsigned(cs_mqi), to_integer(unsigned(cfg_u_max)));
--			end if;
--		else
--			if (cs_input_symbol = CONST_INPUT_SYMBOL_X) then
--				--same as above but k = 0
--				if unsigned(cs_mqi) < unsigned(cfg_u_max) then
--					bits := bits + 1 + to_integer(unsigned(cs_mqi));
--				else
--					bits := bits + CONST_MAX_CODE_LENGTH;
--				end if;
--			end if;
--			if cs_is_tree(0) = '0' then
--				bits := bits + to_integer(unsigned(cs_cw_length));
--			end if;
--		end if;
--	end process;
	
----	axis_out_code			: out std_logic_vector(CONST_MAX_CODE_LENGTH - 1 downto 0);
----		axis_out_length			: out std_logic_vector(CONST_MAX_CODE_LENGTH_BITS - 1 downto 0);