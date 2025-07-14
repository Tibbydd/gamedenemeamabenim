# CURSOR: Fragments of the Forgotten

**An isometric pixel-art dungeon crawler for Android where players hack into digital minds of forgotten civilizations.**

## 🎮 Game Overview

In CURSOR: Fragments of the Forgotten, players take on the role of "Cursor" hackers who enter the digital minds of deceased individuals to clean corrupted mental data and recover lost memories. Navigate through procedurally generated dungeons that reflect the emotional states of forgotten souls.

### 🚀 Key Features

- **🧠 Mind-Based Dungeons**: Explore procedurally generated levels based on emotional profiles (regret, anger, melancholy, fear, joy, trauma)
- **🔧 Cursor Hacking Tools**: 
  - **Time Rewind (CTRL-Z)**: Restore previous state
  - **Code Injection**: Boost abilities and bypass defenses  
  - **Memory Scan**: Reveal hidden fragments and secrets
- **🧩 Memory Puzzle System**: Collect and reconstruct fragmented memories with ethical decision-making
- **📱 Touch-Optimized Controls**: Drag-to-move interface designed for mobile devices
- **🎨 Dynamic Visual Effects**: Cyberpunk aesthetics with procedural sprite generation
- **🤖 Advanced AI Enemies**: Three unique enemy types with sophisticated behaviors
- **🌈 Emotional Theming**: Environment colors, music, and atmosphere adapt to psychological states

## 🏗️ Technical Architecture

### Core Systems

#### � **GameManager** (Singleton)
- Game state management and progression tracking
- Player statistics and save/load functionality
- Session management and ethical choice recording

#### 🗺️ **DungeonGenerator** (Singleton)  
- Procedural level generation based on mind profiles
- Room-based layout with emotional distribution
- Dynamic tile placement and corridor connections

#### 🧠 **MemorySystem** (Singleton)
- Memory fragment collection and reconstruction
- Turkish language content generation
- Ethical dilemma creation and choice tracking

#### ⚙️ **HackingSystem** (Singleton)
- Cursor tool implementation and cooldown management
- Time rewind buffer system with state snapshots
- Code injection mini-games and effect application

#### 🎨 **SpriteGenerator** (Singleton)
- Real-time pixel art generation for all game elements
- Emotion-based color schemes and corruption effects
- Dynamic sprite creation for walls, floors, entities

#### ✨ **EffectsManager** (Singleton)
- Comprehensive visual effects library (15+ effects)
- Cyberpunk UI styling system
- Particle systems and screen effects

### 🎭 Character Systems

#### � **Player (Cursor)**
- Touch-based movement with collision detection
- Health/energy management and damage system
- Digital trail effects and interaction handling
- Rewind state management for time manipulation

#### � **Enemy AI System**
- **Corruptor**: Aggressive pursuer with corruption spreading
- **Looper**: Pattern-recording enemy that creates temporal echoes
- **PhantomMemory**: Ethereal entity that steals memories and phases through walls

#### 🧩 **Memory Fragments**
- Interactive collectibles with Turkish cultural content
- Professional and emotional context generation
- Reconstruction weight system for puzzle completion

## 🎮 Gameplay Flow

1. **🏠 Main Menu**: Cyberpunk-styled interface with settings
2. **🌊 Neural Dive**: Enter a randomly generated mind
3. **🏃 Exploration**: Navigate dungeons using touch controls
4. **⚔️ Combat**: Use hack tools to defeat corrupted entities
5. **� Collection**: Gather memory fragments throughout levels
6. **🤔 Ethical Choices**: Decide fate of recovered memories
7. **� Results**: View statistics and make final decisions
8. **🔄 Progression**: Return to surface or dive deeper

## �️ Development Features

### 🔧 **Error Handling & Robustness**
- Comprehensive null-checking and validation
- Fallback systems for missing data
- Graceful degradation when components fail

### � **Mobile Optimization** 
- Touch-first interface design
- Appropriate collision layers and physics
- Android-optimized rendering and controls

### 🎨 **Visual Polish**
- No placeholder graphics - everything procedurally generated
- Consistent cyberpunk aesthetic throughout
- Smooth animations and particle effects

### 🎵 **Audio Framework**
- Volume control system (Master/SFX)
- Audio bus configuration ready for sound implementation

## 🚀 Getting Started

### Prerequisites
- Godot 4.3 or later
- Android SDK (for mobile deployment)

### Installation
1. Clone this repository
2. Open the project in Godot 4.3+
3. Set up Android export template (optional)
4. Run the project

### Controls
- **Touch/Drag**: Move cursor
- **Z Key**: Time Rewind hack tool
- **X Key**: Code Injection hack tool  
- **C Key**: Memory Scan hack tool
- **ESC**: Pause/Resume game
- **Enter/Space**: Accept (menus)

## 📁 Project Structure

```
CURSOR/
├── scenes/
│   ├── Main.tscn          # Main game scene
│   ├── Menu.tscn          # Main menu
│   └── GameOver.tscn      # End game screen
├── scripts/
│   ├── singletons/        # Core game systems
│   ├── player/            # Player controller
│   ├── enemies/           # AI enemy types  
│   ├── systems/           # Generation & effects
│   └── ui/                # Interface scripts
└── assets/
    └── icons/             # Game icons
```

## 🌟 Key Innovations

- **🧠 Psychological Dungeon Design**: Levels reflect human emotional states
- **🔄 Temporal Mechanics**: Time rewind system with state management
- **🎨 Real-time Art Generation**: No pre-made sprites required
- **📖 Cultural Storytelling**: Turkish language memories and narratives
- **⚖️ Ethical Gameplay**: Meaningful choices about digital consciousness
- **📱 Mobile-First Design**: Built specifically for touch interaction

## 🔮 Future Enhancements

- � Dynamic soundtrack based on emotional states
- 🗣️ Voice acting for memory fragments  
- 🌐 Multiplayer collaborative hacking
- 🎯 Achievement system and progression trees
- 📊 Analytics dashboard for memory choices
- 🔧 Level editor for custom minds

## 📄 License

This project is available for educational and personal use. Commercial use requires permission.

## 🙏 Acknowledgments

- Built with Godot Engine 4.3
- Inspired by cyberpunk aesthetics and psychological exploration
- Turkish cultural elements and storytelling traditions

---

**CURSOR: Fragments of the Forgotten** - *Enter the digital minds of the forgotten. Hack • Explore • Remember*

*Version Alpha 1.0 - Neural Dive Ready*