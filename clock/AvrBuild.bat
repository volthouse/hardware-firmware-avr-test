@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "C:\Users\azure\Documents\Firmware\clock\labels.tmp" -fI -W+ie -C V2E -o "C:\Users\azure\Documents\Firmware\clock\clock.hex" -d "C:\Users\azure\Documents\Firmware\clock\clock.obj" -e "C:\Users\azure\Documents\Firmware\clock\clock.eep" -m "C:\Users\azure\Documents\Firmware\clock\clock.map" "C:\Users\azure\Documents\Firmware\clock\clock.asm"