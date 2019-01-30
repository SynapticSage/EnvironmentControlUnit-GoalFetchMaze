/*

GOALMAZE PERIPHERAL MOTOR AND LIGHT SYSTEM
------------------------------------------

This file contains functionality for
  (A) Raising/lowering maze barriers
  (B) Lights
    1. Dimming
    2. Color change

*/

// include the SPI library:
#include <SPI.h>

/////////////////////////////////
// MOTOR  Settings
/////////////////////////////////
// L9958 slave select pins for SPI
#define SS_M4 14
#define SS_M3 13
#define SS_M2 12
#define SS_M1 11
int mSS[4] = {SS_M1, SS_M2, SS_M3, SS_M4};
// L9958 DIRection pins
#define DIR_M1 2
#define DIR_M2 3
#define DIR_M3 4
#define DIR_M4 7
int mDIR[4] = {DIR_M1, DIR_M2, DIR_M3, DIR_M4};
// L9958 PWM pins
#define PWM_M1 9
#define PWM_M2 10    // Timer1
#define PWM_M3 5
#define PWM_M4 6     // Timer0
int mPWM[4] = {PWM_M1, PWM_M2, PWM_M3, PWM_M4};

// Pins used to command the barrier to flip
int controlPins[] = {30,31,32,33};

// Shortcut functions for up and down
#define UP 1
#define DOWN 0

// L9958 Enable for all 4 motors
#define ENABLE_MOTORS 8

int     pwm1, pwm2, pwm3, pwm4;
boolean dir1, dir2, dir3, dir4;

// Motor Functions
void motorsOff();
void motorMove(int motor, int dir, int speed);
void motorFlip(int motor);
void generalPattern();
void initializeMotor(int motor, unsigned int configWord);
int motorSpeed(int motor, int direction);

// Digital potentiometer settings
//////////////////////////////////
byte address = 0x00;
int CS= 10;

// Digital motor state trackers
int motorStates[] = {DOWN, DOWN, DOWN, DOWN};

// Whether or not to execute movements in parallel or series
boolean parallel = true;


/* SETUP */
/////////////////////////////////
void setup() { 
  
  /*
  PART 1: Motor pin mode setup!
  */
  unsigned int configWord;

  // put your setup code here, to run once:
  for (int i = 0; i < 4; i++)
  {
    pinMode(mSS[0], OUTPUT); 
    digitalWrite(mSS[0], LOW);  // HIGH = not selected
  }

  // L9958 DIRection pins: Q...how are direction pins different from PWM?
  for (int i = 0; i < 4; i++)
    pinMode(mDIR[i], OUTPUT);
    
  // L9958 PWM pins: Q...how are PWM different from direction?
  for (int i = 0; i<4; i++)
  {
    pinMode(mPWM[0], OUTPUT);  
    digitalWrite(mPWM[0], LOW);
  }

  // L9958 Enable for all 4 motors
  pinMode(ENABLE_MOTORS, OUTPUT); 
  motorOff(true);
  
  /*
  PART 2: Transfer configurations to each motor
  */

  configWord = 0b0000010000001100;
  SPI.begin();
  SPI.setBitOrder(LSBFIRST);
  SPI.setDataMode(SPI_MODE1);  // clock pol = low, phase = high

  // Initialize motors
  for (int i = 0; i<4; i++)
    initializeMotor(i, configWord);
    
  for (int motor = 0; motor < 4; motor++)
  {
    pinMode(     controlPins[motor], INPUT_PULLUP);
    digitalWrite(controlPins[motor], HIGH);
  }

  //Set initial actuator settings to pull at 0 speed for safety
  dir1 = 0; dir2 = 0; dir3 = 0; dir4 = 0; // Set direction
  pwm1 = 0; pwm2 = 0; pwm3 = 0; pwm4 = 0; // Set speed (0-255)
  

  motorOff(false);
  Serial.begin(9600);
} // End setup

/* LOOP */
void loop() 
{
  //Serial.println("Loop");
    // CONSOLE COMMANDS
    bool serialProcessed = false;
    while (Serial.available() > 0)
    {
      
      serialProcessed = true;
      char incomingByte = Serial.read();
      Serial.println("Got bit :");
      Serial.println(incomingByte);
      switch (incomingByte)
      {
        case '1' :
        motorFlip(0);
        break;
        case '2' :
        motorFlip(1);
        break;
        case '3' :
        motorFlip(2);
        break;
        case '4' :
        motorFlip(3);
        break;
        case 'p' :
        toggleParallel();
        case 'g' :
        generalPattern();
        break;
        Serial.println("Pattern not recognized");
      }
      Serial.flush(); // Throw out anything not handled
    }
    if (parallel && serialProcessed)
    {
      delay(4000);
      //motorOff(false);
      for (int motor = 0; motor < 4; motor++)
      {
        //digitalWrite(mDIR[motor], 0);
        analogWrite( mPWM[motor], 0);
      }
      //motorOff(true);
    }
    
    
    //////////////////////////////////////
    // Commands from the ECU
    //////////////////////////////////////
    //Comands that come in along the pins
    bool flipHappened = false;
    for (int i = 0; i < 4; i++)
      if (digitalRead(controlPins[i]) == LOW)
      {
        motorFlip(i);
        flipHappened = true;
      }
    if (parallel && flipHappened)
    {
      delay(4000);
      //motorOff(false);
      for (int motor = 0; motor < 4; motor++)
      {
        //digitalWrite(mDIR[motor], 0);
        analogWrite( mPWM[motor], 0);
      }
      //motorOff(true);
    }
      
    
  

}//end void loop

/////////////////////////////////
// LOW LEVEL MOTOR FUNCTIONS ////
/////////////////////////////////
/*
Function: motorMove
Purpose:  Commands one of the motors to move
          in a direction at a certain speed.
Input:    motor - which motor 0...3
          dir   - direction {0:down, 1:up}
          speed - {0:slowest .. 255:fastest}
*/
void motorMove(int motor, int dir, int speed)
{
  // Move motor
  Serial.print("\nMoving ");
  Serial.print(motor);
  Serial.print(" in direction ");
  Serial.print(dir);
  Serial.print(" with speed ");
  Serial.print(speed);
  Serial.print("\n");
 // motorOff(false);
  digitalWrite(mDIR[motor], dir);
  analogWrite( mPWM[motor], speed);
  if (!parallel)
  {
    delay(3000);
    digitalWrite(mDIR[motor], 0);
    analogWrite( mPWM[motor], 0);
  }
 // motorOff(true);
  // Store state
  motorStates[motor] = dir;
}

void motorFlip(int motor)
{
  int speed;
  if (motorStates[motor] == UP)
    motorStates[motor] = DOWN;
  else
    motorStates[motor] = UP;
  speed = motorSpeed(motor, motorStates[motor]);
  motorMove( motor, motorStates[motor], speed );
}

void toggleParallel()
{
  Serial.print("\nToggling parllel mode");
  parallel = !parallel;
  if (parallel)
    Serial.print("on\n");
  else
    Serial.print("off\n");
}
/*
Function: motorOff
Purpose:  enable or disable motor output
            true - off
            false- on
*/
void motorOff(bool val)
{
  if (val == true)
  {
    Serial.println("deactivating motors");
    digitalWrite(ENABLE_MOTORS, HIGH);  // HIGH = disabled
  }
  else
  {
    Serial.println("activating motors");
    digitalWrite(ENABLE_MOTORS, LOW); 
  }
}
void initializeMotor(int motor, unsigned int configWord)
{
  digitalWrite(mSS[motor], LOW);
  SPI.transfer(lowByte(configWord));
  SPI.transfer(highByte(configWord));
  digitalWrite(mSS[motor], HIGH);
}

//////////////////////////////////////
// LOW LEVEL DIGITAL POT FUNCTIONS ////
//////////////////////////////////////
int digitalPotWrite(int value)
{
  digitalWrite(CS, LOW);
  SPI.transfer(address);
  SPI.transfer(value);
  digitalWrite(CS, HIGH);
}

//////////////////////////////////
// General Movement Patterns  ////
//////////////////////////////////
void generalPattern()
{
    Serial.println("General motions");
    // motorMove(1,UP,255);
    // motorMove(2,DOWN,128);
    // motorMove(3,UP,255);
    // motorMove(4,DOWN,128);

    // delay(5000); // wait once all four motors are set

    dir1 = DOWN;
    pwm1 = 128;
    digitalWrite(DIR_M1, dir1);
    analogWrite( PWM_M1, pwm1);

    dir2 = UP;
    pwm2 = 255;
    digitalWrite(DIR_M2, dir2);
    analogWrite( PWM_M2, pwm2);

    dir3 = DOWN;
    pwm3 = 128;
    digitalWrite(DIR_M3, dir3);
    analogWrite( PWM_M3, pwm3);

    dir4 = DOWN;
    pwm4 = 255;
    digitalWrite(DIR_M4, dir4);
    analogWrite( PWM_M4, pwm4);

    delay(5000); 
}

//////////////////////////////////
// Customizing motors         ////
//////////////////////////////////
/*
  function: motorSpeed
  purpose: Customizing rise and fall times of
  specific motors
  input: 
    motor (int), 
      integer specifying the identity of a motor of interest
    direction (int)
      integer specifying the direction a motor of interest will
      move (up/down)
/*/
int motorSpeed(int motor, int direction)
{
  int speed = 0;
  switch (motor)
  {
    case 0:
    if (direction == UP)
      speed = 128;
    else
      speed = 256;
    break;
    case 1:
    if (direction == UP)
      speed = 128;
    else
      speed = 256;
    break;
    case 2:
    if (direction == UP)
      speed = 128;
    else
      speed = 256;
    break;
    case 3:
    if (direction == UP)
      speed = 128;
    else
      speed = 256;
    break;
  }
  
  return speed;
}




