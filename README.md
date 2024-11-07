# RISC-V Snake Game 🐍

A classic Snake game implementation in RISC-V Assembly language. The game features a snake that grows as it eats food, navigates through obstacles, and must avoid colliding with walls and itself.

## 🎮 Game Features

- Classic snake movement mechanics (ZQSD controls)
- Growing snake length when eating food
- Random food spawning system
- Obstacle system with:
  - Border walls
  - Random internal obstacles
- Progressive difficulty (snake speeds up as it grows)
- Score tracking through snake length
- Victory condition when reaching maximum length
- Collision detection with:
  - Walls
  - Obstacles
  - Snake's own body

## 🕹️ Controls

- Z: Move Up
- S: Move Down
- Q: Move Left
- D: Move Right

## 🎯 Game Objectives

- Guide the snake to eat the food (green pixels)
- Avoid hitting:
  - Blue border walls
  - Yellow internal obstacles
  - The snake's own body (red)
- Grow your snake to the maximum length to win

## 🛠️ Technical Implementation

The game is implemented in RISC-V Assembly and includes several key components:

- Display system using bitmap display
- Queue data structure for snake body management
- Random obstacle generation
- Collision detection system
- Keyboard input handling
- Dynamic speed adjustment

## 🚀 Memory Structure

The game uses the following memory organization:
- Display address: `0x10010000`
- Data segment: `0x10007000`
- Custom data structures for:
  - Snake queue
  - Obstacle array
  - Game state variables

## ⚙️ Running the Game

To run this game, you'll need:
1. RISC-V simulator/emulator
2. Bitmap display configuration:
   - Unit Width: 16
   - Unit Height: 16
   - Display Width: 256
   - Display Height: 256
   - Base Address: `0x10010000`
3. Keyboard input system for MMIO at address `0xffff0000`

## 🏆 Game End Conditions

The game can end in three ways:
1. Victory: Snake reaches maximum length
2. Collision with obstacles
3. Collision with snake's own body

## 🎨 Color Scheme

- Snake body: Red
- Food: Green
- Border walls: Blue
- Internal obstacles: Yellow

---
Made with 🎮 in RISC-V Assembly
