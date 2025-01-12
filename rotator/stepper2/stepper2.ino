// демо - основные возможности библиотеки

#include <GyverStepper2.h>
//GStepper2<STEPPER2WIRE> stepper(3200, 3, 6, 8); // 0.9
GStepper2<STEPPER2WIRE> stepper(1600, 3, 6, 8); // 1.8

// мотор с драйвером ULN2003 подключается по порядку пинов, но крайние нужно поменять местами
// то есть у меня подключено D2-IN1, D3-IN2, D4-IN3, D5-IN4, но в программе поменял 5 и 2

// создание объекта
// steps - шагов на один оборот вала (для расчётов с градусами)
// step, dir, pin1, pin2, pin3, pin4 - любые GPIO
// en - пин отключения драйвера, любой GPIO
//GStepper<STEPPER2WIRE> stepper(steps, step, dir);                   // драйвер step-dir
//GStepper<STEPPER2WIRE> stepper(steps, step, dir, en);               // драйвер step-dir + пин enable
//GStepper<STEPPER4WIRE> stepper(steps, pin1, pin2, pin3, pin4);      // драйвер 4 пин
//GStepper<STEPPER4WIRE> stepper(steps, pin1, pin2, pin3, pin4, en);  // драйвер 4 пин + enable
//GStepper<STEPPER4WIRE_HALF> stepper(steps, pin1, pin2, pin3, pin4);     // драйвер 4 пин полушаг
//GStepper<STEPPER4WIRE_HALF> stepper(steps, pin1, pin2, pin3, pin4, en); // драйвер 4 пин полушаг + enable

void setup() {
  Serial.begin(9600);
  // режим поддержания скорости

  //  stepper.setSpeedDeg(80);  // в градусах/сек
  //
  //  // режим следования к целевй позиции
  ////  stepper.setRunMode(FOLLOW_POS);
  //
  //  // можно установить позицию
  ////  stepper.setTargetDeg(-360);  // в градусах
  //
  //  // установка макс. скорости в градусах/сек
  stepper.setMaxSpeedDeg(1600);
  //
  //  // установка макс. скорости в шагах/сек
  //  stepper.setMaxSpeed(400);

  // установка ускорения в градусах/сек/сек
  //  stepper.setAccelerationDeg(300);


  // отключать мотор при достижении цели
  //  stepper.autoPower(true);

  // включить мотор (если указан пин en)
  stepper.enable();
}
int32_t pos = 0;
static bool dir = 1;
void loop() {
  // просто крутим туды-сюды
  //  if (!stepper.tick()) {
  //////    static bool dir;
  //////    dir = !dir;
  ////////    stepper.setTarget(dir ? -1600 : 1600);
  //    stepper.setTargetDeg(pos, RELATIVE);
  //  }
  //if (!stepper.tick()) {
  
  if (!stepper.tick()) {
    if (Serial.available() > 0) {
      char incoming = Serial.read();
      switch (incoming) {
        case 'w': stepper.reset(); stepper.enable();
          break;
        case 'a': pos = -1; stepper.setTargetDeg(pos, RELATIVE);
          break;
        case 'q': pos = -10; stepper.setTargetDeg(pos, RELATIVE);
          break;
        case 's': stepper.stop();  stepper.disable();
          break;
        case 'd': pos = 1; stepper.setTargetDeg(pos, RELATIVE);
          break;
        case 'e': pos = 10; stepper.setTargetDeg(pos, RELATIVE);

          break;
        case 'r': pos = -90; stepper.setTargetDeg(pos, RELATIVE);
          break;
        case 'f': pos = 90; stepper.setTargetDeg(pos, RELATIVE);
          break;
        case 'o':
          while (Serial.available() == 0) {
            // Wait here until number arrives
          }
          // Read until newline (or timeout)
          String posStr = Serial.readStringUntil('\n');

          // Convert the string to an integer
          pos = posStr.toInt();

          // Send to stepper in ABSOLUTE mode
          stepper.setTargetDeg(pos, ABSOLUTE);

          // Print out the parsed value for debugging
          //        Serial.print("Received angle: ");

          break;
      }
    }
    stepper.tick();
  }
  if (stepper.ready()) {
    Serial.println(pos);
  }
  //  }
}
