-- TIMER.VHD  --  The Stopwatch Peripheral for SCOMP
-- ECE 2031 Fall 2026 design project
--
-- Every time value in this peripheral is in TICKS of 0.1 s (10 Hz), the same
-- unit as the original Lab 8 timer, so old programs keep working.
--
-- Register map (see REGISTER_MAP.md for the full contract):
--   0x002  COUNT     R: ticks since last reset     W: any value -> COUNT = 0
--   0x0F0  LAP       R: last captured count        W: any value -> LAP = COUNT
--   0x0F1  CTRL      R: bit0 = 1 running           W: bit0 = 1 run, 0 pause
--
-- Pause (CTRL bit0 = 0) freezes all time in the peripheral, including the
-- partial tick in progress, so resume picks up exactly where it stopped.
--
-- Design rules:
--   * Every register runs on the 10 MHz SCOMP clock. Wire CLOCK to clk_10MHz.
--   * IO_WRITE and IO_READ are used as enables, never as clocks or resets.
--   * A prescaler makes a one-clock TICK pulse every TICK_DIV clocks.

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE LPM.LPM_COMPONENTS.ALL;


ENTITY TIMER IS
	GENERIC(
		TICK_DIV : INTEGER := 1000000  -- CLOCK cycles per tick: 10 MHz / 1,000,000 = 10 Hz
	);
	PORT(
		CLOCK,                          -- must be the 10 MHz SCOMP clock
		RESETN   : IN    STD_LOGIC;
		IO_ADDR  : IN    STD_LOGIC_VECTOR(10 DOWNTO 0);
		IO_READ  : IN    STD_LOGIC;
		IO_WRITE : IN    STD_LOGIC;
		IO_DATA  : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END TIMER;


ARCHITECTURE a OF TIMER IS
	-- I/O addresses
	CONSTANT TIMER_ADDR  : STD_LOGIC_VECTOR(10 DOWNTO 0) := "00000000010"; -- 0x002
	CONSTANT LAP_ADDR    : STD_LOGIC_VECTOR(10 DOWNTO 0) := "00011110000"; -- 0x0F0
	CONSTANT CTRL_ADDR   : STD_LOGIC_VECTOR(10 DOWNTO 0) := "00011110001"; -- 0x0F1

	-- Time base
	SIGNAL PRESCALE  : INTEGER RANGE 0 TO TICK_DIV-1;
	SIGNAL TICK      : STD_LOGIC;  -- '1' for one CLOCK cycle every 0.1 s while running

	-- Registers
	SIGNAL COUNT     : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL LAP       : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL RUN       : STD_LOGIC;  -- '1' = counting, '0' = paused

	-- Address decode and bus control
	SIGNAL TIMER_SEL  : STD_LOGIC;
	SIGNAL LAP_SEL    : STD_LOGIC;
	SIGNAL CTRL_SEL   : STD_LOGIC;
	SIGNAL ANY_SEL    : STD_LOGIC;
	SIGNAL OUT_DATA   : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL IO_EN      : STD_LOGIC;

	BEGIN

	-- Address decode
	TIMER_SEL  <= '1' WHEN IO_ADDR = TIMER_ADDR  ELSE '0';
	LAP_SEL    <= '1' WHEN IO_ADDR = LAP_ADDR    ELSE '0';
	CTRL_SEL   <= '1' WHEN IO_ADDR = CTRL_ADDR   ELSE '0';
	ANY_SEL    <= TIMER_SEL OR LAP_SEL OR CTRL_SEL;


	-- Use LPM function to create bidirection I/O data bus
	IO_BUS: lpm_bustri
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => OUT_DATA,
		enabledt => IO_EN,
		tridata  => IO_DATA
	);


	-- TIME BASE: one TICK pulse every TICK_DIV clocks, frozen while paused
	TICK <= '1' WHEN (RUN = '1') AND (PRESCALE = TICK_DIV-1) ELSE '0';

	PROCESS (CLOCK, RESETN)
	BEGIN
		IF (RESETN = '0') THEN
			PRESCALE <= 0;
		ELSIF (rising_edge(CLOCK)) THEN
			IF (RUN = '1') THEN
				IF (PRESCALE = TICK_DIV-1) THEN
					PRESCALE <= 0;
				ELSE
					PRESCALE <= PRESCALE + 1;
				END IF;
			END IF;
		END IF;
	END PROCESS;


	-- COUNT (0x002): any write resets to 0, otherwise +1 per tick
	PROCESS (CLOCK, RESETN)
	BEGIN
		IF (RESETN = '0') THEN
			COUNT <= x"0000";
		ELSIF (rising_edge(CLOCK)) THEN
			IF (TIMER_SEL = '1') AND (IO_WRITE = '1') THEN
				COUNT <= x"0000";
			ELSIF (TICK = '1') THEN
				COUNT <= COUNT + 1;
			END IF;
		END IF;
	END PROCESS;


	-- LAP (0x0F0): any write copies COUNT into LAP
	PROCESS (CLOCK, RESETN)
	BEGIN
		IF (RESETN = '0') THEN
			LAP <= x"0000";
		ELSIF (rising_edge(CLOCK)) THEN
			IF (LAP_SEL = '1') AND (IO_WRITE = '1') THEN
				LAP <= COUNT;
			END IF;
		END IF;
	END PROCESS;


	-- CTRL (0x0F1): bit 0 = 1 run, 0 pause
	PROCESS (CLOCK, RESETN)
	BEGIN
		IF (RESETN = '0') THEN
			RUN <= '1';               -- out of reset, the timer runs
		ELSIF (rising_edge(CLOCK)) THEN
			IF (CTRL_SEL = '1') AND (IO_WRITE = '1') THEN
				RUN <= IO_DATA(0);
			END IF;
		END IF;
	END PROCESS;


	-- Read mux: pick the register for the address being read
	OUT_DATA <= LAP                                WHEN LAP_SEL    = '1' ELSE
	            "000000000000000" & RUN            WHEN CTRL_SEL   = '1' ELSE
	            COUNT;

	-- Drive IO_DATA only when one of our addresses is being read
	IO_EN <= ANY_SEL AND IO_READ;

END a;
