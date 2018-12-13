Sysid test

12/13/2018 = stratix10 support

Support files are in the stratix10 subdirectory...
* The jic.gz file has to be gunzipped and updated into the board's qspi using Quartus Programmer.
* The patch to add the dts's has to be applied to the kernel (and built).
* The persona*.rbf.gz's need to be gunzipped and added to board rootfs's /lib/firmware directory
When booting the board, run 'bridge enable' in u-boot before kernel boots

7/18/2017

This test is based on the A10 PR reference design which can be found on RocketBoards at:

https://rocketboards.org/foswiki/Projects/Arria10SoCHardwareReferenceDesignThatDemostratesPartialReconfiguration#A_42Release_Contents_42

These 3 rbf's were downloaded from that build:
* This rbf should alred be on the booting sd card's fat partition as the image that uboot will use:
  * ghrd_10as066n2.rbf
* These two rbfs should alread be in /lib/firmware in the board's rootfs:
  * persona0.rbf
  * persona1.rbf

You will need to apply these two patches:

  0001-socfpga_defconfig-enable-SYSID-driver.patch
  0002-arria10-Device-Tree-overlays-for-sysid-test.patch

And copy the resulting dtb's to your Arria10 board at /lib/firmware.


================================================================================
Note that additional bits came from Matthew's GSRD test.  Hopefully you won't need
to go there:

https://sj-arc.altera.com/tools/soceds/17.0/current.linux64/linux64/not_shipped/examples/hardware/a10_soc_devkit_sdmmc_pr/output_files/
