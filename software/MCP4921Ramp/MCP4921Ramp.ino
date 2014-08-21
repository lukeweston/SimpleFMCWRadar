// Basic demo of flexible, software-controlled ramp waveform synthesis (triangle wave in this case).
// Using an Arduino and Microchip MCP4921 12-bit SPI DAC.
// Ramp magnitude goes from 0 to VRef (single-ended), Vref is 5V in this case.

// Luke Weston, 2014
// License: Creative Commons attribution-noncommercial-sharealike - http://creativecommons.org/licenses/by-nc-sa/4.0/
// This license only applies to this file - other files (eg. my CERN OHL-licensed hardware files) may use different licence - see docs.

#define CS 10
#include "SPI.h"
word output = 0;
byte data = 0;

void setup()
{
  pinMode(CS, OUTPUT);
  SPI.begin();
  SPI.setBitOrder(MSBFIRST);
}
 
void loop()
{
  for (int i=0; i<=4095; i++)
  {
    outputValue = i;
    digitalWrite(CS, LOW);
    data = highByte(value);
    data = 0b00001111 & data;
    data = 0b00110000 | data;
    SPI.transfer(data);
    data = lowByte(value);
    SPI.transfer(data);
    digitalWrite(CS, HIGH);
  }
  delay(25);
  
  for (int i=4095; i>=0; --i)
  {
    outputValue = i;
    digitalWrite(CS, LOW);
    data = highByte(value);
    data = 0b00001111 & data;
    data = 0b00110000 | data;
    SPI.transfer(data);
    data = lowByte(value);
    SPI.transfer(data);
    digitalWrite(CS, HIGH);
  }
}
