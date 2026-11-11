# Stopwatch Peripheral: Register Map

All times are in **ticks of 0.1 s** (10 Hz), the same unit as the original
Lab 8 timer. Registers are 16-bit unsigned. Unused bits read as 0.

| Addr  | Name      | Read                                | Write |
|-------|-----------|-------------------------------------|-------|
| 0x002 | COUNT     | ticks since last reset              | any value: COUNT = 0 |
| 0x0F0 | LAP       | last captured COUNT                 | any value: LAP = COUNT (COUNT keeps running) |
| 0x0F1 | CTRL      | bit 0: 1 = running, 0 = paused      | bit 0: 1 = run, 0 = pause |
| 0x0F2 | COUNTDOWN | ticks remaining, stops at 0         | load N and start; 0 cancels (no EXPIRED) |
| 0x0F3 | PERIOD    | current period                      | set TICK flag every N ticks; 0 = off |
| 0x0F4 | STATUS    | bit 0 EXPIRED, bit 1 TICK           | write 1 to a bit to clear it; 0 bits are unchanged |

## Behavior
- **Reset (KEY0):** COUNT = LAP = COUNTDOWN = PERIOD = 0, running, flags clear.
- **Pause** freezes COUNT, COUNTDOWN, PERIOD and the partial tick. Resume continues exactly.
- **EXPIRED** sets when COUNTDOWN goes 1 -> 0 and stays set until cleared or a new countdown is loaded.
- **TICK** sets every PERIOD ticks and stays set until cleared. If two periods pass before you clear it, you see one flag.
- If a flag sets in the same clock cycle that software clears it, the set wins (no lost events).
- **Range:** COUNT wraps after 6553.6 s. Values above 3276.7 s read as negative, so `JNEG` wait loops work up to about 54 minutes.
- The first tick after `OUT Timer` arrives within 0.1 s (same as the original timer).

## Idioms
Wait N tenths of a second:
```
	LOADI  50
	OUT    Cdown
Wait:	IN     Status
	AND    Bit0
	JZERO  Wait
```
Do something every 0.5 s while doing other work:
```
	LOADI  5
	OUT    Period
Loop:	IN     Status
	AND    Bit1
	JZERO  Other
	LOAD   Bit1
	OUT    Status      ; clear TICK
	CALL   Periodic
Other:	...
	JUMP   Loop
```
Short vs. long press (stopwatch keeps running):
```
	OUT    Lap         ; on press
	...
	IN     Lap         ; on release
	STORE  PressT
	IN     Timer
	SUB    PressT      ; AC = press length in ticks
	ADDI   -10
	JNEG   ShortPress  ; under 1.0 s
```

## Hardware notes
All registers run on the 10 MHz SCOMP clock (CLOCK must be wired to `clk_10MHz`).
IO_WRITE and IO_READ are synchronous enables. The peripheral drives IO_DATA only
when IO_READ = 1 and IO_ADDR is one of its six addresses.
