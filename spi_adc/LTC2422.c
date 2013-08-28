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

#include <stdint.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/spi/spidev.h>
#include "LTC2422.h"

#include <stdio.h>

#define SPI_CLOCK_RATE  200000

#define SPI_DATA_CHANNEL_OFFSET 22
#define SPI_DATA_CHANNEL_MASK   (1 << SPI_DATA_CHANNEL_OFFSET)

// Bits/word or transaction size. Should really be 24 bits but max of 16 bits is
// currently supported by HPS SPI peripheral/driver.
#define SPI_DATA_BPW    16
//#define SPI_DATA_BPW    24
//#define SPI_DATA_BPW    32

// Returns the Data and Channel Number(0- channel 0, 1-Channel 1)
// Returns the status of the SPI read. 0=successful, 1=unsuccessful.
// Timeout value is ignored.
int8_t LTC2422_read(uint8_t *adc_channel, int32_t *code, uint16_t timeout)
{
  int fd;
  int ret;
  int32_t value;
  uint8_t buffer[4];

  struct spi_ioc_transfer tr = {
      .tx_buf = 0,                      // No data to send
      .rx_buf = (unsigned long) buffer, // Where to store the received data
      .delay_usecs = 0,                 // No delay
      .speed_hz = SPI_CLOCK_RATE,       // SPI clock speed (in Hz)
      .bits_per_word = SPI_DATA_BPW,    // Word/transaction size.
      .len = (SPI_DATA_BPW / 8)         // Number of bytes to transfer.
  };

  // Open the device
  fd = open("/dev/spidev0.0", O_RDWR);
  if (fd < 0)
  {
    return (1);
  }

  // Perform the transfer
  ret = ioctl(fd, SPI_IOC_MESSAGE(1), &tr);
  if (ret < 1)
  {
    close(fd);
    return (1);
  }

  // Close the device
  close(fd);
  
  // Assemble the returned code
#if SPI_DATA_BPW == 16
  value  = buffer[1] << 16;
  value |= buffer[0] << 8;
  // No lower 8-bits due to 16 bit restriction.
#elif SPI_DATA_BPW == 24
  value  = buffer[2] << 16;
  value |= buffer[1] << 8;
  value |= buffer[0];
#elif SPI_DATA_BPW == 32
  value  = buffer[3] << 16;
  value |= buffer[2] << 8;
  value |= buffer[1];
#else
#error Unsupported size for SPI_DATA_BPW.
#endif

  // Determine the channel number
  *adc_channel = (value & SPI_DATA_CHANNEL_MASK) ? 1 : 0;

  // Return the code
  *code = value;

  return(0);
}

// Returns the Calculated Voltage from the ADC Code
float LTC2422_voltage(uint32_t adc_code, float LTC2422_lsb)
{
  float adc_voltage;
  if (adc_code & 0x200000)
  {
    adc_code &= 0xFFFFF;                                           // Clears Bits 20-23
    adc_voltage=((float)adc_code)*LTC2422_lsb;
  }
  else
  {
    adc_code &= 0xFFFFF;                                           // Clears Bits 20-23
    adc_voltage = -1*((float)adc_code)*LTC2422_lsb;
  }
  return(adc_voltage);
}

// Calibrate the lsb
void LTC2422_cal_voltage(float LTC2422_reference_voltage, float *LTC2422_lsb)
{
  *LTC2422_lsb = LTC2422_reference_voltage/(1048575);                 // ref_voltage /(2^20-1)
}


