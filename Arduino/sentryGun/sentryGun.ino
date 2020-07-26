#include <Servo.h>

// Servos
Servo xServo;
Servo yServo;
Servo barrelServo;

// Pins
int barrelSpinPin = 8;
int xServoPin = 9;
int yServoPin = 10;
int barrelServoPin = 11;

// Min and Max servo angles
int xMin = 0;
int xMax = 180;
int xDefault = 90;

int yMin = 45;
int yMax = 110;
int yDefault = 90;

int barrelRestAngle = 180;
int barrelFiringAngle = 125;

// Recoil values
unsigned long firingStartTime = 0;
unsigned long firingCurrentTime = 0;
const long barrelPushDelay = 150;
const long barrelReturnDelay = 150;

unsigned long recoilStartTime = 0;
unsigned long recoilCurrentTime = 0;

// State
bool hasTarget = false;
bool isFiring = false;

void setup() {
  pinMode(barrelSpinPin, OUTPUT);
  xServo.attach(xServoPin);
  yServo.attach(yServoPin);
  barrelServo.attach(barrelServoPin);
  // Default position
  xServo.write(xDefault);
  yServo.write(yDefault);
  barrelServo.write(barrelRestAngle);
}

void loop() {
  if (Serial.available() > 0) {
    char incomingByte = Serial.read();
    if (incomingByte == 'X') {
      if (!hasTarget) {
        spinBarrel();
      }
      target();
      if (!hasTarget) {
        delay(15); // let the barrel spin a bit
      }
      hasTarget = true;
    } else if (incomingByte == 'L') {
      if (hasTarget) {
        stopBarrel();
      }
      hasTarget = false;
    }
  }
  fireIfPossible();
}

void spinBarrel() {
  digitalWrite(barrelSpinPin, HIGH);
}

void stopBarrel() {
  digitalWrite(barrelSpinPin, LOW);
}

void target() {
  unsigned int integerValueX = 0;
  while(1) {
    char incomingByte = Serial.read();
    if (incomingByte == -1) {
      continue;
    }
    if (isdigit(incomingByte) == false) {
      break;
    }
    integerValueX *= 10;
    integerValueX = ((incomingByte - 48) + integerValueX);
  }
  unsigned int integerValueY = 0;
  while(1) {
    char incomingByte = Serial.read();
    if (incomingByte == -1) {
      continue;
    }
    if (isdigit(incomingByte) == false) {
      break;
    }
    integerValueY *= 10;
    integerValueY = ((incomingByte - 48) + integerValueY);
  }
  xServo.write(integerValueX);
  yServo.write(integerValueY);
}

void fireIfPossible() {
  if (hasTarget && !isFiring) {
    firingStartTime = millis();
    isFiring = true;
  }

  if (!isFiring) {
    return;
  }

  firingCurrentTime = millis();
  int timePassed = firingCurrentTime - firingStartTime;

  if (timePassed < barrelPushDelay) {
    barrelServo.write(barrelFiringAngle);
  } else if ((timePassed + barrelPushDelay) < barrelReturnDelay) {
    barrelServo.write(barrelRestAngle);
  } else {
    isFiring = false;
  }
}
