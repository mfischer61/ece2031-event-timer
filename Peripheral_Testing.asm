; LapTest.asm
; Tests TIMER lap functionality.
; Self-test results: Hex0 = 600D on pass.
;                    Hex0 = EEEE and Hex1 = failing test number on fail.
; After passing: Hex0 shows the live count; raising SW0 takes a lap,
; shown on Hex1 (low 8 bits).

ORG 0
	; Test 1: reset clears the lap register
	LOADI  1
	STORE  TestNum
	IN     Lap
	JNZ    Fail

	; Test 2: a lap captures the current count (timer reset, wait 2 s)
	LOADI  2
	STORE  TestNum
	OUT    Timer
Wait1:
	IN     Timer
	ADDI   -20
	JNEG   Wait1        ; wait until count >= 20 (2 s at 10 Hz)
	OUT    Lap          ; take a lap
	IN     Lap
	STORE  Lap1
	ADDI   -20
	JNEG   Fail         ; lap < 20: count wasn't captured
	LOAD   Lap1
	ADDI   -22
	JPOS   Fail         ; lap > 22: captured something other than the count

	; Test 3: taking a lap does NOT reset the timer
	LOADI  3
	STORE  TestNum
	IN     Timer
	SUB    Lap1
	JNEG   Fail         ; timer went below the lap value, so it was reset

	; Test 4: the lap register holds its value while the timer runs
	LOADI  4
	STORE  TestNum
Wait2:
	IN     Timer
	ADDI   -40
	JNEG   Wait2        ; wait until 4 s
	IN     Lap
	SUB    Lap1
	JNZ    Fail         ; lap changed without a new lap write

	; Test 5: a second lap captures a later time
	LOADI  5
	STORE  TestNum
	OUT    Lap
	IN     Lap
	STORE  Lap2
	SUB    Lap1
	ADDI   -15
	JNEG   Fail         ; second lap should be about 20 ticks later

	; Test 6: resetting the timer leaves the lap alone, and resets the count
	LOADI  6
	STORE  TestNum
	OUT    Timer
	IN     Lap
	SUB    Lap2
	JNZ    Fail         ; timer reset changed the lap register
	IN     Timer
	ADDI   -5
	JPOS   Fail         ; count should be near 0 right after a reset

Pass:
	LOAD   Good
	OUT    Hex0         ; show 600D for 2 seconds
	OUT    Timer
ShowPass:
	IN     Timer
	ADDI   -20
	JNEG   ShowPass

	; Interactive stopwatch: SW0 rising edge takes a lap
	LOADI  0
	STORE  PrevSw
	OUT    Hex1
	OUT    Timer
Live:
	IN     Timer
	OUT    Hex0         ; live count
	IN     Switches
	OUT    LEDs
	AND    Bit0
	STORE  CurSw
	SUB    PrevSw       ; 1 only when SW0 just went from down to up
	JPOS   DoLap
Continue:
	LOAD   CurSw
	STORE  PrevSw
	JUMP   Live
DoLap:
	OUT    Lap
	IN     Lap
	OUT    Hex1         ; lap time (low 8 bits)
	JUMP   Continue

Fail:
	LOAD   TestNum
	OUT    Hex1         ; which test failed
	LOAD   ErrCode
	OUT    Hex0
	JUMP   Fail

; Variables
TestNum:   DW 0
Lap1:      DW 0
Lap2:      DW 0
PrevSw:    DW 0
CurSw:     DW 0

; Useful values
Good:      DW 24589     ; &H600D
ErrCode:   DW -4370     ; &HEEEE
Bit0:      DW &B0000000001

; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Lap:       EQU 240      ; 0x0F0