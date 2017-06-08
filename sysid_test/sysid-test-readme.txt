Sysid test

This is derived from Matthew's GSRD test

https://sj-arc.altera.com/tools/soceds/17.0/current.linux64/linux64/not_shipped/examples/hardware/a10_soc_devkit_sdmmc_pr/output_files/

These 3 rbf's were downloaded from that build:
* This rbf needs to go onto the booting sd card's fat partition as the image that uboot will use.
  * ghrd_10as066n2.rbf
* These two rbfs should be compied to /lib/firmware in the board's rootfs.
  * ghrd_10as066n2.pr_partition_0.rbf
  * alternate_persona.pr_partition_0.rbf

You will need to apply these two patches and compile the dtb's
and copy them to your Arria10 board at /lib/firmware.

 0001-socfpga_defconfig-enable-SYSID-driver.patch
 0002-arria10-dts-for-sysid-test.patch

