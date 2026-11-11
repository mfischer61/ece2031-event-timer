-- TIMER.VHD (a peripheral module for SCOMP)
-- 2003.04.24, lap functionality added 2026.11.10
-- pause/resume functionality added 2026.11.10
--
-- Timer returns a 16 bit counter value with a resolution of the CLOCK period.
-- Writing any value to TIMER_ADDR resets the count to 0x0000, but the timer
-- continues to run.
-- The counter value rolls over to 0x0000 after a clock tick at 0xFFFF.
--
-- Lap: writing any value to LAP_ADDR latches the current count into the lap
-- register. The timer keeps running and is NOT reset. Reading LAP_ADDR returns
-- the most recently latched value. RESETN clears the lap register.
--
-- Pause: writing a value with bit 0 = 0 to CTRL_ADDR holds the count and
-- writing bit 0 = 1 resumes it. The count is NOT reset, so it continues from
-- the held value. Reading CTRL_ADDR returns 1 while running and 0 while
-- paused. RESETN leaves the timer running.

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE LPM.LPM_COMPONENTS.ALL;


ENTITY TIMER IS
	PORT(
		CLOCK,
		RESETN   : IN    STD_LOGIC;
		IO_ADDR  : IN    STD_LOGIC_VECTOR(10 DOWNTO 0);
		IO_READ  : IN    STD_LOGIC;
		IO_WRITE : IN    STD_LOGIC;
		IO_DATA  : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END TIMER;


ARCHITECTURE a OF TIMER IS
	-- I/O addresses
	CONSTANT TIMER_ADDR : STD_LOGIC_VECTOR(10 DOWNTO 0) := "00000000010"; -- 0x002
	CONSTANT LAP_ADDR   : STD_LOGIC_VECTOR(10 DOWNTO 0) := "00011110000"; -- 0x0F0
	CONSTANT CTRL_ADDR  : STD_LOGIC_VECTOR(10 DOWNTO 0) := "00011110001"; -- 0x0F1

	SIGNAL COUNT     : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL LAP       : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL RUN       : STD_LOGIC;  -- '1' = counting, '0' = paused
	SIGNAL OUT_DATA  : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL TIMER_SEL : STD_LOGIC;
	SIGNAL LAP_SEL   : STD_LOGIC;
	SIGNAL CTRL_SEL  : STD_LOGIC;
	SIGNAL IO_EN     : STD_LOGIC;

	BEGIN

	-- Address decode
	TIMER_SEL <= '1' WHEN IO_ADDR = TIMER_ADDR ELSE '0';
	LAP_SEL   <= '1' WHEN IO_ADDR = LAP_ADDR   ELSE '0';
	CTRL_SEL  <= '1' WHEN IO_ADDR = CTRL_ADDR  ELSE '0';


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

	-- NORMAL TIMER FUNCTIONALITY PART
	PROCESS (CLOCK, RESETN, TIMER_SEL, IO_WRITE)
	BEGIN
		IF (RESETN = '0' OR ((TIMER_SEL = '1') AND (IO_WRITE = '1'))) THEN
			COUNT <= x"0000";
		ELSIF (rising_edge(CLOCK)) THEN
			IF (RUN = '1') THEN
				COUNT <= COUNT + 1;
			END IF;
		END IF;
	END PROCESS;

	
    -- LAP FUNCTIONALITY PART
	PROCESS (IO_WRITE, RESETN)
	BEGIN
		IF (RESETN = '0') THEN
			LAP <= x"0000";
		ELSIF (rising_edge(IO_WRITE)) THEN
			IF (LAP_SEL = '1') THEN
				LAP <= COUNT;
			END IF;
		END IF;
	END PROCESS;

			
	-- PAUSE / RESUME FUNCTIONALITY PART
	PROCESS (IO_WRITE, RESETN)
	BEGIN
		IF (RESETN = '0') THEN
			RUN <= '1';               -- out of reset, the timer runs
		ELSIF (rising_edge(IO_WRITE)) THEN
			IF (CTRL_SEL = '1') THEN
				RUN <= IO_DATA(0);
			END IF;
		END IF;
	END PROCESS;


	-- Show the correct data
	OUT_DATA <= LAP WHEN LAP_SEL  = '1' ELSE "000000000000000" & RUN WHEN CTRL_SEL = '1' ELSE COUNT;


	-- Drive IO_DATA when either address is read.
	IO_EN <= '1' WHEN (((TIMER_SEL = '1') OR (LAP_SEL = '1') OR (CTRL_SEL = '1'))) AND (IO_READ = '1')
	         ELSE '0';


END a;
