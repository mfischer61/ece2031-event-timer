          ; Demo.asm -- Stopwatch Peripheral video demo
; Three time-based tasks share one polling loop, with no software timing math: 
; 1. Periodic: one LED bounces a step every 0.3 s (PERIOD, STATUS bit 1)
; 2. Stopwatch: Hex0 shows the count (COUNT)
          ; SW0 up = lap, shown on Hex1 (LAP)
          ; SW1 up = pause everything (CTRL)
          ; SW3 up = reset the stopwatch (COUNT write)
; 3. Countdown: SW2 up = start 5.0 s, Hex1 shows time left (COUNTDOWN)
          ; at 0 all LEDs flash (STATUS bit 0)
          ; All times are in tenths of a second. Hex shows them in hex.
          
          ORG 0
          LOADI 3
          OUT Period ; TICK flag every 0.3 s
          LOADI 0
          OUT Timer
          OUT Hex1
          STORE PrevSw
          STORE LastLap
          STORE Dir
          LOADI 1
          STORE Pattern
          
Loop: 
; ---- task 1: periodic animation ----
          IN Status
          AND Bit1
          JZERO NoTick
          LOAD Bit1
          OUT Status ; clear TICK
          CALL StepLED
NoTick: 
; ---- task 3: countdown finished? ----
          IN Status
          AND Bit0
          JZERO NoExpire
          LOAD Bit0
          OUT Status ; clear EXPIRED
          LOADI 1023 ; &H3FF = all ten LEDs
          OUT LEDs ; flash until the next animation step
NoExpire: 
; ---- switches: find bits that just went 0 -> 1 ----
          IN Switches
          STORE CurSw
          XOR PrevSw
          AND CurSw
          STORE Rise
          LOAD CurSw
          STORE PrevSw
          
          LOAD Rise
          AND Bit0
          JZERO NoLap
OUT Lap ; SW0: take a lap
          IN Lap
          STORE LastLap
NoLap: 
          LOAD Rise
          AND Bit2
          JZERO NoStart
          LOADI 50
OUT Cdown ; SW2: start a 5.0 s countdown
NoStart: 
          LOAD Rise
          AND Bit3
          JZERO NoReset
OUT Timer ; SW3: reset the stopwatch
NoReset: 
          LOAD CurSw
          AND Bit1
          JZERO Running
          LOADI 0
OUT Ctrl ; SW1 up: pause all time
          JUMP Display
Running: 
          LOADI 1
OUT Ctrl ; SW1 down: run
          
Display: 
          IN Timer
          OUT Hex0 ; stopwatch
          IN Cdown
          JZERO ShowLap ; no countdown running
          OUT Hex1 ; time left
          JUMP Loop
ShowLap: 
          LOAD LastLap
          OUT Hex1
          JUMP Loop
          
; StepLED: move the lit LED one place, bouncing at both ends
StepLED: 
          LOAD Dir
          JNZ GoRight
          LOAD Pattern
          SHIFT 1
          STORE Pattern
          AND Bit9
          JZERO ShowLED
          LOADI 1
          STORE Dir ; reached LED9, turn around
          JUMP ShowLED
GoRight: 
          LOAD Pattern
          SHIFT -1
          STORE Pattern
          AND Bit0
          JZERO ShowLED
          LOADI 0
          STORE Dir ; reached LED0, turn around
ShowLED: 
          LOAD Pattern
          OUT LEDs
          RETURN
          
          ; Variables
PrevSw: DW 0
CurSw: DW 0
Rise: DW 0
LastLap: DW 0
Pattern: DW 1
Dir: DW 0
          
          ; Useful values
Bit0: DW &B0000000001
Bit1: DW &B0000000010
Bit2: DW &B0000000100
Bit3: DW &B0000001000
Bit9: DW &B1000000000
          
          ; IO address constants
Switches: EQU 000
LEDs: EQU 001
Timer: EQU 002
Hex0: EQU 004
Hex1: EQU 005
Lap: EQU 240 ; 0x0F0
Ctrl: EQU 241 ; 0x0F1
Cdown: EQU 242 ; 0x0F2
Period: EQU 243 ; 0x0F3
Status: EQU 244 ; 0x0F4
          