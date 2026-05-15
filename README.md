# Perception Breach Prototype

First-person cyberpunk space-horror immersive sim survival prototype in Godot 4.x.

This repository has pivoted away from the old 2D/mobile memory-dungeon prototype. The current target is a PC-first story-driven station survival game set inside a ruined off-world facility where hostile post-biological organisms pressure the survivor physically and cognitively.

The long-term structure is not "escape a short run and start over." The ultimate campaign goal is to escape the station. The expected full game length is roughly 5-10 hours, driven by scavenging, floor-by-floor traversal, route discovery, environmental storytelling, and repeated survivor loss. A survivor can die, but the station, dropped gear, repaired systems, broken doors, discovered routes, and story evidence persist.

## Current MVP Goal

Build a slower, deliberate first playable facility slice that proves the systems needed for a multi-floor station crawl.

The prototype should prove:

- Smooth first-person keyboard/mouse movement
- Lethal firearm feel
- Ballistic projectile shooting with enemy hit zones
- Clean weak-point kills
- Body-part player health with fast medical decisions
- Fair enemy sensing and pressure behavior
- A horde/threat director
- One readable mental corruption effect
- Floor traversal, found exits, death, successor handoff, predecessor recovery, and long-term escape scaffolding

This branch treats the usual immersive sim and sci-fi horror references as inspiration only. Creature, tool, weapon, and comms designs should stay original to this project.

## Design Pillars

- Bullets are dangerous for everyone.
- Enemies should not be fake bullet sponges.
- Difficulty comes from numbers, flanking, darkness, ammo pressure, injuries, mental corruption, and player panic.
- Enemies infer from world state: sight, sound, last known position, visible motion, and communicated pressure.
- Cognitive corruption creates tactical uncertainty, not random unfairness.
- Survivors are expendable, but the player should feel encouraged to play carefully and avoid losing ground.
- Meta-progression should mostly change the facility, not permanently buff survivor stats.
- The facility is persistent across survivor deaths: doors, routes, explored rooms, and damage should remember what happened.
- Immersive sim logic comes first: vents, crawlspaces, catwalks, broken doors, alternate routes, sound, light, enemy senses, and tool use should combine predictably.
- The story is mostly environmental because the playable character can change after any death.
- Each floor should have multiple believable paths upward or downward, including rare shortcuts that can skip several floors.

## Current Persistence Prototype

- Survivors are mortal, but the greybox facility stays alive after death.
- On survivor death, the scene does not reload. A new survivor enters from a weighted facility access point.
- Unexplored access points are more likely than already-used ones, but revisiting known access remains possible.
- Late in a facility session, entry weighting flattens as the station becomes more memorized.
- The new survivor briefly locks into a small FPS spawn intro based on how they entered.
- Access points scar, compromise, or block behind the new survivor, changing state permanently for the current facility session.
- Successor spawns have a low chance to bring immediate pursuers through the same access pressure point.
- If pursuers force the entry, the facility records a follow-through breach flag. This can open or complicate a route, but should never be the only way to unlock progress.
- Pressure doors are now physical bodies. They can be locked, jammed, sealed, opened by powered overrides, or forced open with enough damage/impulse.
- The previous survivor leaves a physical lost kit at the death location. It does not despawn.
- The first survivor starts with an earpiece. Later survivors must recover it from the predecessor kit to hear the outside contact again.
- Lost kits now preserve weapon state, wearable modules, lens damage, a generated last note, and a short route trace for route-mapper users.
- Kits decay across additional successor handoffs, and Surgeon-class enemies can consume part of their contents if they reach the body first.
- Every survivor gets a randomized starting loadout: background, ammo variance, and possible flashlight type.
- Flashlight states currently include none, handheld, vest-mounted, helmet-mounted, and weapon-mounted.
- Flashlights can also be found as physical equipment pickups in the facility.
- Hidden route records now exist for vents, crawlspaces, and catwalks, with placeholder geometry hints in the arena.
- Station route, lighting, door, module, environmental-kill, and economy catalogs now exist with multiple variants for content expansion.
- Successor entry selection now filters blocked access points and sealed-door rooms, with maintenance crawlspace fallback behavior.
- Lost kits preserve weapon identity, ammo type, resources, earpiece state, and build-item recovery instead of granting generic supplies.

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
- Buttons should affect real facility state, not just flavor text. Current override buttons can drive prototype door state.
- Economy should feel grounded. Favor salvage, batteries, oxygen, medical supplies, tools, and access credentials over abstract crafting currency.
- The outside contact is helpful while the earpiece link is trusted, but high corruption can distort messages or make the player reinterpret the contact as hostile.
- The player should not have innate HUD knowledge. Exact readouts come from found equipment, damaged equipment, or deliberate physical checks.

## Diegetic Display And Gear

Human eyes do not provide a HUD. The prototype now treats readouts as equipment:

- Diagnostic Glasses: enables vitals and stamina display.
- Ammo Link Receiver: glasses-side module for ammo display.
- Ammo Telemetry Transmitter: weapon-side attachment required before ammo can appear in the glasses.
- Brainwave Reader: glasses module for mental/cognitive state.
- Compass Module: glasses module for facing direction.
- Route Mapper: glasses module for floor-route and loadout context.
- Comms Transcriber: glasses module for earpiece subtitles.
- Reticle Lens: glasses module for projected crosshair.
- Sound Meter: glasses module for stealth-noise estimation.
- Low-Light Filter and Threat Classifier: future visual-analysis modules.
- Glasses use physical module slots, can overload their frame power budget, and can drain power cells when too many modules are active.
- Head hits can damage the glasses lens, leaving a diegetic cracked/warped overlay.
- Under heavy corruption, modules can contradict each other: sound, ammo, route text, and comms can drift or briefly report wrong states.

Without the relevant modules, the player must rely on physical behavior: magazine checks, weapon inspection, sound, light, body state, and memory.

## Station Crawl Systems

The station is planned as a sequence of floors with alternate traversal. Current route variants include:

- Main stairwell
- Service elevator
- Executive hidden lift
- Maintenance ladder riser
- Cargo hoist shaft
- Ventilation stack
- Exterior catwalk

Sector lighting can fail for at least ten grounded reasons, including missing fuses, tripped breakers, cut cables, offline generators, drained battery banks, flooded conduits, technician lockouts, burned transformers, station load shedding, and biological growth.

Current light restoration variants include:

- Replace a fuse
- Reset a breaker
- Patch a cable
- Slot a power cell
- Restart a generator
- Reroute power from an adjacent floor

Door problems are meant to have several routes through or around them. Current solution data covers access credentials, local override power, shooting lock housings, maintenance bypass, hidden routes, manual pry, shove/bash force, reverse motor, cutting charges, service-space bypass, cable patching, actuator replacement, and adjacent-floor power routing.

Some of those verbs now exist in the greybox: lock housings can be shot as specific hit zones, reverse-motor and cut-debris service panels open problem doors, and solver traces remain in the world. Sealed-door events can reveal nearby hidden-route records.

Environmental kill variants currently include:

- Volatile tank blast
- Electrical junction arc
- Steam main rupture
- Pressure dump
- Cargo crusher
- Coolant flood
- Security crossfire scaffold

Grounded economy items currently include:

- Fuse
- Power cell
- Cable spool
- Tool parts
- Access credential
- Cutting charge
- Medical stock
- Crash kit
- Field cauterizer pen
- Earpiece patch
- Suppressor wrap
- Magnetic puller
- Suit patch
- Match-grade rounds
- Boot grips
- Coolant canister
- Static charge
- Splint roll

Station module variants currently include habitation, medical, industrial, research, administration, and exterior works modules, each with multiple gameplay/story uses.

## Build And World Interaction Prototype

- `E`: use/push/interact with the object under the crosshair; on loose props, carry/set down
- `C`: cycle build/placeable item
- `G`: place selected item

Current placeable catalog:

- Barricade Panel: door block or hard cover
- Deployable Cover: low movable cover
- Trip Mine: contact blast trap
- Noise Lure: sound source to manipulate enemy attention
- Shock Pylon: short stun/impulse pulse
- Gap Brace: wedges gaps or slows route use
- Turret Frame: future repairable defense anchor
- Motion Sensor: future route alarm
- Glow Flare: light and attention manipulation
- Pressure Decoy: physical weight for buttons and physics puzzles

Current weapon families have data variants for sidearms, SMGs, assault rifles/carbines, LMGs, and thermal tools. The prototype can now spawn random survivor weapons and findable weapon pickups.

Weapon attachment variants currently include:

- Ammo telemetry transmitter
- Compact suppressor
- Port compensator
- Reflex sight
- Laser pointer
- Foregrip
- Extended magazine
- Quickpull magwell
- Weapon light
- Retention sling

Arm injuries now affect weapon handling. A compromised arm increases weapon instability and reload pressure; heavy impact to an arm can knock the weapon loose, especially without a retention sling.

Reloading with rounds still in a ballistic weapon now drops a recoverable partial magazine instead of deleting or magically preserving ammunition. Thermal tools build heat; abusive firing can burn the weapon arm.

Reloading preserves a chambered round when possible; manual ammo checks now describe chamber and magazine feel instead of abstract ammo buckets.

Dropped weapons are physical pickups with condition, ammo, chamber, and attachment state. Weapon condition decays from use and drops, attachments have durability, and suppressors wear out. Ammo telemetry enables glasses ammo readout but emits a small position-betraying ping.

Carry/throw props, bullet penetration on soft props, cover destruction, pressure-decoy buttons, coolant/electric combos, steam haze, and flare attraction now run through the shared world event logic.

Current enemy archetype data includes stalker husks, crawler husks, bleeders, carapace forms, echoes, howlers, sleeper pods, paired flankers, glasswalkers, surgeons, choirs, shellroots, and relay-voice threats. Not all have final art or full bespoke behavior yet, but the director can spawn varied stat/sense/armor profiles.

There is no countdown-based extraction. Horde pressure is a station awareness/survival problem, not a timed arena clear. The player leaves a floor by finding and using a believable route such as stairs, elevators, ladders, vents, hoists, or exterior paths.

Floor routes now transition the same persistent session instead of ending a short extraction run. The current prototype reuses the arena as a floor-content slice, refreshes hazards or pickups, and only ends the run when the final station escape floor is reached.

A basic procedural audio router now exists for gunshots, suppressed shots, reloads, magazine drops, interaction beeps, pickups, enemy grunts/attacks/deaths, hazards, doors, buttons, movement, comms, telemetry pings, and heartbeat. Mental corruption can replay real sound profiles from false positions, with a small chance that the "false" sound is backed by a real noise event.

## Prototype Controls

- `WASD`: move
- Mouse: look
- Left mouse: fire
- Right mouse: reserved for aiming behavior
- `Shift`: sprint
- `Alt`: stealth walk
- `Ctrl`: crouch
- `E`: use/push/interact; on loose props, carry or set down
- `F`: shove/bash a close enemy away from the weapon, or throw the carried prop
- `H`: manual magazine check
- `I`: inspect weapon and attachments
- `C`: cycle build item
- `G`: place selected build item
- `R`: reload, or restart after temporary floor-clear/death state
- `B`: quick bandage
- `T`: trauma kit, crash kit, or splint roll depending on inventory/injury
- `V`: pain injector
- `X`: tap neural stabilizer, hold cognitive anchor
- `F3`: debug overlay
- `Esc`: release mouse
- `Enter`: recapture mouse

## Active Architecture

- `scripts/MainSurvival.gd`: greybox arena, found exits, successor flow, and event wiring
- `scripts/core/GameEvents.gd`: run, threat, noise, kill, sound, and environment impulse events
- `scripts/core/InputBus.gd`: PC input helper
- `scripts/player/PlayerControllerFPS.gd`: first-person movement, camera, diegetic equipment display gating
- `scripts/player/PlayerHealthBodyParts.gd`: streamlined body-part injury model
- `scripts/weapons/WeaponData.gd`: weapon tuning data
- `scripts/weapons/WeaponController.gd`: muzzle-based firing, reload, ammo state, barrel interference
- `scripts/weapons/BallisticProjectile.gd`: physical projectile travel, drop, and impact handling
- `scripts/enemies/EnemyBase3D.gd`: shared enemy body, archetype setup, movement, attacks, and trait hooks
- `scripts/enemies/EnemyArchetypeCatalog.gd`: enemy archetype data for senses, armor, speed, health, and special traits
- `scripts/enemies/EnemyHealthHitZones.gd`: enemy damage model and weak points
- `scripts/enemies/EnemyHitZone3D.gd`: projectile-collidable weak-point zones
- `scripts/enemies/EnemySenses3D.gd`: fair sight/hearing/last-known-position sensing
- `scripts/enemies/EnemyDecisionStateMachine.gd`: chase/search/flank/attack decisions
- `scripts/systems/ThreatDirector.gd`: open-ended threat escalation based on time, noise, kills, and corruption
- `scripts/systems/MentalStateManager.gd`: perception corruption placeholder
- `scripts/systems/CommsManager.gd`: earpiece outsider contact and corruption-distorted comms
- `scripts/systems/HiddenRouteTrigger3D.gd`: crawl/vent/catwalk route interaction trigger
- `scripts/systems/DoorLockHousing3D.gd`: projectile-collidable door lock weak zone
- `scripts/systems/StationSystemsCatalog.gd`: route, power, door, economy, module, and environmental interaction variants
- `scripts/systems/StationRouteSystem.gd`: multi-floor station route/discovery scaffold
- `scripts/systems/SectorPowerSystem.gd`: sector lighting failure and restoration scaffold
- `scripts/systems/FacilityServiceNode3D.gd`: fuse boxes, breaker panels, route clues, and door service panels
- `scripts/systems/FacilityProgression.gd`: persistent rooms, doors, hidden routes, and facility-remembers meta-progression
- `scripts/systems/DynamicWorldSystem.gd`: shared impulse propagation for bullets, shove, traps, buttons, and dynamic props
- `scripts/systems/BuildPlacementSystem.gd`: player placeable/build catalog and placement
- `scripts/systems/PlaceableDevice3D.gd`: physical placed devices
- `scripts/systems/DynamicObject3D.gd`: throwable/pushable world props
- `scripts/systems/EquipmentPickup3D.gd`: findable flashlights, weapons, and grounded resource pickups
- `scripts/systems/EnvironmentalHazard3D.gd`: physical hazard actors that can kill enemies and injure the player
- `scripts/systems/AudioRouter.gd`: procedural placeholder 3D sound pipeline
- `scripts/systems/EffectMaterialCache.gd`: shared material cache for reactive surfaces and props
- `scripts/systems/FacilityDoor3D.gd`: physical door state, forced opening, and button override support
- `scripts/systems/LostSurvivorKit3D.gd`: recoverable predecessor kit and earpiece handoff
- `scripts/systems/DynamicButton3D.gd`: buttons that respond to use, bullets, impulses, and thrown objects
- `scripts/systems/ReactiveStaticBody3D.gd`: static geometry that can receive damage/impulse scars

## What Is Intentionally Gone

- Top-down/mobile room design
- Memory rooms
- Memory fragments
- Scan-button dungeon mechanics
- Time rewind
- Mobile export focus
- Final art, procedural generation, localization, and complex lore

## How To Run

Open the project in Godot 4.3 or a current Godot 4.x editor and run `res://scenes/PrototypeArena.tscn`.

Godot is not installed in this workspace environment, so engine-level validation still needs to happen in the editor.

Prototype smoke-test scaffold: `res://tests/SmokeTest.gd` boots the arena, kills the first survivor, and checks that a successor enters. Run it from a Godot 4.x command line/editor test setup once Godot is available locally.
