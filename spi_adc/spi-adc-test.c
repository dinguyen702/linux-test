/*
 * DEMO934 ADC SPI testing utility (using spidev driver)
 *
 * Copyright (c) 2013  Altera
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License.
 *
 * Cross-compile with cross-gcc -I/path/to/cross-kernel/include
 */

#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include "LTC2422.h"

/* Global Constants */
const uint16_t LTC2422_TIMEOUT= 1000;  /* Set 1 second LTC2422 SPI timeout */

const float LTC2422_lsb = 4.7683761E-6;  /* The LTC2422 least significant bit value with 5V full-scale */

static void delay(unsigned int ms)
{
  usleep(ms*1000);
}

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

static int32_t spi_read_adc(void)
{
  float adc_voltage;
  int32_t adc_code;
  uint8_t adc_channel;
  /* Array for ADC data. Useful because you don't know which channel until the LTC2422 tells you. */
  int32_t  adc_code_array[2];       
  int8_t return_code;

  /* Throw out the stale data - CS goes low to start a conversion 		*/
  /* We read the ADC, but we'll overwrite it below. 							*/
  /* The ADC channel toggles on each read, so we'll do 3 reads 			*/
  LTC2422_read(&adc_channel, &adc_code, LTC2422_TIMEOUT);   
  delay(LTC2422_CONVERSION_TIME);

  /* At this point, we have good data, store it away in the array       */ 
  return_code = LTC2422_read(&adc_channel, &adc_code, LTC2422_TIMEOUT);   /* Get current data for both channels */
  adc_code_array[adc_channel] = adc_code;                                 /* Note that channels may return in any order, */
  delay(LTC2422_CONVERSION_TIME);

  /* Now read the next ADC channel */
  return_code = LTC2422_read(&adc_channel, &adc_code, LTC2422_TIMEOUT); 
  adc_code_array[adc_channel] = adc_code;
  
  /* Sometimes it is nice to see the raw data */
  printf("     ADC A (raw)): 0x%X\n", adc_code_array[0]);
  printf("     ADC B (raw)): 0x%X\n", adc_code_array[1]);

  /* The DC934A board connects VOUTA to CH1 */
  adc_voltage = LTC2422_voltage(adc_code_array[1], LTC2422_lsb);
  printf("     ADC A : %6.4f V\n", adc_voltage);

  /* The DC934A board connects VOUTB to CH0 */
  adc_voltage = LTC2422_voltage(adc_code_array[0], LTC2422_lsb);
  printf("     ADC B : %6.4f V\n", adc_voltage);


  return(return_code);
}

int main(int argc, char *argv[])
{
	int ret = 0;
		
	while(1)
	{
		ret = spi_read_adc();
		delay(1000);	 /* Delay 1000ms = 1sec */
	}
	
	return ret;
}
