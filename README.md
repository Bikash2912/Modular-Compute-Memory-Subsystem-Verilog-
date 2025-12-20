## Modular-Compute-Memory-Subsystem-Verilog-
Dual Port Memory and ALU Subsystem with External SPI Interface

# Overview

This project implements an FSM-controlled integrated processing and memory subsystem using Verilog HDL.
The design combines internal dual-port memory, an ALU with flag handling, and an external SPI memory interface, all orchestrated by a central memory controller finite state machine.

## The system supports:

1. Internal memory read/write operations
2. External memory access via SPI
3. ALU operations using memory operands
4. Optional ALU result push to external memory using a stack pointer
5. Clean handshaking (busy, done) for CPU-style control

The design was developed and verified module-by-module, then integrated and validated at the top level.

## Top-Level Functionality

At a high level, the system behaves as follows:

### 1. CPU / Host issues a request

1. Internal memory access
2. External memory access
3. ALU operation (with optional external push)

### 2.Memory Controller FSM

1. Decodes the request
2. Selects internal or external path
3. Sequences multi-cycle operations
4. Manages ALU operand fetch, execution, and write-back

### 3.Data Path Execution

1. Internal RAM for fast local storage
2. ALU for arithmetic/logic operations
3. SPI master for serialized external memory access
4. Stack pointer for external result storage

### 4.Completion Signaling

1. busy asserted during operation
2. done asserted for one cycle on completion

 ## Architectural Blocks
### 1. Memory Controller (FSM Core)

Central control unit of the system

Implements multiple FSM paths:

Internal RAM read/write

External SPI read/write

ALU operand fetch → execute → store

Latches requests to ensure correct multi-cycle sequencing

Generates all control signals for memory, ALU, and SPI

2. Internal True Dual-Port RAM

Size: 256 × 8

Port A: controlled by memory controller

Port B: reserved for debug/extension

Supports:

Single-cycle write

Registered read

Optional collision detection

3. ALU Core

Performs arithmetic and logical operations

Operands fetched from internal RAM

Result written back to internal RAM

Generates processor flags:

Carry (CY)

Auxiliary Carry (ACY)

Zero (ZERO)

Sign (SGN)

Parity (PARITY)

4. Flag Register

Latches ALU flags on alu_done

Separates combinational ALU outputs from sequential control logic

Feeds latched flags back to the controller (for chaining or extension)

5. Stack Pointer

Manages external memory addresses for ALU result storage

Automatically increments on push operations

Enables stack-style external data management

6. SPI Master

Handles serialized communication with external memory

Supports:

Byte-wise transfer

Busy/done handshaking

Controlled entirely by the memory controller FSM

7. External SPI Memory

Models off-chip memory accessed through SPI

Receives commands from SPI master

Stores and returns data bytes

Debug signals expose current address and data
