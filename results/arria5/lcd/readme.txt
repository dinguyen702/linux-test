Interpretation of test results: 100% coverage

Run on RC1 with rebuilt kernel 3.9.0-00152-ge82076d

The only function that showed 0 calls is the probe function,
which was called to set up the lcd driver during kernel init.

lcd_probe:0
