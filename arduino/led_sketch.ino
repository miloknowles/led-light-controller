#include &amp;lt;SPI.h&amp;gt;;
#include "Adafruit_BLE_UART.h";
#include &amp;lt;String.h&amp;gt;;
 
// defining the the BLE pins
#define ADAFRUITBLE_REQ 10
#define ADAFRUITBLE_RDY 2
#define ADAFRUITBLE_RST 9
 
// creating an instance of the UART to use for sending and receiving data
Adafruit_BLE_UART uart = Adafruit_BLE_UART(ADAFRUITBLE_REQ, ADAFRUITBLE_RDY, ADAFRUITBLE_RST);
//defining the LED color control pins
#define REDPIN 3
#define GREENPIN 6
#define BLUEPIN 5
 
//DEFINING ALL OF THE NEEDED CONSTANTS
 
int LED_CONTROL_STATE = 0; //determines what the LEDs do during the main loop
/* CONTROL STATES
* 0: solid color
* 1: slow fade
* 2: fast fade
* 3: cut effect
* 4: flash effect
*/
 
//values that are updated and sent to the LED strip to adjust color
int blueVal = 0;
int redVal = 0;
int greenVal = 0;
 
//constants used in special effects
int SLOW_FADESPEED = 10;
int FAST_FADESPEED = 5;
int cutSpeed = 500;
 
//color values for the cut effect
int redCutVals[] = {0, 0, 255, 0, 255, 120};
int greenCutVals[] = {0, 255, 0, 255, 0, 0};
int blueCutVals[] = {255,0, 120, 255, 0, 255};

void setup() {
	Serial.begin(9600);
	while(!Serial); // Leonardo/Micro should wait for serial init
	Serial.println(F("LED Control Board, Powered by Adafruit Bluefruit Low Energy nRF8001"));
	 
	// tell the UART what functions we intend to use for handling ACI events and RX
	uart.setRXcallback(rxCallback);
	uart.setACIcallback(aciCallback);
	uart.begin();
}

void aciCallback(aci_evt_opcode_t event) {
  switch(event) {
    case ACI_EVT_DEVICE_STARTED:
      Serial.println(F("Advertising started"));
      break;
    case ACI_EVT_CONNECTED:
      Serial.println(F("Connected!"));
      break;
    case ACI_EVT_DISCONNECTED:
      Serial.println(F("Disconnected or advertising timed out"));
      break;
    default:
      break;
    }
}

void rxCallback(uint8_t *buffer, uint8_t len) {
 
  // convert the incoming data into a string, to make it easier to work with
  String receivedString;
 
  for (int i=0; i&amp;lt;len;i++) {
    if ((char)buffer[i] != ' ' &amp;amp;&amp;amp; (char)buffer[i] != '\n') {
      receivedString += (char)buffer[i];
    }
  }
 
  //print out the string that was received
  Serial.println(receivedString);
 
  //count how many "dots" are in the received string, and record the indices of the dots
  int dotIndices[2];
  int dotCounter = 0;
  for (int c=0; c&amp;amp;amp;amp;amp;amp;lt;receivedString.length();c++) {
    if (receivedString[c] == '.') {
      dotIndices[dotCounter] = c;
      dotCounter++;
    }
  }
 
  //if the dotCounter is 2, this is an RGB packet
  if (dotCounter==2) {
    LED_CONTROL_STATE = 0; //set the state to solid color
 
    //since we've received a color packet, parse it into RGB values using the dot indices we found above
    int rVal = receivedString.substring(0,dotIndices[0]).toInt();
    int gVal = receivedString.substring(dotIndices[0]+1,dotIndices[1]).toInt();
    int bVal =    receivedString.substring(dotIndices[1]+1,receivedString.length()).toInt();
 
    //print out the RGB values to make sure they are sensible
    Serial.println(rVal);
    Serial.println(gVal);
    Serial.println(bVal);
    redVal = rVal;
    greenVal = gVal;
    blueVal = bVal;
  }
 
  // if we didn't receive a color command, check if the string could be a special command
  if (receivedString == "off") {
    Serial.println("off");
    greenVal = 0; blueVal = 0; redVal = 0;
	} else if (receivedString == "slowFade") {
    LED_CONTROL_STATE = 1;
 
  } else if (receivedString == "fastFade") {
    LED_CONTROL_STATE = 2;
 
  } else if (receivedString == "cut") {
    LED_CONTROL_STATE = 3;
  } else if (receivedString == "flash") {
    LED_CONTROL_STATE = 4;
	}
 
}

void loop() {
  // always poll the UART to see if there has been a state change or a received command
  uart.pollACI();
 
  // this switch has the LEDs do different things depending on the control state
  switch (LED_CONTROL_STATE) {
  case 0: //solid color
    analogWrite(REDPIN, redVal);
    analogWrite(GREENPIN, greenVal);
    analogWrite(BLUEPIN, blueVal);
    break;
 
  case 1: //slow fade
    int r,g,b;
    // fade from blue to violet
    for (r = 0; r&amp;lt;256; r++) {
      uart.pollACI();
      if (LED_CONTROL_STATE != 1) {break;}
      analogWrite(REDPIN, r);
      delay(SLOW_FADESPEED);
    }
 
    // fade from violet to red
    for (b = 255; b&amp;gt;0; b--) {
      uart.pollACI();
      if (LED_CONTROL_STATE != 1) {break;}
      analogWrite(BLUEPIN, b);
      delay(SLOW_FADESPEED);
    }
 
    // fade from red to yellow
    for (g = 0; g&amp;lt;256; g++) {
      uart.pollACI();
      if (LED_CONTROL_STATE != 1) {break;}
      analogWrite(GREENPIN, g);
      delay(SLOW_FADESPEED);
    }
 
    // fade from yellow to green
    for (r = 255; r&amp;gt;0; r--) {
       uart.pollACI();
       if (LED_CONTROL_STATE != 1) {break;}
       analogWrite(REDPIN, r);
       delay(SLOW_FADESPEED);
    }
 
    // fade from green to teal
    for (b = 0; b&amp;lt;256; b++) {
      uart.pollACI();
      if (LED_CONTROL_STATE != 1) {break;}
      analogWrite(BLUEPIN, b);
      delay(SLOW_FADESPEED);
    }
 
    // fade from teal to blue
    for (g = 255; g&amp;gt;0; g--) {
      uart.pollACI();
      if (LED_CONTROL_STATE != 1) {break;}
      analogWrite(GREENPIN, g);
      delay(SLOW_FADESPEED);
    }
 
  case 2: //fast fade
 
    // fade from blue to violet
    for (r = 0; r&amp;lt;256; r++) {
      uart.pollACI();
      if (LED_CONTROL_STATE != 2) {break;}
      analogWrite(REDPIN, r);
      delay(FAST_FADESPEED);
    }
 
    // fade from violet to red
    for (b = 255; b&amp;gt;0; b--) {
      uart.pollACI();
      if (LED_CONTROL_STATE != 2) {break;}
      analogWrite(BLUEPIN, b);
      delay(FAST_FADESPEED);
    }
 
    // fade from red to yellow
    for (g = 0; g&amp;lt;256; g++) {
      uart.pollACI();
      if (LED_CONTROL_STATE != 2) {break;}
      analogWrite(GREENPIN, g);
      delay(FAST_FADESPEED);
    }
 
    // fade from yellow to green
    for (r = 255; r&amp;gt;0; r--) {
      uart.pollACI();
      if (LED_CONTROL_STATE != 2) {break;}
      analogWrite(REDPIN, r);
      delay(FAST_FADESPEED);
    }
 
    // fade from green to teal
    for (b = 0; b&amp;lt;256; b++) {
      uart.pollACI();
      if (LED_CONTROL_STATE != 2) {break;}
      analogWrite(BLUEPIN, b);
      delay(FAST_FADESPEED);
    }
 
    // fade from teal to blue
    for (g = 255; g&amp;gt;0; g--) {
      uart.pollACI();
      if (LED_CONTROL_STATE != 2) {break;}
      analogWrite(GREENPIN, g);
      delay(FAST_FADESPEED);
    }
 
  case 3: //cut effect
    for (int c=0; c&amp;lt;6; c++) {
      uart.pollACI();
      if (LED_CONTROL_STATE != 3) {break;}
      analogWrite(REDPIN, redCutVals[c]);
      analogWrite(GREENPIN, greenCutVals[c]);
      analogWrite(BLUEPIN, blueCutVals[c]);
      delay(cutSpeed);
    }
 
  case 4: //flash effect (not implemented yet)
    break;
 
  default:
    break;
  }
}