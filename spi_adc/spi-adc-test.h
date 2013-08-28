/*
UserInterface.h

UserInterface routines are used to read and write user data through the Arduino's 
serial interface.

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

#ifndef USERINTERFACE_H
#define USERINTERFACE_H

#include <stdint.h>

#define UI_BUFFER_SIZE 64

// io buffer
extern char ui_buffer[UI_BUFFER_SIZE];

// Read data from the serial interface into the ui_buffer buffer
uint8_t read_data();

// Read a float value from the serial interface
float read_float();

// Read an integer from the serial interface.
// The routine can recognize Hex, Decimal, Octal, or Binary
// Example:
// Hex:     0x11 (0x prefix)
// Decimal: 17
// Octal:   O21 (leading letter O prefix)
// Binary:  B10001 (leading letter B prefix)
int32_t read_int();

// Read a string from the serial interface.  Returns a pointer to the ui_buffer.
char *read_string();

// Read a character from the serial interface
int8_t read_char();

#endif  // USERINTERFACE_H
