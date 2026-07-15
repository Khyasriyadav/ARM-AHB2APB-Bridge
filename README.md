# ARM AHB2APB Bridge

A Verilog-based implementation of an **ARM AHB to APB Bridge**, designed to interface a high-speed **AMBA AHB (Advanced High-performance Bus)** with low-speed **AMBA APB (Advanced Peripheral Bus)**. The bridge performs protocol conversion, enabling efficient communication between AHB masters and APB peripherals.

---

## 📌 Project Overview

The AHB2APB Bridge acts as an interface between the AHB and APB buses. It converts AHB transactions into APB transactions while maintaining compatibility with the ARM AMBA protocol.

### Key Features

- Verilog RTL implementation
- AHB to APB protocol conversion
- Read and Write transaction support
- Finite State Machine (FSM) based control
- Functional verification using Testbench
- Simulation using ModelSim / QuestaSim
- RTL synthesis using Intel Quartus Prime Lite 17.1

---

## 🏗️ Block Diagram

![Block Diagram](block%20diagram.png)

---

## 📊 Simulation Result

The design was verified using **ModelSim / QuestaSim**. The waveform confirms successful AHB read/write transactions and correct APB signal generation.

![Simulation Waveform](simulation%20.png)

---

## 🛠️ Tools Used

| Tool | Purpose |
|------|---------|
| Verilog HDL | RTL Design |
| ModelSim / QuestaSim | Functional Simulation & Verification |
| Intel Quartus Prime Lite 17.1 | RTL Synthesis |

---

## 📂 Repository Contents

| File | Description |
|------|-------------|
| `AHB2APHBRIDEGE.v` | Verilog RTL implementation of the AHB2APB Bridge |
| `tb_ahb2apb.v` | Testbench used for functional verification |
| `block diagram.png` | Project Block Diagram |
| `simulation.png` | Simulation waveform |
| `README.md` | Project documentation |

---

## ▶️ Simulation

The project was simulated using **ModelSim / QuestaSim**.

Basic simulation flow:

```bash
vlib work
vlog AHB2APHBRIDEGE.v tb_ahb2apb.v
vsim tb_ahb2apb
run -all
```

---

## ✅ Results

- Successfully designed an AHB to APB Bridge in Verilog HDL.
- Verified functionality using a dedicated testbench.
- Generated simulation waveforms confirming correct protocol conversion.
- Synthesized using Intel Quartus Prime Lite 17.1.

---

## 📚 Applications

- ARM-based SoCs
- Embedded Systems
- Microcontroller Peripherals
- FPGA-based Digital System Design
- VLSI Design and Verification

---

## 👩‍💻 Author

YADAV KHYATHI SRI

B.Tech – Electronics and Communication Engineering
SRM Institute of Science and Technology, AP

GitHub: https://github.com/Khyasriyadav
Linkdin: https://www.linkedin.com/in/khyathi-sri-yadav

---
