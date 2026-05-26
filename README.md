# self-attention-hardware-accelerator

A SystemVerilog-based hardware design for accelerating Transformer neural network computation using pipelined self-attention and SRAM-based matrix multiplication.

## Overview

This project implements a high-performance Transformer computation module for ASIC and FPGA design. The design focuses on accelerating self-attention by optimizing matrix multiplication, memory access, and pipeline utilization.

Inputs and weights are stored in SRAM-style memory files, and the hardware processes them through a pipelined datapath to reduce total execution cycles. The optimized design improves self-attention computation speed by reducing clock cycles and increasing throughput.

## Key Features

- SystemVerilog RTL implementation
- Pipelined self-attention computation
- SRAM-based input and weight storage
- Matrix multiplication acceleration
- Optimized memory access pattern
- ModelSim simulation support
- Synopsys synthesis flow
- Configurable synthesis clock period
- Headless evaluation testing

## Repository Structure

```text
.
├── inputs/                 # Input .dat files for SRAM initialization
├── HW_specification/        # Homework specification document
├── rtl/                    # RTL design files
│   └── dut.sv              # Main design module connected to test fixture
├── run/                    # Simulation Makefile and generated logs
│   └── logs/               # Evaluation and simulation logs
├── scripts/                # Python scripts for generating test inputs/outputs
├── synthesis/              # Synthesis flow
│   ├── reports/            # Generated synthesis reports
│   └── gl/                 # Gate-level synthesized netlist
├── testbench/              # Test fixture and verification files
├── setup.sh                # Environment setup script
└── README.md
```

## Environment Setup

Source the setup script from the `HW6/` directory to load the required tools:

```bash
source setup.sh
```

This script loads the ModelSim and Synopsys environments and enables tab completion for supported `make` commands.

## RTL Design

The main design file is located at:

```text
rtl/dut.sv
```

The provided `dut.sv` file contains the required module interface and port connections to the test fixture. All RTL design changes should be implemented inside this file or additional SystemVerilog files placed in the `rtl/` directory.

All `.sv` files in `rtl/` are compiled during simulation.

## Build Instructions

To compile the design, move into the simulation directory:

```bash
cd run
```

Then run:

```bash
make build-dw
make build
```

## Running Simulation

To run the design in ModelSim GUI mode:

```bash
make debug
```

This launches the simulation environment for waveform inspection and debugging.

## Evaluation Testing

To run the full evaluation test suite in headless mode:

```bash
make eval
```

This generates simulation logs in:

```text
run/logs/
```

Important log files:

```text
run/logs/RESULTS.log    # Evaluation results
run/logs/output.log     # Simulation output
run/logs/INFO.log       # Simulation information
```

Run evaluation testing after confirming the design works in debug mode.

## Synthesis

After the RTL passes functional simulation, synthesize the design from the synthesis directory:

```bash
cd ../synthesis
make all
```

By default, synthesis uses a 10 ns clock period.

To specify a custom clock period:

```bash
make all CLOCK_PER=<clock_period>
```

Example:

```bash
make all CLOCK_PER=4
```

Generated synthesis files are stored in:

```text
synthesis/reports/      # Timing, area, and power reports
synthesis/gl/           # Synthesized gate-level netlist
```

## Design Flow

```text
1. Source setup script
2. Modify RTL in rtl/dut.sv
3. Build the design
4. Run GUI simulation for debugging
5. Run headless evaluation tests
6. Review logs
7. Run synthesis
8. Analyze timing, area, and generated netlist
```

## Commands Summary

| Task | Command | Directory |
|---|---|---|
| Setup environment | `source setup.sh` | `HW6/` |
| Compile DesignWare | `make build-dw` | `HW6/run/` |
| Build RTL | `make build` | `HW6/run/` |
| Run GUI simulation | `make debug` | `HW6/run/` |
| Run evaluation tests | `make eval` | `HW6/run/` |
| Run synthesis | `make all` | `HW6/synthesis/` |
| Run synthesis with custom clock | `make all CLOCK_PER=4` | `HW6/synthesis/` |

## Technologies Used

- SystemVerilog
- ModelSim
- Synopsys Design Compiler
- ASIC design flow
- FPGA design concepts
- SRAM-based memory architecture
- Pipelined digital design
- Transformer neural network acceleration

## Results

The design accelerates Transformer self-attention computation by reducing the number of required clock cycles through pipelined matrix multiplication and optimized SRAM access.

Key result:

```text
Self-attention computation speed improved by approximately 90%.
```

## Future Improvements

- Add additional pipeline stages for higher clock frequency
- Improve SRAM access scheduling
- Add configurable matrix dimensions
- Add synthesis comparison across different clock periods
- Add timing, area, and power result plots
- Extend the design to support additional Transformer operations

## License

This project is intended for academic and educational use.
