----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.03.2021 09:34:58
-- Design Name: 
-- Module Name: code_aligner - Behavioral
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
use IEEE.NUMERIC_STD.ALL;


entity code_aligner is
	Port ( 
		clk, rst			: in std_logic;
		axis_in_code		: in std_logic_vector(63 downto 0);
		axis_in_length		: in std_logic_vector(6 downto 0);
		axis_in_valid		: in std_logic;
		axis_in_last		: in std_logic;
		axis_in_ready		: out std_logic;
		axis_out_data		: out std_logic_vector(63 downto 0);
		axis_out_valid		: out std_logic;
		axis_out_last		: out std_logic;
		axis_out_ready		: in std_logic
	);
end code_aligner;

architecture Behavioral of code_aligner is
	type state_t is (WORKING, FLUSHING, FINISHED);
	signal state_curr, state_next: state_t;
	
	signal buffered_free, buffered_free_next: std_logic_vector(6 downto 0);
	signal buffered_code, buffered_code_next: std_logic_vector(63 downto 0);
	
	--input latch signals
	signal input_latch_valid, input_latch_ready: std_logic;
	signal input_latch_code: std_logic_vector(63 downto 0);
	signal input_latch_length: std_logic_vector(6 downto 0);
	signal input_latch_last: std_logic;


	--output latch signals
	signal output_latch_valid, output_latch_ready: std_logic;
	signal output_latch_data: std_logic_vector(63 downto 0);
	signal output_latch_last: std_logic;
begin

	input_latch: entity work.AXIS_LATCHED_CONNECTION
		Generic map (
			DATA_WIDTH => 64,
			USER_WIDTH => 7
		)
		Port map (
			clk => clk, rst => rst,
			input_ready => axis_in_ready,
			input_valid => axis_in_valid,
			input_data  => axis_in_code,
			input_last  => axis_in_last,
			input_user  => axis_in_length,
			output_ready=> input_latch_ready,
			output_valid=> input_latch_valid,
			output_data => input_latch_code,
			output_last => input_latch_last,
			output_user => input_latch_length
		);

	seq: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				state_curr <= WORKING;
				buffered_free <= std_logic_vector(to_unsigned(64, buffered_free'length));
				buffered_code <= (others => '0');
			else
				state_curr <= state_next;
				buffered_free <= buffered_free_next;
				buffered_code <= buffered_code_next;
			end if;
		end if;
	end process;

	comb: process(
			clk, rst, state_curr,
			input_latch_valid, output_latch_ready, input_latch_last,
			input_latch_code, input_latch_length,
			buffered_free, buffered_code
		)
	begin
		buffered_free_next 	<= buffered_free;
		buffered_code_next 	<= buffered_code;
		state_next			<= state_curr;
		
		input_latch_ready <= '0';
		output_latch_valid <= '0';
		output_latch_last <= '0';
		
		output_latch_data <= (others => 'X');
	
		if state_curr = WORKING then
			--check if operation can be completed, otherwise don't do anything
			--we violate axis stream protocol, but it is latched so for the outside
			--ports we are still under strict standard
			if input_latch_valid = '1' and output_latch_ready = '1' then
				--not outputting
				if unsigned(buffered_free) > unsigned(input_latch_length) then
					input_latch_ready <= '1';
					buffered_free_next <= std_logic_vector(unsigned(buffered_free) - unsigned(input_latch_length));
					buffered_code_next <= 
						buffered_code 
						or 
						std_logic_vector(
							shift_left(unsigned(input_latch_code),to_integer(unsigned(buffered_free) - unsigned(input_latch_length)))
						);
					if input_latch_last = '1' then
						state_next <= FLUSHING;
					end if;
				elsif unsigned(buffered_free) = unsigned(input_latch_length) then
					buffered_free_next <= std_logic_vector(to_unsigned(64, buffered_free'length));
					buffered_code_next <= (others => '0');
					input_latch_ready <= '1';
					output_latch_valid <= '1';
					output_latch_data <= buffered_code or input_latch_code;
					if input_latch_last = '1' then
						output_latch_last <= '1';
						state_next <= FINISHED;
					end if;
				else
					--shifting out something and something else we keep
					input_latch_ready <= '1';
					output_latch_valid <= '1';
					output_latch_data <= 
						buffered_code 
						or 
						std_logic_vector(
							shift_right(unsigned(input_latch_code),to_integer(unsigned(input_latch_length) - unsigned(buffered_free)))
						);
					buffered_code_next <= 
					std_logic_vector(shift_left(unsigned(input_latch_code),to_integer(
						64 + unsigned(buffered_free) - unsigned(input_latch_length)  --127 + 1 to avoid overflow to 8 bit repr
					)));
					buffered_free_next <= std_logic_vector(64 + unsigned(buffered_free) - unsigned(input_latch_length));
					if input_latch_last <= '1' then
						state_next <= FLUSHING;
					end if;
				end if;
			end if;
		elsif state_curr = FLUSHING then
			output_latch_data <= buffered_code;
			output_latch_last <= '1';
			output_latch_valid <= '1';
			if output_latch_ready = '1' then
				state_next <= FINISHED;
			end if;
		elsif state_curr = FINISHED then
			--wait for reset
		end if;
	end process;

	output_latch: entity work.AXIS_LATCHED_CONNECTION
		Generic map (
			DATA_WIDTH => 64
		)
		Port map (
			clk => clk, rst => rst,
			input_ready => output_latch_ready,
			input_valid => output_latch_valid,
			input_data  => output_latch_data,
			input_last  => output_latch_last,
			output_ready=> axis_out_ready,
			output_valid=> axis_out_valid,
			output_data => axis_out_data,
			output_last => axis_out_last
		);

end Behavioral;
