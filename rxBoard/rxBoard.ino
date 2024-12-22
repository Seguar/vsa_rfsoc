/*
  Example Arduino Sketch for reading 90 bits from Serial
  and outputting them as 3 "streams" of 30 bits each via bit-banging.

  Hardware Setup:
    - CH340 or similar USB-UART connected to pins 0(RX) & 1(TX), or an alternative
      hardware serial on other boards.
    - Three digital pins for "SPI"-like clock and data lines.
      Or, if you want 3 separate data lines, define them below.
*/

#include <Arduino.h>

// --- Pin assignments (adjust as needed) ---
const int CLK_PIN  = 2;  // clock pin
const int DATA_PIN = 3;  // single data line (if you want 3 separate lines, define more pins)
#define SPI_Clk 5 //2
#define SPI_En 6  //3
#define SPI_D1 2  //4
#define SPI_D2 3  //5
#define SPI_D3 4  //6


#define LED_01 9  //5
#define LED_02 10  //6
int SPI_TX_THOLD = 20;  //mcs   
//int SPI_TX_THOLD = 20;  //ms  original 20 
bool data1[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
bool data2[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
bool data3[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
// If you want each 30-bit segment to go on a separate data pin, define them like this:
// const int DATA_PIN_1 = 3;
// const int DATA_PIN_2 = 4;
// const int DATA_PIN_3 = 5;

// For demonstration, we’ll output all bits on the same DATA_PIN in sequence.

void setup() {
  // Setup pins
  pinMode(SPI_Clk, OUTPUT);
  pinMode(SPI_En, OUTPUT);
  pinMode(SPI_D1, OUTPUT);
  pinMode(SPI_D2, OUTPUT);
  pinMode(SPI_D3, OUTPUT);

  pinMode(LED_01, OUTPUT);
  pinMode(LED_02, OUTPUT);
  
  digitalWrite(SPI_Clk, LOW);
  digitalWrite(SPI_En, LOW);
  digitalWrite(SPI_D1, LOW);
  digitalWrite(SPI_D2, LOW);
  digitalWrite(SPI_D3, LOW);
  
  
  digitalWrite(LED_01,LOW);
  digitalWrite(LED_02,LOW);

  // Setup serial
  Serial.begin(115200);

  // (Optional) Wait a moment for USB-serial
//  delay(1000);
}

void loop() {
  // Check if 12 bytes are available in serial buffer
  const int NUM_BYTES = 12;
//  Serial.println("Ready");
  if (Serial.available() >= NUM_BYTES) {
    
    // Read 12 bytes (90 bits total) into a buffer
    uint8_t buffer[NUM_BYTES];
    for (int i = 0; i < NUM_BYTES; i++) {
      buffer[i] = Serial.read();
    }
    storeBits(buffer, 30);

    sendBits(buffer, 30);
    Serial.println("Done");


  }
}

// Helper function to get a specific bit from the buffer
// bits are assumed MSB-first in each byte: 
//   buffer[0] = bits [0..7], buffer[1] = bits [8..15], etc.
uint8_t getBit(const uint8_t *buf, int bitIndex) {
  int byteIndex = bitIndex / 8;         // which byte
  int bitPos    = bitIndex % 8;         // which bit in that byte
  uint8_t b     = buf[byteIndex];
  int reversedPos = 7 - bitPos;
  return (b >> reversedPos) & 0x01;
}
// Normal order: data1[0] = bit(29), data1[1] = bit(28), etc.
void storeBits(const uint8_t *buf, int count) {
  for (int i = 0; i < count; i++) {
    // For the first 30-bit chunk:
    data1[i] = (bool) getBit(buf, 2 + i);

    // For the second 30-bit chunk:
    data2[i] = (bool) getBit(buf, 34 + i);

    // For the third 30-bit chunk:
    data3[i] = (bool) getBit(buf, 66 + i);
  }
}
// Sends `count` bits starting at bit index `startBit` via bit-bang
void sendBits(const uint8_t *buf, int count) {
  digitalWrite(SPI_En, HIGH);
  delayMicroseconds(SPI_TX_THOLD);
//  delay(SPI_TX_THOLD); 
  for (int i = 0; i < count; i++) {
    // Toggle clock
    digitalWrite(SPI_Clk, HIGH);
    // Drive DATA line
    digitalWrite(SPI_D1, data1[i] ? HIGH : LOW);
    digitalWrite(SPI_D2, data2[i]);
    digitalWrite(SPI_D3, data3[i]);

    // small delay for hold time
//    delay(SPI_TX_THOLD);
    delayMicroseconds(SPI_TX_THOLD);  
    digitalWrite(SPI_Clk, LOW);
//    delay(SPI_TX_THOLD);
    delayMicroseconds(SPI_TX_THOLD);
  }
  digitalWrite(SPI_Clk, LOW);
  digitalWrite(SPI_En, LOW);
  digitalWrite(SPI_D1, LOW);
  digitalWrite(SPI_D2, LOW);
  digitalWrite(SPI_D3, LOW);
}
