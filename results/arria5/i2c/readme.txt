Coverage 100%

Tested on rel_13.07_RC1 with rebuilt kernel and device tree version 3.9.0-00152-ge82076d

The following functions were called 0 times (i2c-coverage.txt) for the following reasons:

i2c_dw_clear_int:0       = not used except if pci
i2c_dw_disable:0         = only used in probe and remove
i2c_dw_disable_int:0     = only used in probe
i2c_dw_enable:0          = not used in the kernel
i2c_dw_func:0            = called in probe
i2c_dw_init:0            = only used in probe and resume and under a certain error condition
i2c_dw_is_enabled:0      = not used except if pci
i2c_dw_read_comp_param:0 = only used in probe

