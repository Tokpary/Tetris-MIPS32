# MIPS32 Tetris

> *A bare-metal implementation of the classic Tetris game written entirely in MIPS32 Assembly.*

This project is a fully functional Tetris clone built for the **MARS 4.5** simulator. It directly manages memory-mapped graphics, keyboard I/O, and game state at the hardware level without relying on any high-level abstractions or libraries. 

## 🧩 Key Features

* **Memory-Mapped Graphics:** Direct pixel manipulation using the MARS Bitmap Display tool.
* **Real-Time MMIO Input:** Polling-based keyboard input using the Keyboard and Display MMIO Simulator.
* **Complete Core Mechanics:** 
  * Piece generation and randomization.
  * Tetromino rotation and boundary/collision detection.
  * Line clearing and gravity systems.
* **Game Progression:** Dynamic scoring system and progressive speed increases as the game advances.
* **Low-Level Architecture:** Designed strictly within the architectural constraints of the MIPS environment, utilizing efficient register allocation, stack management, and bitwise operations.

## ⚙️ Prerequisites

To run this game, you need the **MARS (MIPS Assembler and Runtime Simulator) 4.5**.
* Download MARS 4.5 [here](https://github.com/dpetersanderson/MARS).
* Java Runtime Environment (JRE) is required to run MARS.

## 🚀 How to Run

Running graphical games in MARS requires setting up the specific display tools before executing the code.

1. Open `MARS 4.5` and load the `tetris.asm` file.
2. Go to the **Tools** menu and open the **Bitmap Display**.
3. Configure the Bitmap Display settings as follows:
   * Unit Width in Pixels: `8` 
   * Unit Height in Pixels: `8` 
   * Display Width in Pixels: `256` 
   * Display Height in Pixels: `512` 
   * Base Address for Display:  `0x10008000 ($gp)`
4. Click **Connect to MIPS** at the bottom of the Bitmap Display window.
5. Go to the **Tools** menu again and open the **Keyboard and Display MMIO Simulator**.
6. Click **Connect to MIPS** at the bottom of the MMIO window.
7. Assemble the code (`F3` or the Wrench icon).
8. Run the code (`F5` or the Play icon). 
   * *Note: Make sure the MMIO Keyboard window is focused when typing controls!*

## 🎮 Controls

Ensure the **Keyboard and Display MMIO Simulator** window is focused to send inputs to the game.

| Action | Key |
| :--- | :--- |
| **Move Left** | `A` |
| **Move Right** | `D` |
| **Rotate** | `R` |
| **Soft Drop** | `S` |
| **Hard Drop** | `Space` |

## 💻 Technical Details

This project serves as an exploration of low-level software architecture. Key technical challenges solved include:
* **Grid Representation:** The 10x20 Tetris grid is mapped linearly in memory. Matrix math (`y * width + x`) is calculated via bit-shifting and addition to optimize CPU cycles.
* **Collision Detection:** Implemented by calculating the absolute memory address of the tetromino's next state and checking against boundary limits and existing static blocks in the heap.
* **Pseudo-Random Number Generation:** Uses MIPS syscalls to seed and generate random sequences for piece selection.

## 👤 Author

**[Tokpary]** 
* [GitHub](https://github.com/Tokpary)
