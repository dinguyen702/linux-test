Interpretation of test results: 100% coverage

Run on rebuilt kernel 
Linux socfpga_cyclone5 3.12.0-00321-g301b1c7 #1 SMP Mon Jan 27 14:53:05 CST 2014 armv7l GNU/Linux 
(rebuilt with EDAC modules enabled).
CONFIG_EDAC_ALTERA_MC=y

The following functions showed 0 calls:
altr_sdram-get_total_mem_size:0     => Called from probe().
altr_sdram_mc_probe:0   => Called during kernel init
altr_sdram_mc_remove:0  => Called during Kernel tear-down.
altr_sdr_mc_create_debugfs_nodes:0  => Called from probe().

The above functions cannot be probed because they occur before tracing begins or
they are not being used (power management & debug)

