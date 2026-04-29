# 🚀 Advanced Digital Design & Verification Portfolio

Welcome! I'm **Adarsh Misra**, a 3rd-year B.E. student specializing in **Electronics VLSI Design and Technology**. 

This repository serves as my comprehensive hardware portfolio. It bridges the gap between pure RTL hardware design and advanced software-driven verification. Inside, you will find a progression of projects scaling from foundational combinational logic up to a fully parameterized 3x3 Network-on-Chip (NoC) verified with Object-Oriented SystemVerilog environments.

---

## 🛠️ Technical Arsenal
* **Languages:** SystemVerilog, Verilog, VHDL, Python, C/C++
* **Verification:** Object-Oriented Programming (OOP), Inter-Process Communication (Mailboxes, Semaphores, Events), Constrained-Random Generation, Scoreboarding, Coverage-Driven methodologies.
* **Protocols & Interfaces:** AMBA AXI-Stream, I2C, SPI.
* **Tools:** Xilinx Vivado, Cadence Virtuoso, Git/GitHub.

---

## 📂 Project Directory

### 🌟 Capstone Architecture
* **[3x3 Mesh Network-on-Chip (NoC) with Wormhole Routing](./)**
  * **Description:** A scalable, multi-hop router network featuring XY deterministic routing, 5-port Non-Blocking Crossbars, Round-Robin Arbitration, and Credit-Based Flow Control. 
  * **Skills:** Parameterized structural generation (`generate` loops), complex datapath routing, deadlock-avoidance strategies, and multi-agent OOP verification.

### 🛡️ Advanced Verification & Security
* **[Layered OOP Verification Environment (Pipelined ALU)](./)**
  * **Description:** A lightweight, UVM-style verification environment built from scratch to test a 3-stage pipelined ALU.
  * **Skills:** Abstract base classes, polymorphism, `mailbox` communication between Generators/Drivers/Monitors, `semaphore` arbitration, out-of-order execution scoreboarding, and pipeline draining (teardown).
* **[Secure AXIS Packet Gatekeeper (Hardware Firewall)](./)**
  * **Description:** A store-and-forward AXI-Stream gatekeeper that inspects packet headers byte-by-byte, dropping spoofed or malicious packets while forwarding valid data.
  * **Skills:** AXI-Stream protocol compliance, hybrid RTL/OOP testbenches, and race-condition mitigation.

### 🔌 Standard & Custom Protocols
* **[Custom 32 bps I2C Master Controller](./)**
  * **Description:** A unique, ultra-low-speed I2C controller specifically engineered at 32 bits per second. This allows for naked-eye hardware debugging via FPGA LEDs and low-bandwidth oscilloscope capture.
  * **Skills:** Open-drain tri-state buffer routing, 4x clock oversampling, and valid/ready handshake synchronization across disparate clock domains.
* **[SPI Master Controller](./)**
  * **Description:** A fully configurable SPI Master tested with constrained-random (`randc`) cyclic generation to mathematically guarantee all CPOL/CPHA modes are exercised.

### ⚙️ Core Logic & State Machines
* **[Digital Chess Clock Controller](./)**
  * **Description:** A highly resilient Finite State Machine (FSM) handling real-time pausing, player toggling, and game-over conditions.
* **[Round-Robin Bus Arbiter](./)**
  * **Description:** A multi-request arbiter utilizing rotating priority pointers to prevent peripheral starvation.
* **[Combinational ALU](./)**
  * **Description:** The foundational arithmetic logic unit that started it all.

---

## 🎯 My Approach to Engineering
I build hardware with a software engineer's mindset. Writing RTL is only half the battle; proving it works under chaotic, highly congested conditions requires robust, scalable testbenches. Whether I am routing flits across a mesh network or tracking API responses in a Python backend, my goal is always to build clean, modular, and verifiable systems.

📫 **Let's Connect:** Feel free to explore the code or reach out!
