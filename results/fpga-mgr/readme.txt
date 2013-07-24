Interpretation of test results: 100% coverage

When running the test initally, some functions maxxed out the trace buffer,
even when the buffer was made to be very large.  These functions are
(from fpga-mgr-coverage.txt):
alt_fpga_configure_write:691745
fpga_data_writel:691722

This causes some trace output to be dropped out of the buffer which causes
some functions to appear that they were never called.  Since I've already
shown that alt_fpga_configure_write and fpga_data_writel were covered
(being called >600K times),  I did a second test run without these two
functions.  The results are in the fpga-mgr*no-swamp*.txt files.

The functions that show 0 calls in the fpga-mgr-coverage-no-swamping.txt mostly
are due to them being called during driver initialization (before tracing is
configured and enabled).  The only exceptions are two functions that are
not used for our driver (fpga_data_readl and fpga_data_read) because our fpga
manager does not support reading the FPGA image back.

alt_fpga_probe:0              == init
alt_fpga_remove:0             == init
fpga_attach_mmio_transport:0  == init
fpga_data_readl:0             == not used
fpga_detach_mmio_transport:0  == init
fpga_mgr_attach_transport:0   == init
fpga_mgr_detach_transport:0   == init
fpga_mgr_read:0               == not used
register_fpga_manager:0       == init
remove_fpga_manager:0         == init
