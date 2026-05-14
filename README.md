# Perception Breach Prototype

First-person cyberpunk space-horror roguelite horde shooter prototype in Godot 4.x.

This repository has pivoted away from the old 2D/mobile memory-dungeon prototype. The current target is a PC-first greybox survival test set inside a ruined off-world colony facility where hostile post-biological organisms pressure the survivor physically and cognitively.

## Current MVP Goal

Build a 3-minute first playable survival scenario in one greybox arena.

The prototype should prove:

- Smooth first-person keyboard/mouse movement
- Lethal firearm feel
- Ballistic projectile shooting with enemy hit zones
- Clean weak-point kills
- Body-part player health with fast medical decisions
- Fair enemy sensing and pressure behavior
- A horde/threat director
- One readable mental corruption effect
- Extraction, survival, death, successor handoff, and restart states

## Design Pillars

- Bullets are dangerous for everyone.
- Enemies should not be fake bullet sponges.
- Difficulty comes from numbers, flanking, darkness, ammo pressure, injuries, mental corruption, and player panic.
- Enemies infer from world state: sight, sound, last known position, visible motion, and communicated pressure.
- Cognitive corruption creates tactical uncertainty, not random unfairness.
- Roguelite meta-progression should mostly change the facility, not permanently buff survivor stats.
- The facility is persistent across survivor deaths: doors, routes, explored rooms, and damage should remember what happened.
- Immersive sim logic comes first: vents, crawlspaces, catwalks, broken doors, alternate routes, sound, light, enemy senses, and tool use should combine predictably.

## Current Persistence Prototype

- Survivors are mortal, but the greybox facility stays alive after death.
- On survivor death, the scene does not reload. A new survivor enters from a weighted facility access point.
- Unexplored access points are more likely than already-used ones, but revisiting known access remains possible.
- Late in a facility session, entry weighting flattens as the station becomes more memorized.
- The new survivor briefly locks into a small FPS spawn intro based on how they entered.
- Access points scar, compromise, or block behind the new survivor, changing state permanently for the current facility session.
- Successor spawns can bring immediate pursuers through the same access pressure point.
- The previous survivor leaves a physical lost kit at the death location, but the next survivor may not know where that is yet.
- Hidden route records now exist for vents, crawlspaces, and catwalks, with placeholder geometry hints in the arena.

Current survivor entry scenarios:

- Hab pressure door
- Emergency airlock tumble
- Maintenance crawlspace
- Ceiling catwalk drop
- Broken reactor vent
- Crashed cargo lift
- Elevator shaft ladder
- Buckled floor hatch
- Cracked med pod
- Overhead service pipe
- Hull breach lock
- Waste chute spill

## Immersive Sim Direction

- Locked doors should be problems, not binary blockers.
- A route can go nowhere, lead behind a locked door, expose a safer angle, reveal story evidence, or contain tools and equipment.
- Small spaces should be tactically meaningful: limited turning room, awkward reloads, barrel obstruction, sound risk, and enemy ambush pressure.
- Door states should be physical and consequential: locked, jammed, sealed, powered, cut open, bypassed, or made worse by panic.
- Player decisions should leave facility-state traces that future survivors inherit.
- Dynamic interaction is central: bullets, shove, use, explosions, thrown objects, buttons, cover, and placeables should all affect nearby systems through consistent world-state rules.
- Physical objects should be able to trigger controls, including buttons hit by projectiles or thrown props.

## Build And World Interaction Prototype

- `E`: use/push/interact with the object under the crosshair
- `C`: cycle build/placeable item
- `G`: place selected item

Current placeable catalog:

- Barricade Panel: door block or hard cover
- Deployable Cover: low movable cover
- Trip Mine: contact blast trap
- Noise Lure: sound source to manipulate enemy attention
- Shock Pylon: short stun/impulse pulse
- Foam Seal: plugs gaps or slows route use
- Turret Frame: future repairable defense anchor
- Motion Sensor: future route alarm
- Glow Flare: light and attention manipulation
- Pressure Decoy: physical weight for buttons and physics puzzles

## Prototype Controls

- `WASD`: move
- Mouse: look
- Left mouse: fire
- Right mouse: reserved for aiming behavior
- `Shift`: sprint
- `Ctrl`: crouch
- `E`: use/push/interact
- `F`: shove/bash a close enemy away from the weapon
- `C`: cycle build item
- `G`: place selected build item
- `R`: reload, or restart after extraction/survival end state
- `B`: quick bandage
- `T`: trauma kit
- `V`: pain injector
- `X`: neural stabilizer
- `Esc`: release mouse
- `Enter`: recapture mouse

## Active Architecture

- `scripts/MainSurvival.gd`: greybox arena, extraction, run loop
- `scripts/core/GameEvents.gd`: run, threat, noise, kill, extraction events
- `scripts/core/InputBus.gd`: PC input helper
- `scripts/player/PlayerControllerFPS.gd`: first-person movement, camera, HUD
- `scripts/player/PlayerHealthBodyParts.gd`: streamlined body-part injury model
- `scripts/weapons/WeaponData.gd`: weapon tuning data
- `scripts/weapons/WeaponController.gd`: muzzle-based firing, reload, ammo state, barrel interference
- `scripts/weapons/BallisticProjectile.gd`: physical projectile travel, drop, and impact handling
- `scripts/enemies/EnemyBase3D.gd`: basic parasite-husk enemy
- `scripts/enemies/EnemyHealthHitZones.gd`: enemy damage model and weak points
- `scripts/enemies/EnemyHitZone3D.gd`: projectile-collidable weak-point zones
- `scripts/enemies/EnemySenses3D.gd`: fair sight/hearing/last-known-position sensing
- `scripts/enemies/EnemyDecisionStateMachine.gd`: chase/search/flank/attack decisions
- `scripts/systems/ThreatDirector.gd`: timed horde escalation
- `scripts/systems/MentalStateManager.gd`: perception corruption placeholder
- `scripts/systems/FacilityProgression.gd`: persistent rooms, doors, hidden routes, and facility-remembers meta-progression
- `scripts/systems/DynamicWorldSystem.gd`: shared impulse propagation for bullets, shove, traps, buttons, and dynamic props
- `scripts/systems/BuildPlacementSystem.gd`: player placeable/build catalog and placement
- `scripts/systems/PlaceableDevice3D.gd`: physical placed devices
- `scripts/systems/DynamicObject3D.gd`: throwable/pushable world props
- `scripts/systems/DynamicButton3D.gd`: buttons that respond to use, bullets, impulses, and thrown objects
- `scripts/systems/ReactiveStaticBody3D.gd`: static geometry that can receive damage/impulse scars

## What Is Intentionally Gone

- Top-down/mobile room design
- Memory rooms
- Memory fragments
- Scan-button dungeon mechanics
- Time rewind
- Mobile export focus
- Final art, procedural generation, save/load, localization, and complex lore

## How To Run

Open the project in Godot 4.3 or a current Godot 4.x editor and run `res://scenes/PrototypeArena.tscn`.

Godot is not installed in this workspace environment, so engine-level validation still needs to happen in the editor.
