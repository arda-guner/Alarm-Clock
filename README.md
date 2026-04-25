# Alarm Clock — Lab 1: Architecture

**Course:** Digital Electronics  
**Board:** Nexys A7-50T (Artix-7 XC7A50T)  
**Tool:** Vivado 2025.2  
**Language:** Verilog  

---

## Project Description

Implementation of a digital alarm clock on the Nexys A7-50T FPGA board.  
The clock displays the current time in **HH:MM:SS** format on the 8-digit 7-segment display.  
The user can set the current time and an alarm time using push buttons.  
When the alarm time is reached, the buzzer sounds and the LEDs light up.

---

## Team Members

 Arda Guner & Zay Yar Naung 

---

## Module Hierarchy (Block Diagram)

![Block_diagram](images/Block_diagram.png)

### Top-Level Inputs / Outputs

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `CLK100MHZ` | in | 1b | 100 MHz system clock (pin E3) |
| `BTNU` | in | 1b | Increment button |
| `BTND` | in | 1b | Confirm / alarm on-off button |
| `BTNC` | in | 1b | Mode select button |
| `SW[0]` | in | 1b | Alarm enable switch |
| `AN[7:0]` | out | 8b | 7-segment anodes (active LOW) |
| `SEG[6:0]` | out | 7b | 7-segment cathodes a–g (active LOW) |
| `AUD_PWM` | out | 1b | Buzzer PWM output |
| `LED[7:0]` | out | 8b | Alarm active indicator |

### Internal Signals

| Signal | Width | Description |
|--------|-------|-------------|
| `ena` | 1b | 1 Hz clock enable from `clk_en` |
| `btn_inc`, `btn_set`, `btn_mode` | 1b each | Debounced button outputs |
| `HH[5:0]`, `MM[5:0]`, `SS[5:0]` | 6b each | Current time registers |
| `AHH[4:0]`, `AMM[5:0]` | 5b, 6b | Alarm time registers |
| `digits[31:0]` | 32b | BCD digits fed to display driver |
| `alarm_trig` | 1b | High when current time == alarm time |
| `FSM_state[1:0]` | 2b | 0=normal, 1=set time, 2=set alarm |

---

## Pin Constraints (XDC)

 [Nexys A7-50T](constraints/nexys)


## Repository Structure

```
alarm_clock/
├── README.md
├── images/
│   └── Block_Diagram.png
│   └──alarm_clock_top_simulation.png
│   └──clk_en_tb.png
│   └──debouncer_simulation.png
│   └──display_driver.png
├── src/
│   └── alarm_clock_top.v
│   └── clk_en.v
│   └── debouncer.v
│   └── display_driver.v
│   └── Block_Diagram.png
├── sim/
│   └── alarm_clock_top.v
│   └── clk_en_tb.v
│   └── debouncer_tb.v
│   └──display_driver.v
```

---
## Design sources and testbenches
 1) [clk_en.v](src/clk_en.v) /
    [clk_en_tb.v](sim/clk_en_tb.v)
    ![Block_diagram](images/clk_en_tb.png)
    
    ### Description
The testbench verifies that `clk_en` generates a single-cycle `ena` pulse at the
correct frequency. The simulation uses a reduced `MAX = 9` (instead of
`100_000_000 - 1`) so that the 1 Hz behaviour can be observed within a 500 ns
simulation window.

**Test sequence:**

a) **Reset (0–20 ns):** `rst` is held high. Both `count` and `ena` are forced to
   `0`. No pulse is produced during this period.

b) **First pulse (~120 ns):** After reset is released, `count` increments on every
   rising edge of `clk`. When it reaches `MAX = 9`, `ena` goes high for exactly
   one clock cycle (10 ns), then returns to `0` and `count` resets to `0`.

c) **Subsequent pulses:** The pattern repeats every 10 clock cycles (~100 ns),
   confirming that the period is correct and the pulse width is always exactly
   1 cycle regardless of how long the simulation runs.

 2) [debouncer.v](src/debouncer.v) /
    [debouncer_tb.v](sim/debouncer_tb.v)
    ![Block_diagram](images/debouncer_simulation.png)

### Description

The testbench verifies that the debouncer filters out mechanical button bounce
and only emits a single-cycle `btn_out` pulse after the input has been stable
for `STABLE` clock cycles. A reduced `STABLE = 20` is used so the behaviour
can be observed within a 1000 ns simulation window.

**Test sequence:**

a) **Idle (0–100 ns):** `btn_in` is held low. No output is produced.

b) **Test 1 — Bouncy press (~100–700 ns):** `btn_in` toggles rapidly five times
   (30 ns high, 30 ns low each) to simulate mechanical bounce. The debouncer
   resets its counter on every edge and suppresses all the glitches. Once
   `btn_in` settles stably high and `STABLE` cycles pass, exactly one
   `btn_out` pulse is emitted.

c) **Test 2 — Clean press (~700–900 ns):** `btn_in` goes high immediately
   without any bouncing and stays high for 500 ns. After `STABLE` cycles the
   debouncer emits a single `btn_out` pulse, confirming normal operation for
   a clean button press.

d) **Test 3 — Short glitch (~900 ns):** `btn_in` goes high for only 20 ns,
   which is shorter than the `STABLE` threshold. The counter never reaches
   `STABLE` so `btn_out` remains low, confirming that brief glitches are
   correctly ignored.
    
 3) [alarm_clock_top.v](src/alarm_clock_top.v) /
    [alarm_clock_top_tb.v](sim/alarm_clock_top_tb.v)
![Block_diagram](images/alarm_clock_top_simulation.png)
### Description

The testbench performs an end-to-end verification of the complete alarm clock,
covering normal timekeeping, time setting, alarm setting, alarm triggering, and
alarm silencing. The `ena` pulse is driven manually to simulate 1 Hz ticks
without waiting for the real clock divider.

**Test sequence:**

1. **Test 1 — Normal ticking (0–~1 µs):** Three `ena` pulses are applied while
   the FSM is in normal mode. `SS` increments from `0` to `3`, confirming that
   the time counter advances correctly on each tick.

2. **Test 2 — Set time to 01:30:00 (~1–10 µs):** `btn_mode` is pressed once to
   enter set-time mode. `btn_inc` is pressed once to set `HH = 1`, then
   `btn_set` advances to the `MM` field where 30 presses set `MM = 30`. A
   further `btn_set` moves to `SS`, and 57 presses wrap it from `3` to `0`.
   Two `btn_mode` presses return the FSM to normal mode. The `digits` output
   settles at `01300000`, confirming the time was stored correctly.

3. **Test 3 — Set alarm to 01:30 (~10–14 µs):** Two `btn_mode` presses advance
   the FSM to set-alarm mode. `AHH` is set to `1` and `AMM` to `30` using
   `btn_inc` and `btn_set`. The FSM is then returned to normal mode.

4. **Test 4 — Alarm trigger (~14–16 µs):** `sw_alarm` is raised to enable the
   alarm. Since the current time is already `01:30:00` and matches the alarm
   set-point, one `ena` tick causes `alarm_trig` to go high and `LED` to
   output `0xFF`, confirming the trigger logic works correctly.

5. **Test 5 — Silence alarm (~16–17 µs):** A single `btn_set` press clears
   `alarm_trig` back to `0` and `LED` returns to `0x00`, confirming the
   silence mechanism works.

6. **Test 6 — SS rollover (~17–25 µs):** The FSM enters set-time mode and `SS`
   is manually set to `58`. Three subsequent `ena` ticks advance `SS` through
   `59`, then roll it over to `0` and increment `MM` by one, verifying the
   carry logic between seconds and minutes.

 5) [display_driver.v](src/display_driver.v) /
    [display_driver_tb.v](sim/display_driver_tb.v)
![Block_diagram](images/display_driver_simulation.png)

