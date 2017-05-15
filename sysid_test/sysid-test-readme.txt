Sysid test

This is derived from Matthew's GSRD test

You will need to apply these two patches and compile the dtb's
and copy them to your Arria10 board at /lib/firmware.

 0001-socfpga_defconfig-enable-SYSID-driver.patch
 0002-arria10-dts-for-sysid-test.patch

The rbfs also should be compied to /lib/firmware

 ghrd_10as066n2.pr_partition.rbf
 alternate_persona.pr_partition.rbf
