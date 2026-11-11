create_clock -name clock_50 -period 20.000 [get_ports {clock_50}]
derive_pll_clocks
derive_clock_uncertainty
