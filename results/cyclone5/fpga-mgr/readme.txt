Interpretation of test results: 100% coverage

Run on RC1 with rebuilt kernel 3.9.0-00152-ge82076d

Note that two functions get called a *lot*
alt_fpga_configure_write:691745
fpga_data_writel:691722

When rerunning the test, there is some risk that they can max out the
trace buffer, causing some test results to be pushed out of the buffer.
If that happens, rerun the tests while eliminating these two functions
from the trace to show a more accurate coverage.

The functions that show 0 calls in the fpga-mgr-coverage.txt mostly
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
