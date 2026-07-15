# ARM-AHB2APB-Bridge
Verilog-based Design and Verification of ARM AHB to APB Bridge using ModelSim and Intel Quartus Prime.
# AHB2APB Bridge

A synthesizable RTL implementation of an **AHB-to-APB Bridge**, designed to interface a high-speed **AMBA AHB (Advanced High-performance Bus)** master domain with low-power, low-speed **AMBA APB (Advanced Peripheral Bus)** slave peripherals, as per the ARM AMBA specification.

---

## 📌 Overview

The AHB2APB bridge acts as an APB slave from the AHB side and as the sole master to multiple APB peripherals. It performs protocol conversion, address decoding, and handshake translation, allowing simple, low-bandwidth peripherals (UART, GPIO, Timer, etc.) to be accessed from a high-performance AHB system bus.

Key responsibilities of the bridge:
- Latch address and control signals from the AHB bus
- Generate APB-compliant `PSEL`, `PENABLE`, `PWRITE`, `PADDR`, `PWDATA`
- Convert single AHB transfers into two-cycle APB transfers (SETUP + ENABLE)
- Return `PRDATA` back to the AHB master as `HRDATA`
- Handle wait states / ready signaling (`HREADY`) since APB peripherals are inherently slower

---

## 🏗️ Architecture

```
 ┌─────────────┐        ┌──────────────────────┐        ┌─────────────┐
 │  AHB Master │ <----> │   AHB2APB Bridge      │ <----> │ APB Slave 0 │
 └─────────────┘  AHB   │  (APB Slave on AHB,   │  APB   ├─────────────┤
                  Bus    │   APB Master on APB)  │  Bus   │ APB Slave 1 │
                         └──────────────────────┘        ├─────────────┤
                                                          │ APB Slave N │
                                                          └─────────────┘
```

The bridge is triggered whenever the AHB address falls within the mapped APB address range, decoded via `HSEL`.

---

## ⚙️ FSM (Finite State Machine)

The bridge core is implemented as a Moore/Mealy FSM with the following states:

| State    | Description                                             |
|----------|----------------------------------------------------------|
| `IDLE`   | No active transfer; waits for a valid AHB request        |
| `SETUP`  | Drives `PSEL` and `PADDR`; `PENABLE` = 0 (APB setup phase)|
| `ENABLE` | Drives `PENABLE` = 1; peripheral responds with `PRDATA`/ack |
| `WAIT`   | (optional) Extended state if peripheral is not ready      |

```
 IDLE ──(HSEL & HTRANS valid)──> SETUP ──> ENABLE ──(PREADY)──> IDLE
                                              │
                                              └──(!PREADY)──> WAIT ──> ENABLE
```

---

## 📂 Repository Structure

```
AHB2APB/
├── rtl/
│   ├── ahb2apb_bridge.v        # Top-level bridge module
│   ├── ahb_slave_interface.v   # AHB-side interface logic
│   ├── apb_master_interface.v  # APB-side interface logic
│   └── fsm_controller.v        # Bridge FSM
├── tb/
│   ├── ahb2apb_tb.v            # Testbench
│   └── apb_slave_model.v       # Behavioral APB slave for verification
├── sim/
│   └── run.do / Makefile       # Simulation scripts (ModelSim/QuestaSim/VCS)
├── docs/
│   ├── block_diagram.png
│   └── timing_diagrams.png
└── README.md
```

> Update the tree above to match your actual folder/file names.

---

## 🔑 Interface Signals

### AHB Side (Slave)
| Signal      | Direction | Description                     |
|-------------|-----------|----------------------------------|
| `HCLK`      | Input     | AHB clock                        |
| `HRESETn`   | Input     | Active-low reset                 |
| `HSEL`      | Input     | Slave select                     |
| `HADDR`     | Input     | Address bus                      |
| `HTRANS`    | Input     | Transfer type                    |
| `HWRITE`    | Input     | Write/Read control                |
| `HSIZE`     | Input     | Transfer size                    |
| `HWDATA`    | Input     | Write data                       |
| `HRDATA`    | Output    | Read data                        |
| `HREADY`    | Output    | Transfer ready                   |
| `HRESP`     | Output    | Transfer response                 |

### APB Side (Master)
| Signal      | Direction | Description                     |
|-------------|-----------|-----------------------------------|
| `PCLK`      | Output    | APB clock (usually = HCLK)       |
| `PRESETn`   | Output    | APB reset                        |
| `PSEL`      | Output    | Peripheral select                |
| `PENABLE`   | Output    | Enable signal (2nd cycle)        |
| `PADDR`     | Output    | Peripheral address               |
| `PWRITE`    | Output    | Write control                    |
| `PWDATA`    | Output    | Write data                       |
| `PRDATA`    | Input     | Read data from peripheral        |
| `PREADY`    | Input     | Peripheral ready                 |
| `PSLVERR`   | Input     | Slave error response             |

---

## ▶️ Simulation / How to Run

```bash
# Example using QuestaSim/ModelSim
vlib work
vlog rtl/*.v tb/*.v
vsim -c ahb2apb_tb -do "run -all"

# Example using Icarus Verilog
iverilog -o sim.out rtl/*.v tb/*.v
vvp sim.out
gtkwave dump.vcd
```

> Replace with your actual tool/flow (Vivado, VCS, Verilator, etc.)

---

## ✅ Verification

- Directed test cases for single read/write transfers
- Back-to-back transfer scenarios
- Wait-state / `PREADY` de-assertion handling
- Error response (`PSLVERR`) propagation to `HRESP`
- Address decode boundary checks across multiple APB slaves

Waveforms and coverage reports are available in `docs/` (add your screenshots/reports here).

---

## 📊 Results

| Parameter            | Value            |
|-----------------------|------------------|
| Language              | Verilog / SystemVerilog |
| Target                | FPGA / ASIC synthesis |
| Max Frequency         | _add your synthesis result_ |
| Simulator Used        | _e.g. QuestaSim / Icarus_ |
| Coverage Achieved     | _e.g. 95% functional_ |

---

## 🚀 Future Enhancements

- Support for multiple APB slaves with dynamic address decoding
- Burst-to-single transfer splitting for AHB burst transactions
- Configurable data width (8/16/32-bit)
- UVM-based verification environment

---

## 📄 References

- ARM AMBA 3 APB Protocol Specification
- ARM AMBA AHB-Lite Protocol Specification

---

## 🧑‍💻 Author

YADAV KHYATHI SRI 
https://github.com/Khyasriyadav / www.linkedin.com/in/khyathi-sri-yadav

