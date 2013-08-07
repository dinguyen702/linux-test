Code coverage: 100%

Test run on rel_13.07_RC1 with kernel and device tree rebuilt (version 3.9.0-00154-g3e1a0ef)

Four functions didn't get any hits. Two are probe and remove, of course.  The other two
are at24_macc_read and at24_macc_write which allow other kernel code to access the eeprom
in theory, but are not used by any kernel code.

at24_macc_read:0
at24_macc_write:0
at24_probe:0
at24_remove:0
