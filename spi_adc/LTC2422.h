/*
LTC2422
2 Channel 20-Bit uPower No Latency Delta-Sigma ADC in MSOP-10

SPI DATA FORMAT (MSB First):

            Byte #1                           Byte #2                         Byte #3

Data Out :  !EOC CH SIG EXT D19 D18 D17 D16   D15 D14 D13 D12 D11 D10 D9 D8   D7 D6 D5 D4 D3 D2 D1 D0

!EOC : End of Conversion Bit (Active Low)
CH   : Channel Bit( 0-Channel 0, 1-Channel 1)
SIG  : Sign Bit (1-data positive, 0-data negative)
EXT  : Extended Input Range
Dx   : Data Bits

REVISION HISTORY
$Revision: 1334 $
$Date: 2013-03-02 15:18:26 -0800 (Sat, 02 Mar 2013) $

LICENSE
Permission to freely use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the below
copyright notice and this permission notice appear in all copies:

THIS SOFTWARE IS PROVIDED "AS IS" AND LTC DISCLAIMS ALL WARRANTIES
INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
EVENT SHALL LTC BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM ANY USE OF SAME, INCLUDING
ANY LOSS OF USE OR DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.

Copyright 2013 Nuvation Research Corporation
Copyright 2013 Linear Technology Corp. (LTC)
*/

#ifndef LTC2422_H
#define LTC2422_H

#define LTC2422_CONVERSION_TIME     137 // ms

// MISO timeout in ms
#define MISO_TIMEOUT 1000

// Returns the Data and Channel Number(0- channel 0, 1-Channel 1)
// Returns the status of the SPI read. 0=successful, 1=unsuccessful.
int8_t LTC2422_read(uint8_t *adc_channel, int32_t *code, uint16_t timeout);

// Returns the Calculated Voltage from the ADC Code
float LTC2422_voltage(uint32_t adc_code, float LTC2422_lsb);

// Calibrate the lsb
void LTC2422_cal_voltage(float LTC2422_reference_voltage, float *LTC2422_lsb);

#endif  //  LTC2422_H
