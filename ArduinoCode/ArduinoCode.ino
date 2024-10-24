#include <SparkFun_Bio_Sensor_Hub_Library.h>
#include <Wire.h>

#define DEF_ADDR 0x55

// Buzzer
const int buzzerPin = 12;

// Bio Sensor
const int resPin = 4;
const int mfioPin = 5;
// Possible widths: 69, 118, 215, 411us
int width = 411;
// Possible samples: 50, 100, 200, 400, 800, 1000, 1600, 3200 samples/second
int samples = 50;
int pulseWidthVal;
int sampleVal;
SparkFun_Bio_Sensor_Hub bioHub(resPin, mfioPin);
bioData body;

void setup() {
  // Setup Arduino communication (I2C & Serial)
  Serial.begin(115200);
  Serial.println("Initializing");
  delay(500);
  Wire.begin();

  // Setup buzzer
  pinMode(buzzerPin, OUTPUT);

  // Setup error bit for Processing
  int errorsFound = 0;

  // Configure Bio Sensor
  int error = bioHub.begin();
  if (!error) {
    Serial.println("Sensor started.");
  } else {
    errorsFound++;
    Serial.println("Error starting sensor.");
    Serial.print("Error: ");
    Serial.println(error);
  }
  delay(500);
  // Set Bio Sensor mode
  error = bioHub.configSensorBpm(MODE_ONE);
  if (!error) {
    Serial.println("Sensor configured.");
  } else {
    errorsFound++;
    Serial.println("Error configuring sensor.");
    Serial.print("Error: ");
    Serial.println(error);
  }
  // Set Bio Sensor communication pulse width
  error = bioHub.setPulseWidth(width);
  if (!error) {
    Serial.println("Pulse Width Set.");
  } else {
    errorsFound++;
    Serial.println("Could not set Pulse Width.");
    Serial.print("Error: ");
    Serial.println(error);
  }
  pulseWidthVal = bioHub.readPulseWidth();
  Serial.print("Pulse Width: ");
  Serial.println(pulseWidthVal);
  // Set Bio Sensor sample rate
  error = bioHub.setSampleRate(samples);
  if (!error) {
    Serial.println("Sample Rate Set.");
  } else {
    errorsFound++;
    Serial.println("Could not set Sample Rate!");
    Serial.print("Error: ");
    Serial.println(error);
  }
  // Communicate Bio Sensor errors to Processing, a 1 numeric character means there were errors, a character with the ascii value of 1 means no errors
  Serial.write(errorsFound != 0 ? '1' : 1);
  Serial.write('\n');
  // Take a second to sync with Processing and read the bio sensor settings
  delay(2000);

  
  // Code for testing with broken sensor
  randomSeed(analogRead(0));
}

// Code for reading the indicator to play the buzzer
int incomingByte = 0;

// Code for testing with broken sensor
int zone1Min = 60;
int zone2Min = 90;
int zone3Min = 120;
int zone4Min = 150;
int zone5Min = 180;
int hrMax = 198;
int zone = 1;
long randNumber;
long base = zone1Min;

void loop() {
  //body = bioHub.readSensorBpm();
  //Serial.println(String(body.irLed) + "," + String(body.redLed) + "," + String(body.heartRate) + "," + String(body.confidence) + "," + String(body.oxygen) + "," + String(body.status));
  //delay(50);

  //Code for testing with broken sensor
  randNumber = random(250);
  if (randNumber == 0) {
    zone = random(5) + 1;
  }
  if (zone == 1) {
    base = zone1Min;
  } else if (zone == 2) {
    base = zone2Min;
  } else if (zone == 3) {
    base = zone3Min;
  } else if (zone == 4) {
    base = zone4Min;
  } else if (zone == 5) {
    base = zone5Min;
  }
  int randHR = random(30) + base;
  Serial.println("0,0," + String(randHR) + ",95,99,3");
  delay(50);

  if (Serial.available() > 0) {
    incomingByte = Serial.read();
    if (incomingByte == 1) {
      // Play beep
      tone(buzzerPin, 333);
      delay(50);
      noTone(buzzerPin);
      delay(50);
      tone(buzzerPin, 333);
      delay(50);
      noTone(buzzerPin);
    }
    while (Serial.available() > 0) {
      Serial.read();
    }
  }
}
