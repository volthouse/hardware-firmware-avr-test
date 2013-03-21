@ECHO OFF
"C:\Program Files\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "E:\Temp\serial\labels.tmp" -fI -W+ie -o "E:\Temp\serial\serial.hex" -d "E:\Temp\serial\serial.obj" -e "E:\Temp\serial\serial.eep" -m "E:\Temp\serial\serial.map" "E:\Temp\serial\serial.asm"
