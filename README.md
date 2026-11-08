# RISC-V CPU and Verification Flow in Verilog

Single-cycle **RISC-V processor in Verilog**, verified with directed tests and a **constrained-random, coverage-driven** flow.

## Contents

- `rtl/`: CPU (ALU, register file, control unit, immediate generator, PC, ROM, RAM, top)
- `sim/`: testbenches (instruction test)
- `sw/`: `crt0.s`, C program, `convert.py`

**Random regression** (requires Icarus Verilog and Python 3):

    python rand_test.py

## Verification

- **Directed tests:** self-checking testbenches (`PASS` / `FAIL`) for instructions.
- **Constrained-random:** random programs from a seed, compared with a Python reference model. Failing seeds are saved.
- **Coverage-driven:** new seeds run until all coverage bins are hit.



## Next steps

`sra`, `auipc` and `bltu` support, FPGA implementation on the Tang Nano 9K (Yosys / nextpnr), UART and HDMI output, 5-stage pipeline.
