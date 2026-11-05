# RISC-V CPU and Verification Flow in Verilog

Single-cycle **RISC-V processor in Verilog**, verified with directed tests and a **constrained-random, coverage-driven** flow. A Snake game in C runs on the CPU in simulation.

## Contents

- `rtl/`: CPU (ALU, register file, control unit, immediate generator, PC, ROM, RAM, top)
- `tb/`: testbenches (instruction test, Snake system test)
- `sw/`: `crt0.s`, C program, `convert.py`
- `scripts/rand_test.py`: Python random generator, reference model and coverage

## Build and run

Requires Icarus Verilog, Python 3 and `riscv-none-elf-gcc`.


Add `-DSIM` when building the Snake for simulation.

## Verification

- **Directed tests:** self-checking testbenches (`PASS` / `FAIL`) for instructions and for the Snake game (17 checks).
- **Constrained-random:** random programs from a seed, compared with a Python reference model. Failing seeds are saved.
- **Coverage-driven:** new seeds run until all coverage bins are hit.



## Next steps

`sra`, `auipc` and `bltu` support, FPGA implementation on the Tang Nano 9K (Yosys / nextpnr), UART and HDMI output, 5-stage pipeline.
