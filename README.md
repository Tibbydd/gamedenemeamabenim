# CURSOR: Fragments of the Forgotten

Top-down cyberpunk dungeon crawler where you play a "Cursor" hacker diving into the digital minds of the deceased to recover corrupted memories.

> Status: **v0.1 vertical slice.** Single room, one enemy, one hack tool, one fragment. Built to validate the core loop before scaling up.

## Engine & targets

- **Godot 4.3** (mobile renderer).
- Built for **iOS + Android** in portrait, runs unmodified on **Linux / Windows / macOS** for development.
- If mobile performance ever caps the design, the codebase is engine-portable enough to pivot to PC-first.

## How to run

1. Install Godot 4.3+ (the standard build, not the Mono build — no C# in this slice).
2. Open the project: `Godot4 --path .` or import `project.godot` from the editor.
3. Press F5 to run. The scene boots straight into `scenes/Main.tscn`.

## Controls

| Action       | Desktop                 | Mobile               |
|--------------|-------------------------|----------------------|
| Move         | WASD / Arrow keys       | Touch-drag anywhere  |
| Move (alt)   | Hold left mouse button  | —                    |
| Memory Scan  | `C` or `Space`          | On-screen SCAN button |
| Restart      | Any key after game end  | Any tap after game end |

Keyboard input wins over pointer input when both are active, so you can mix freely on desktop.

## What's in the slice

- **One hand-built room** with outer walls and three interior pillars (cover for the Scan to matter).
- **Player**: 100 HP, 100 energy, regen 14/s. 0.8s i-frames after a hit.
- **Memory Scan** hack tool: 30 energy, 2.5s cooldown, 360 px radius. Reveals fragments and pings enemies within range.
- **Memory fragment**: starts dim (alpha 0.18). Becomes visible + pulses when scanned. Walk over to collect.
- **Exit zone**: greyed out until the fragment is collected, then activates.
- **Corruptor** enemy: chases the player, deals 20 contact damage on touch.
- **Win**: collect fragment + reach exit → "MEMORY RECOVERED".
- **Lose**: HP hits 0 → "MIND LOST".

## Architecture

Three autoloads (singletons) glue everything together:

| Autoload        | Job                                                     |
|-----------------|---------------------------------------------------------|
| `InputBus`      | Cross-platform input: keyboard vector, pointer-held flag, `scan_pressed` signal |
| `SpriteFactory` | Procedural pixel-art texture generation, cached by key  |
| `GameEvents`    | Event bus: `fragment_collected`, `player_died`, `player_won`, `scan_emitted` |

Gameplay nodes wire to these via signals — there is no tight coupling between Player, Corruptor, Fragment, ExitZone, or HUD. Each subscribes to what it cares about.

### File layout

```
project.godot
scenes/
  Main.tscn            # Boots the slice. Hand-placed entities; walls built in code.
  Player.tscn          # CharacterBody2D + Sprite2D + Camera2D
  Corruptor.tscn       # CharacterBody2D + DamageZone Area2D
  MemoryFragment.tscn  # Area2D pickup, hidden until scanned
  ExitZone.tscn        # Area2D, arms on fragment_collected
  ScanPulse.tscn       # Transient visual for the scan ring
  HUD.tscn             # CanvasLayer with HP/energy bars, scan button, end overlay
scripts/
  main.gd
  autoload/
    input_bus.gd
    sprite_factory.gd
    game_events.gd
  player/player.gd
  enemies/corruptor.gd
  pickups/memory_fragment.gd
  pickups/exit_zone.gd
  systems/scan_pulse.gd
  ui/hud.gd
```

### Collision layers

| Bit | Layer    | Used by                          |
|-----|----------|----------------------------------|
| 1   | Player   | Player body                      |
| 2   | Enemies  | Corruptor body + DamageZone      |
| 3   | Walls    | StaticBody2D walls               |
| 4   | Pickups  | MemoryFragment, ExitZone         |

## What's deliberately not in the slice

- Procedural dungeon generation
- Other enemies (Looper, PhantomMemory)
- Other hack tools (Time Rewind, Code Injection)
- Memory reconstruction / ethical choice system
- Main menu and game-over scenes (we boot into gameplay; end overlay handles restart)
- Audio
- Save / load
- Localization (planned, deferred)

These are next on the roadmap once the slice feels good.

## Roadmap (high level)

1. Polish slice feel: scan SFX, hit feedback, end-screen transitions.
2. Add **Time Rewind** as the second hack tool — needs a position ring-buffer on Player.
3. Add **Looper** and **PhantomMemory** enemies.
4. Procedural room generator (start with rectangular rooms + corridors).
5. Multi-room dungeons with mind-profile theming.
6. Audio pass.
7. iOS + Android export setup and signing pipeline.

## Archive

The original v0 code (pre-rewrite, 6,300 lines) lives at the commit on `origin/main` (f2cdf74) and the local `v0-archive` ref. Don't delete `main` — that's the durable archive.
