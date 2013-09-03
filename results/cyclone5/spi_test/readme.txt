Interpretation of test results: 100% coverage

Run on rebuilt kernel 3.10.0-00152-gb6d7145-dirty (rebuilt with SPI support modules).
CONFIG_SPI_DESIGNWARE=y
CONFIG_SPI_DW_MMIO=y
CONFIG_SPI_SPIDEV=y

The following functions showed 0 calls:
dw_spi_add_host:0     => Called from SPI probe.
dw_spi_cleanup:0      => Called during kernel tear-down.
dw_spi_mmio_probe:0   => Called during kernel init
dw_spi_mmio_remove:0  => Called during Kernel tear-down.
dw_spi_remove_host:0  => Called to remove a new SPI host.
dw_spi_resume_host:0  => Called for power management
dw_spi_suspend_host:0 => Called for power management
spi_hw_init:0         => Called from dw_spi_add_host & dw_spi_resume_host.
spi_show_regs:0       => Debug purposes, not used.
start_queue:0         => Called from dw_spi_add_host & dw_spi_resume_host.
stop_queue:0          => Called from dw_spi_add_host & dw_spi_resume_host.

The above functions cannot be probed because they occur before tracing begins or
they are not being used (power management & debug)

