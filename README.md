# UART Transceiver with Debuggable Traffic Light Controller

**Tools:** Quartus II · ModelSim · Altera Cyclone IV FPGA (DE2-115) · MAX232  
**Language:** Structural VHDL

---

## Overview

A complete Universal Asynchronous Receiver-Transmitter (UART) implemented in structural VHDL, integrated with a traffic light controller to produce a real-time debuggable embedded system. On each FSM state transition, the traffic light controller transmits a 6-byte ASCII debug message over RS-232 serial to a PC terminal (HyperTerminal / Minicom).

All components are built from the ground up using `enARdFF_2` (enabled, asynchronous-reset D flip-flop) primitives. No behavioral modeling. No IP cores.

---

## System Architecture

```
                        FLEX FPGA (DE2-115)
┌──────────────────────────────────────────────────────┐
│                                                      │
│  ┌────────────┐  state_info[1:0]  ┌───────────────┐  │
│  │ FSM        │──────────────────▶│  UART FSM     │  │
│  │ Controller │  MSTL[2:0]        │  (polling     │  │
│  │ (TLC)      │──────────────────▶│   mode)       │  │
│  │            │  SSTL[2:0]        │               │  │
│  └────────────┘                   └───────┬───────┘  │
│       ▲                            Addr/RW/CS/Data    │
│  clk_slow  MSC/SSC                        │          │
│       │    ▲                       ┌──────▼───────┐  │
│  ┌────┴────┴─┐                     │    UART      │  │
│  │  Clock    │                     │  (TX+RX+     │  │
│  │  Divider  │                     │   BaudGen)   │  │
│  │  + Timer  │                     └──────┬───────┘  │
│  └───────────┘                           TxD/RxD     │
│                                           │          │
└───────────────────────────────────────────┼──────────┘
                                            │
                                        MAX232
                                    (CMOS ↔ RS-232)
                                            │
                                        PC Serial Port
                                     (HyperTerminal)
```

---

## UART Architecture

```
          Data Bus [7:0]
               │
    ┌──────────┼──────────┐
    │          │          │
    ▼      ┌───▼────┐     ▼
  [TDR] ──▶│ SCCR  │◀── [SCCR Write]
    │      └───┬────┘
    │          │ SEL[2:0]
    │      ┌───▼───────────┐
    │      │ Baud Rate Gen │──▶ BClkx8 ──▶ Receiver Control
    │      │ (÷41 → ÷256   │──▶ BClk  ──▶ Transmitter Control
    │      │  → MUX → ÷8)  │
    │      └───────────────┘
    │
    ▼
  [TSR] ──▶ Transmitter ──▶ TxD
  Control      FSM
    (12-state: IDLE→LOAD→START→S0..S7→STOP)

  RxD ──▶ [RSR] ──▶ [RDR] ──▶ Data Bus [7:0]
           ▲    Receiver Control
           │    (IDLE→START_BIT→B0..B7→STOP_BIT)
           │    samples at BClkx8, tick=3 of 8
        [SCSR] ──▶ {TDRE, RDRF, OE, FE} ──▶ Data Bus
```

---

## UART Components

### Baud Rate Generator

Divides the 25.175 MHz system clock to generate programmable baud rates:

**Pipeline:** `25.175 MHz → ÷41 → 8-bit counter (÷256) → 8-to-1 MUX → ÷8`

| SEL[2:0] | BClk (Hz) | BClkx8 (Hz) |
|----------|-----------|-------------|
| `000` | 38,377 | 307,016 |
| `001` | 19,188 | 153,508 |
| `010` | 9,594 | 76,754 |
| `011` | 4,797 | 38,377 |
| `100` | 2,398 | 19,188 |
| `101` | 1,199 | 9,594 |
| `110` | 600 | 4,797 |
| `111` | 300 | 2,398 |

Components: `modulo_41_counter` → `freq_div_256` → `Mux8to1` → `final_div_8`

---

### Transmitter

**Data flow:** TDR → TSR → TxD  
**Control:** `Transmitter_Control` — 12-state FSM clocked by BClk

| State | Action | TxD |
|-------|--------|-----|
| `IDLE` | Wait for TDRE=0 | `1` |
| `LOAD` | Assert load_TSR, copy TDR→TSR | `1` |
| `START` | Transmit start bit | `0` |
| `S0`–`S7` | Shift and transmit data bits (LSB first) | TSR[0] |
| `STOP` | Transmit stop bit, check for next byte | `1` |

TDRE logic (in TDR): `data_valid_d = i_load OR (data_valid_q AND NOT i_load_TSR)`  
TDRE is asserted (`1`) when TDR is empty — ready for CPU to write next byte.

---

### Receiver

**Data flow:** RxD → RSR → RDR → Data Bus  
**Control:** `Receiver_Control` — 11-state FSM clocked by system clock, advances on BClkx8 ticks

**Sampling strategy:** RxD is sampled 8× per bit period at BClkx8 edges. Start bit confirmed at tick 3. Each data bit sampled at tick 3 of its 8-tick window. Stop bit checked at tick 3 for framing error.

| State | Condition | Action |
|-------|-----------|--------|
| `IDLE` | `RxD = 0` | → `START_BIT`, reset tick counter |
| `START_BIT` | tick=3, RxD=0 | Valid start, continue |
| `START_BIT` | tick=3, RxD=1 | False start/noise, → `IDLE` |
| `B0`–`B7` | tick=3 | Assert `shift_RSR`, sample into RSR |
| `B7` | tick=7 | → `STOP_BIT` |
| `STOP_BIT` | tick=3, RxD=0 | Set FE (framing error) |
| `STOP_BIT` | tick=3, RDRF=1 | Set OE (overrun error), skip load |
| `STOP_BIT` | tick=3, normal | Assert `load_RDR`, copy RSR→RDR |

RSR shift direction: new bit enters MSB (bit 7), contents shift right. After 8 shifts, first received bit (LSB of byte) is at bit 0. Correct for LSB-first UART encoding.

---

### UART Registers

| Register | Type | Description |
|----------|------|-------------|
| **TDR** | 8-bit latch | CPU writes byte to transmit; TDRE clears on write, sets when TSR takes data |
| **TSR** | 8-bit shift register | Parallel-load from TDR, shift-right on each BClk tick during S0–S7 |
| **RDR** | 8-bit latch | Receives parallel byte from RSR; RDRF sets on load, clears on CPU read |
| **RSR** | 8-bit shift register | Serially receives RxD bit-by-bit, shifted right (new bits enter MSB) |
| **SCCR** | 8-bit control | `[2:0]` SEL (baud rate), `[6]` RIE, `[7]` TIE |
| **SCSR** | 8-bit status (read-only) | `[7]` TDRE, `[6]` RDRF, `[2]` OE, `[1]` FE |

### Address Decoder

| ADDR[1:0] | R/W | Action |
|-----------|-----|--------|
| `00` | Read | Data Bus ← RDR |
| `00` | Write | TDR ← Data Bus |
| `01` | Read | Data Bus ← SCSR |
| `01` | Write | No action (Z) |
| `1x` | Read | Data Bus ← SCCR |
| `1x` | Write | SCCR ← Data Bus |

---

## UART FSM — The Microcontroller Simulator

The `UART_FSM` simulates the role of a microcontroller that monitors the traffic light state and sends debug messages via polling mode.

**FSM States:**

```
IDLE ──(state change detected)──▶ POLL_STATUS
  ▲                                     │
  │                               CHECK_TDRE
  │                              /          \
  │                        TDRE=1           TDRE=0
  │                             \          /
  │                           WRITE_CHAR──▶ POLL_STATUS
  │                               │
  └───(char_index = 5)────── NEXT_CHAR
                                  │
                           (char_index < 5) ──▶ POLL_STATUS
```

**Debug messages** (6 bytes each, including carriage return `0x0D`):

| State | state_info | Message | ASCII bytes |
|-------|-----------|---------|-------------|
| Main green / Side red | `00` | `Mg Sr\r` | `4D 67 20 53 72 0D` |
| Main yellow / Side red | `01` | `My Sr\r` | `4D 79 20 53 72 0D` |
| Main red / Side green | `10` | `Mr Sg\r` | `4D 72 20 53 67 0D` |
| Main red / Side yellow | `11` | `Mr Sy\r` | `4D 72 20 53 79 0D` |

**Operation:** IDLE detects `state_information ≠ prev_state`. Transitions to POLL_STATUS, reads SCSR at address `01`, checks TDRE (bit 7). When TDRE=1 (transmitter ready), writes the next character to TDR at address `00`. Repeats until all 6 characters sent.

---

## Traffic Light Controller FSM

4-state Moore machine using 2 flip-flops (`y1`, `y0`). One-hot encoded outputs.

| y1 y0 | State | MSTL | SSTL | Transition Condition |
|-------|-------|------|------|---------------------|
| 0 0 | MS Green / SS Red | 001 | 100 | MSC AND SSCS |
| 0 1 | MS Yellow / SS Red | 010 | 100 | MSC |
| 1 0 | MS Red / SS Green | 100 | 001 | SSC |
| 1 1 | MS Red / SS Yellow | 100 | 010 | SSC |

Next-state logic:
```
bigY0 = NOT y0
bigY1 = (y1 AND NOT y0) OR (NOT y1 AND y0)
enable = (NOT y1 AND NOT y0 AND MSC AND SSCS)
       OR (NOT y1 AND y0 AND MSC)
       OR (y1 AND NOT y0 AND SSC)
       OR (y1 AND y0 AND SSC)
```

State output to UART FSM: `state_information = {y1, y0}`

---

## File Structure

```
uart-traffic-controller/
├── rtl/
│   ├── top/
│   │   └── debuggableTrafficLightController.vhd  # System top-level
│   ├── uart/
│   │   ├── UART.vhd                # UART top: connects TX, RX, BaudGen, registers
│   │   ├── UART_Transmitter.vhd    # TDR + TSR + Transmitter_Control
│   │   ├── UART_Receiver.vhd       # RSR + RDR + Receiver_Control
│   │   ├── Transmitter_Control.vhd # 12-state TX FSM (enARdFF_2 primitives)
│   │   ├── Receiver_Control.vhd    # 11-state RX FSM (BClkx8 tick-based)
│   │   ├── TDR.vhd                 # Transmit Data Register + TDRE logic
│   │   ├── TSR.vhd                 # Transmit Shift Register (parallel load, shift right)
│   │   ├── RDR.vhd                 # Receive Data Register + RDRF logic
│   │   ├── RSR.vhd                 # Receive Shift Register (serial in, parallel out)
│   │   ├── SCCR.vhd                # Serial Communications Control Register
│   │   ├── SCSR.vhd                # Serial Communications Status Register (read-only)
│   │   └── addressDecode.vhd       # 2-bit address + R/W → 6-bit decode vector
│   ├── baud/
│   │   ├── baud_rate_generator.vhd # Top: mod41 → div256 → MUX → div8
│   │   ├── modulo_41_counter.vhd   # Divides 25.175 MHz by 41
│   │   ├── freq_div_256.vhd        # 8-stage binary counter (÷2 to ÷256)
│   │   ├── Mux8tol.vhd             # 8-to-1 MUX for baud rate selection
│   │   └── final_div_8.vhd         # Divides selected BClkx8 by 8 → BClk
│   ├── controller/
│   │   ├── UART_FSM.vhd            # Polling FSM: monitors state, sends debug strings
│   │   ├── fsmController.vhd       # Traffic light 4-state Moore FSM
│   │   ├── Timer.vhd               # MSC/SSC timer driven by SW1/SW2
│   │   ├── interruptGenerator.vhd  # IRQ from TIE/RIE + TDRE/RDRF
│   │   └── clk_div.vhd             # System clock divider
│   └── primitives/
│       └── enARdFF_2.vhd           # Enabled, async-reset D flip-flop (base primitive)
└── README.md
```

---

## Data Frame Format

```
  Idle    Start   D0   D1   D2   D3   D4   D5   D6   D7   Stop  Idle
───────┐  ┌────┬────┬────┬────┬────┬────┬────┬────┬────┐  ┌───────
       │  │    │    │    │    │    │    │    │    │    │  │
       └──┘    └────┴────┴────┴────┴────┴────┴────┴────┘  └
         Start  LSB ──────────── 7-bit ASCII ──────────── MSB Stop
```

- 1 start bit (low)
- 8 data bits, LSB first
- 1 stop bit (high)
- No parity
- Baud rate programmable via SEL[2:0] in SCCR

---

## Design Constraints
- VHDL only
- Structural RTL only
- All atomic modules built from `enARdFF_2` primitives
- Synchronous design with global clock and asynchronous global reset throughout
