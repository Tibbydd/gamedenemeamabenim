extends Node

# Singleton audio dispatcher. Call play_3d() for positional sounds,
# play_ui() for non-spatial HUD/action sounds.
# Pools AudioStreamPlayer3D nodes to avoid per-shot allocations.
# Connects to GameEvents.sound_requested to handle engine-wide audio requests.

const POOL_SIZE := 16
const UI_POOL_SIZE := 6

# Maps GameEvents sound IDs to SoundSynthesizer IDs
const ALIASES: Dictionary = {
	"movement": "footstep_soft",
	"loud_movement": "footstep_hard",
	"use_push": "interact",
	"use_air_push": "interact",
	"enemy_grunt": "enemy_alert",
	"enemy_windup": "enemy_alert",
	"enemy_attack": "enemy_alert",
	"mag_drop": "reload_click",
}

var _3d_pool: Array[AudioStreamPlayer3D] = []
var _ui_pool: Array[AudioStreamPlayer] = []
var _3d_cursor: int = 0
var _ui_cursor: int = 0

func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer3D.new()
		p.bus = "Master"
		p.max_distance = 48.0
		p.unit_size = 8.0
		add_child(p)
		_3d_pool.append(p)
	for i in range(UI_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_ui_pool.append(p)
	GameEvents.sound_requested.connect(_on_sound_requested)

func _on_sound_requested(sound_id: String, position: Vector3, _intensity: float) -> void:
	var resolved := ALIASES.get(sound_id, sound_id) as String
	play_3d(resolved, position)

func play_3d(sound_id: String, world_position: Vector3, pitch_scale: float = 1.0) -> void:
	var stream: AudioStream = SoundSynthesizer.get_stream(sound_id)
	if stream == null:
		return
	var player := _3d_pool[_3d_cursor % POOL_SIZE]
	_3d_cursor += 1
	player.stream = stream
	player.global_position = world_position
	player.pitch_scale = pitch_scale * randf_range(0.93, 1.07)
	player.play()

func play_ui(sound_id: String, pitch_scale: float = 1.0) -> void:
	var stream: AudioStream = SoundSynthesizer.get_stream(sound_id)
	if stream == null:
		return
	var player := _ui_pool[_ui_cursor % UI_POOL_SIZE]
	_ui_cursor += 1
	player.stream = stream
	player.pitch_scale = pitch_scale * randf_range(0.96, 1.04)
	player.play()
