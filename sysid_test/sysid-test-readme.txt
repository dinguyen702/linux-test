Sysid test

======================================================================================================================
12/13/2018 = stratix10 support

Support files are in the stratix10 subdirectory...

Set up for testing
* Apply the linux-test/sysid-test/stratix10/0001-arm64-dts-add-test-overlays-for-S10-PR-test.patch to the kernel.
* Rebuild the kernel, copying these three dtb files to your rootfs /lib/firmware:
  * base.dtb
  * persona0.dtb
  * persona1.dtb
* gunzip the linux-test/sysid-test/stratix10/persona*.rbf.gz files.
  * Copy the resulting persona*.rbf’s to your rootfs /lib/firmware.
* gunzip the linux-test/sysid-test/stratix10/s10_18p1_222_hps_pr.jic.gz file
  * Use the resulting s10_18p1_222_hps_pr.jic to update the board's qspi using Quartus Programmer.

**** When booting the board, run 'bridge enable' in u-boot before kernel boots ****
* Run the script on the board: sysid-test.sh

======================================================================================================================
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
