# SysMeter 📊

SysMeter is a lightweight, native macOS menu bar application written purely in Swift. Inspired by minimalist tools like Pomodori, SysMeter lives entirely in your Mac's status bar (with no dock icon!) and provides real-time, low-level insights into your system's resource usage.

## Features
* **Dual Menu Bar View**: View CPU load and RAM percentage side-by-side, or toggle them individually.
* **Low-Level Accuracy**: Utilizes macOS Mach kernel APIs (`host_processor_info` and `host_statistics64`) for true real-time hardware data.
* **Activity Monitor Layout**: Click the menu bar icon for a detailed, familiar breakdown of Physical Memory, App Memory, Wired Memory, and Swap.
* **Customizable Refresh Rate**: Choose between 1, 2, or 5-second polling intervals.
* **No Xcode Required**: Builds entirely from the terminal using a custom shell script.

## Requirements
* macOS 13.0 (Ventura) or later
* Swift 5.7+ (Included with Xcode Command Line Tools)

## Preview
![alt text](image.png)

## Customization 
![alt text](image-1.png)

## Installation & Setup

You can build and run SysMeter directly from your terminal without opening Xcode.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/BogdanAlinTudorache/sysMeter.git
   cd sysMeter
   ```

2. **Make the build script executable (first time only):**
   ```bash
   chmod +x build.sh
   ```

3. **Build the app:**
   ```bash
   ./build.sh
   ```

4. **Run it directly:**
   ```bash
   open build/SysMeter.app
   ```

5. **(Optional) Install to your Applications folder:**
   ```bash
   cp -r build/SysMeter.app /Applications/
   ```

## Customization
Click the SysMeter icon in your menu bar, then click the **gear icon** to open the settings view. Your preferences are saved automatically using standard macOS `UserDefaults`.
