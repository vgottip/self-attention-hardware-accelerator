# Self-Attention Hardware Accelerator

A SystemVerilog-based hardware accelerator for Transformer self-attention computation using pipelined matrix multiplication and SRAM-stored inputs and weights.

## Overview

This project implements a pipelined self-attention computation module for ASIC/FPGA-style digital design. The design optimizes matrix multiplication and memory access using SRAM-based input storage, reducing total clock cycles and improving computation speed.

The accelerator was evaluated using ModelSim simulation and benchmark input data.

## Features

- SystemVerilog RTL implementation
- Pipelined self-attention computation
- SRAM-based input and weight storage
- Matrix multiplication acceleration
- Optimized memory access pattern
- ModelSim simulation support
- Headless evaluation testing
- Log-based result analysis

## Repository Structure

```text
.
├── inputs/              # Input .dat files for SRAM initialization
├── rtl/                 # RTL design files
│   └── dut.sv           # Main design module
├── testbench/           # Testbench and verification files
├── run/                 # Simulation Makefile and run scripts
│   └── logs/            # Generated simulation logs
├── dpi/                 # DPI-C source files, if used
├── scripts/             # Helper scripts
├── setup.sh             # Tool environment setup script
└── README.md
