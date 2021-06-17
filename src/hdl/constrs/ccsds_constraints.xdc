create_clock -period 3.333 [get_ports clk]

create_clock -period 10.000 [get_ports c_s_axi_clk]
create_clock -period 5.000  [get_ports d_m_axi_clk]
create_clock -period 4.000  [get_ports ccsds_clk]


#create_clock -period 3.333  [get_ports axis_in_clk]
#create_clock -period 2.000  [get_ports axis_out_clk]