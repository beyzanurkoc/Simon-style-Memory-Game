# Simon-style Memory Game  
## CENG 329 Course Project

This repository contains a **Simon-style memory game** implemented using the **MSP430 microcontroller**.  
The game generates random LED patterns that the player must repeat correctly using buttons.  
As the player progresses, the game becomes more difficult by increasing pattern length and reducing delay times.

---

## Project Team

- **Deniz Sanem Sağlık** 
- **İpek Kaya** 
- **Beyza Nur Koç** 
- **Lara Yağmur** 

---

## 1. System Overview

In this project, a Simon-style memory game was implemented on the MSP430 microcontroller.  
The game starts when the player long-presses the first button for approximately two seconds.

- The initial pattern length starts at **2 steps**.
- Each level increases the pattern length by **1 step** until the first **3 levels** are completed.
- After every set of 3 completed levels:
  - The starting pattern length increases.
  - Delay times are reduced, causing LEDs to flash faster.
- This design gradually increases the game difficulty as the player progresses.

---

## 2. System Design

### 2.1 Hardware Configuration

**Outputs:**
- LEDs connected to pins **P1.0 – P1.6** are used to display game patterns.

**Inputs:**
- Buttons connected to **P2.0, P2.2, P2.3, and P2.4**.
- Buttons are configured with pull-up resistors and interrupts.
- **P2.0** also acts as the *Start Game* trigger when long-pressed.

**Timing:**
- **Timer A (TA0)** is used for:
  - Generating random patterns.
  - Detecting long button presses to start the game from the Idle state.

---

### 2.2 Register Usage

- **R4:** Controls the main program state  
  - `0` → Player lost  
  - `1` → Player won  
  - `2` → In game  
  - `3` → Idle state  

- **R5:** Stores difficulty level  
  - Increases after each completed 3-level sequence  
  - Reduces delay time and increases pattern length

- **R6:** Stores the number of steps in the current pattern

- **R7:** Counts the number of correct button presses by the player  
  - If `R7 = R6`, the level is won

- **R8:** Used as an offset/index for the pattern array

---

## 3. Feature Implementation

### 3.1 Reset State

- Resets all registers
- Sets difficulty to the easiest level
- Returns the system to Idle state
- Turns off all LEDs

---

### 3.2 Idle State

**Labels:** `idle`, `idle_exit`  
**Subroutines:** `delay_idle`

- LEDs toggle sequentially while the system waits in Idle.
- The game starts when the player long-presses **P2.0** for approximately 2 seconds.
- Timer interrupt changes the state from Idle (`R4 = 3`) to In Game (`R4 = 2`).
- LEDs are turned off and the system jumps to Level 1.

---

### 3.3 In-Game State

**Labels:**  
`level_1`, `level_2`, `level_3`, `level_4`, `loop1`, `loop2`, `loop3`, `loop4`, `lost`, `win_check`  

**Subroutines:** `create_pattern`

#### 3.3.1 Level Initialization

Pattern length is calculated using difficulty level (`R5`):

- Level 1: `R6 = 2 + R5`
- Level 2: `R6 = 3 + R5`
- Level 3: `R6 = 4 + R5`

After completing Level 3, difficulty increases and all subsequent levels start with longer patterns.

---

#### 3.3.2 Game Flow

- **Input Detection:**  
  Button presses trigger interrupts. Pressed buttons are compared with the expected pattern.

- **Loss Condition:**  
  If an incorrect button is pressed, the player loses (`R4 = 0`).

- **Valid Move:**  
  Correct presses update progress and wait for the next input.

- **Win Condition:**  
  If the entire pattern is entered correctly, the player wins (`R4 = 1`) and the built-in green LED lights up.

---

### 3.3.3 Random Pattern Generation

- Random values are generated using **Timer A Counter**.
- `AND #0x0003` is applied to extract the last two bits.
- This produces values between **0–3**, corresponding to LEDs.
- The pattern array is filled with 16 random values.
- The array is used for LED display and input verification.

---

### 3.4 Delay Mechanism

- Delays are implemented using nested loops.

**Delay Subroutines:**
- `Delay`: Base delay (~0.2 seconds)
- `Delay_Difficult`: Shortens delay as difficulty increases
- `TwoSec_Delay`: Used after winning the game to light the green LED for 2 seconds

---

### 3.5 Interrupt Processing and Timing

**Port 2 ISR (`press_ISR`):**
- Detects falling edges from buttons.
- Compares pressed button with expected value from pattern array.
- Calls:
  - `win_check` for correct input
  - `lose` for incorrect input

**win_check:**
- Increments index registers (`R7`, `R8`)
- Checks if pattern is complete
- Sets game state to Win if successful

**lose:**
- Sets game state to Lost
- Flashes all LEDs three times

**Timer A Usage:**
- Random number generation
- Detecting long button press to start the game

---

## 4. Flowcharts

- The first flowchart illustrates the **main program flow**.
- The second flowchart illustrates **interrupt handling**.
- Core subroutines are shown for clarity, while basic delays and animations are omitted.

---

## Disclaimer

This project was developed for academic purposes as part of the **CENG 329** course.
