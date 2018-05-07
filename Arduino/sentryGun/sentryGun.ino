#include <Servo.h>

Servo myservo;
const int buzzer = 11;

bool hasTarget = false;
bool isScanning = false;

void setup() {
  Serial.begin(9600);
  myservo.attach(9);
  pinMode(buzzer, OUTPUT);
  myservo.write(90);
  delay(1000); 
}

void loop() {
  if (isScanning == true) {
    scan();
    return;
  }
  if (Serial.available() > 0) {
    char incomingByte = Serial.read();
    if (incomingByte == 'L') {
      hasTarget = false;
      isScanning = true;
    } else if (incomingByte == 'T') {
      tone(buzzer, 800);
      delay(160);
      noTone(buzzer);
    } if (incomingByte == 'O') {
      tone(buzzer, 750);
      delay(160);
      noTone(buzzer);
    } else if (incomingByte == 'C') {
      tone(buzzer, 700);
      delay(160);
      noTone(buzzer);
    } else if (incomingByte == 'X') {
      if (hasTarget == false) {
        hasTarget = true;
        tone(buzzer, 900, 160);
      }
      setServoAngle();
    }
  }
}

void scan() {
  int angle = myservo.read();
  for (int i = angle; i<= 160; i++) {
    if (Serial.peek() != -1) {
      isScanning = false;
      return;
    }
    myservo.write(i);
    delay(15);
  }
  for (int i = 160; i>= 20; i--) {
    if (Serial.peek() != -1) {
      isScanning = false;
      return;
    }
    myservo.write(i);
    delay(15);
  }
}

void setServoAngle() {
  unsigned int integerValue = 0;
  while(1) {
    char incomingByte = Serial.read();
    if (incomingByte == -1) {
      continue;
    }
    if (isdigit(incomingByte) == false) {
      break;
    }
    integerValue *= 10;
    integerValue = ((incomingByte - 48) + integerValue);
  }
  myservo.write(integerValue);
}

