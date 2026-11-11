# ECE 2031 Stopwatch Peripheral

A SCOMP timer peripheral with lap, pause/resume, countdown and a periodic tick,
backward compatible with the Lab 8 timer at 0x002. See REGISTER_MAP.md.

| File | Purpose |
|---|---|
| TIMER.vhd | the peripheral |
| SCOMP_System.bdf | top level; TIMER CLOCK is wired to clk_10MHz |
| Peripheral_Testing.asm | 16 self-checks: Hex0 = 600D on pass, EEEE + test number (hex) on Hex1 on fail |
| Demo.asm | video demo (SW0 lap, SW1 pause, SW2 countdown, SW3 reset) |

Build: open SCOMP.qpf in Quartus Lite, assemble the .asm with SCASM, set
init_file in SCOMP.vhd, compile, program, press KEY0.

Team: Matthew N, Baris, Gokce, Matthew F, Abhay.
