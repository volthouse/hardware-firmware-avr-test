@ECHO OFF
"C:\Program Files\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "E:\Temp\AlarmClock\labels.tmp" -fI -W+ie -I "C:\Users\azure\Documents\Firmware\alarmclock" -o "E:\Temp\AlarmClock\AlarmClock.hex" -d "E:\Temp\AlarmClock\AlarmClock.obj" -e "E:\Temp\AlarmClock\AlarmClock.eep" -m "E:\Temp\AlarmClock\AlarmClock.map" "E:\Temp\AlarmClock\AlarmClock.asm"
