# FPGA Alarm Clock (24-hour format)

## Problem Description
This project implements a digital 24-hour alarm clock using Verilog on an FPGA.  
The system keeps track of time (hours, minutes, seconds), allows setting an alarm, and displays the current time and alarm status on 7-segment displays.

---

## Architecture Overview
The design follows a hierarchical structure with multiple modules:

- clk_divider – Converts FPGA clock (e.g., 100 MHz) to 1 Hz
- time_counter – Keeps track of current time (HH:MM:SS)
- alarm_register – Stores alarm time set by user
- alarm_compare – Compares current time with alarm time
- seven_seg_driver – Controls 7-segment display output
- top module – Connects all modules together

---

## Block Diagram
(Insert diagram here – created in draw.io or PowerPoint)

---

## Git Flow
Project uses incremental commits:
- Initial repository setup
- Module creation
- Simulation and testing (planned in Lab 2)

---

## Tools Used
- Vivado 2025.2
- Verilog HDL
- Git

---

## Notes
- All modules will be individually simulated before integration
- Design avoids latches by using proper synchronous logic
