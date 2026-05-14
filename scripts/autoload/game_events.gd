extends Node

# Lightweight event bus for cross-scene communication.

signal fragment_collected
signal player_died
signal player_won
signal scan_emitted(world_position: Vector2, radius: float)
