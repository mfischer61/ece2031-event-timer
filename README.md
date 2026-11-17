# Stopwatch Peripheral for SCOMP (ECE 2031)

A memory-mapped timer peripheral in VHDL for SCOMP, the 16-bit teaching processor in Georgia Tech's ECE 2031, running on a Terasic DE10-Standard (Cyclone V) FPGA. It adds lap capture, pause/resume, a hardware countdown and a periodic tick flag, so programs can run several time-based tasks at once without any timing math in software. Programs written for the original Lab 8 timer at `0x002` still work unchanged.

<!-- DEMO VIDEO: drag an .mp4 into this README on GitHub, or link a YouTube/Drive video here -->
> 🎥 **Demo video:** _coming soon_

## Features

| | |
|---|---|
| **Stopwatch** | Free-running count in 0.1 s ticks, compatible with the Lab 8 timer |
| **Lap** | Capture the current count without stopping the clock |
| **Pause / resume** | Freezes every timer in the peripheral, including the partial tick, and resumes exactly |
| **Countdown** | Load N ticks; the `EXPIRED` flag sets when it reaches 0 |
| **Periodic tick** | `TICK` flag every N ticks for scheduling recurring work |
| **Safe flags** | Write-1-to-clear status bits; a set that lands on the same cycle as a clear wins, so no event is lost |
| **Self-test** | 16 on-board checks: `600D` on the display means all pass |

## Register map

All values are 16-bit, in ticks of 0.1 s. Full contract with timing rules and code idioms: [REGISTER_MAP.md](REGISTER_MAP.md).

| Addr | Name | Read | Write |
|---|---|---|---|
| `0x002` | COUNT | ticks since reset | any value resets COUNT |
| `0x0F0` | LAP | last captured COUNT | any value captures COUNT |
| `0x0F1` | CTRL | bit 0: running | bit 0: 1 run, 0 pause |
| `0x0F2` | COUNTDOWN | ticks left | load N and start; 0 cancels |
| `0x0F3` | PERIOD | current period | TICK every N ticks; 0 = off |
| `0x0F4` | STATUS | bit 0 EXPIRED, bit 1 TICK | write 1 to clear a bit |

## Demo program

`Demo.asm` runs three tasks in one polling loop, each driven by a different hardware feature:

1. **Animation:** an LED bounces one step every 0.3 s (PERIOD + TICK).
2. **Stopwatch:** HEX0 shows the running count. SW0 takes a lap (shown on HEX1), SW1 pauses everything, SW3 resets.
3. **Countdown:** SW2 starts 5.0 s, HEX1 shows time left, and all LEDs flash at zero (COUNTDOWN + EXPIRED).

<!-- PHOTO: board running the demo -->

## Verification

`Peripheral_Testing.asm` runs 16 self-checks on the board: lap capture and hold, reset behavior, pause and resume (count holds, then continues without resetting), countdown load, expiry and cancel, W1C flag clearing, and periodic tick rate and disable. HEX0 shows `600D` when everything passes; on a failure HEX0 shows `EEEE` and HEX1 the failing test number.

## Design notes

- Everything is synchronous to the 10 MHz SCOMP clock. A prescaler makes a one-clock tick enable every 1,000,000 cycles (10 Hz); `IO_READ` and `IO_WRITE` are used only as enables, never as clocks.
- The peripheral drives the shared `IO_DATA` bus only while `IO_READ` is high and the address matches one of its six registers.
- COUNT wraps after 6553.6 s. Values past 3276.7 s read as negative, so `JNEG` wait loops work for up to about 54 minutes.

## Build and run

1. Open `SCOMP.qpf` in Quartus Prime Lite.
2. Assemble `Demo.asm` or `Peripheral_Testing.asm` with SCASM and point `init_file` in `SCOMP.vhd` at the `.mif`.
3. Compile, program the DE10-Standard, and press KEY0 to reset.

## Files

| File | Purpose |
|---|---|
| `TIMER.vhd` | The peripheral |
| `SCOMP_System.bdf` | Top level; TIMER's clock is wired to `clk_10MHz` |
| `REGISTER_MAP.md` | Register contract and assembly idioms |
| `Demo.asm` | Three-task video demo |
| `Peripheral_Testing.asm` | 16 on-board self-checks |
| `IODemo.asm` | Bouncing-LED I/O demo |

## Team and contributions

ECE 2031 Fall 2026 design project: Matthew Nichols, Baris Akinci, Gokce Onal, Abhay Malik, Matthew Fischer.

My work (Matthew Fischer):
- Rewrote the timer on the 10 MHz system clock with a tick prescaler
- Added the countdown register with the `EXPIRED` flag, and the periodic tick register with the `TICK` flag
- Wrote pause/resume self-tests 7–9 and the three-task demo program
- Wrote the register-map contract and README
- Fixed the top-level clock wiring and the repo's `.gitignore` (stopped tracking Quartus build output)

Lap capture (Matthew Nichols), pause/resume (Abhay Malik), and the project base (Gokce Onal) came from teammates.
