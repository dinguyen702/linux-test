There are some rtc functions that are implemented in the Linux community driver
but not used in our implementation, as per our requirements.

The ds1339's interrupt is not connected so any functions having to do with
interrupt, alarms, and timers, including ds1307_work.

The ds1339 does not have nvram so all ds1307_nvram* functions are not
applicable.

The ds1339 is connected to i2c so the i2c_smbus_read/write* functions are used
and not the ds1307_read/write_block_data functions.

Any functions having to do with init/remove of the driver/class are not included
in this form of testing as the driver is already initialized before we start
ftracing and we can't ftrace into shutdown.

