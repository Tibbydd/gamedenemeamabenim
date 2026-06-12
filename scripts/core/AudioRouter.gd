extends Node

# Singleton audio dispatcher.
# play_3d() auto-detects wall occlusion via raycast and routes to "Muffled" bus.
# play_ui() for non-spatial HUD/action sounds.

const POOL_SIZE := 16
const MUFFLED_POOL_SIZE := 8
const UI_POOL_SIZE := 6

const ALIASES: Dictionary = {
	"movement": "footstep_soft",
	"loud_movement": "footstep_hard",
	"metal_movement": "footstep_metal",
	"wet_movement": "footstep_wet",
	"use_push": "interact",
	"use_air_push": "interact",
	"enemy_attack": "enemy_hit",
	"mag_drop": "reload_click",
	"sector_bulkhead_release": "door_open",
	"door_forced": "door_slam",
	"equipment_pickup": "pickup",
	"bone_fracture": "bone_crack",
	"hazard_steam": "cauterize",
	"injector_use": "injector",
	"alarm": "danger_alarm",
}

const UI_SOUND_IDS: Array[String] = [
	"heartbeat",
	"breath_exhale",
	"telemetry_ping",
	"comms",
	"tinnitus",
]

var _3d_pool: Array[AudioStreamPlayer3D] = []
var _muffled_pool: Array[AudioStreamPlayer3D] = []
var _ui_pool: Array[AudioStreamPlayer] = []
var _3d_cursor: int = 0
var _muffled_cursor: int = 0
var _ui_cursor: int = 0
var _player_ref: Node3D = null   # set by MainSurvival after player spawns

var _reverb_effect: AudioEffectReverb = null
var _reverb_bus_idx: int = -1
var _amplify_effect: AudioEffectAmplify = null
var _shepard_player: AudioStreamPlayer = null
var _tinnitus_tween: Tween = null

func _ready() -> void:
	# Clear bus on Master (index 0 always exists)
	# Create "Muffled" bus routed through Master with a low-pass filter
	var muffled_idx := AudioServer.bus_count
	AudioServer.add_bus(muffled_idx)
	AudioServer.set_bus_name(muffled_idx, "Muffled")
	AudioServer.set_bus_send(muffled_idx, "Master")
	var lpf := AudioEffectLowPassFilter.new()
	lpf.cutoff_hz = 680.0
	lpf.resonance = 0.5
	AudioServer.add_bus_effect(muffled_idx, lpf)

	# Create "Reverb" bus — 3D spatial sounds route here so rooms echo naturally
	_reverb_bus_idx = AudioServer.bus_count
	AudioServer.add_bus(_reverb_bus_idx)
	AudioServer.set_bus_name(_reverb_bus_idx, "Reverb")
	AudioServer.set_bus_send(_reverb_bus_idx, "Master")
	_reverb_effect = AudioEffectReverb.new()
	_reverb_effect.room_size = 0.3
	_reverb_effect.damping = 0.8
	_reverb_effect.wet = 0.0    # dry by default, updated per room
	_reverb_effect.dry = 1.0
	AudioServer.add_bus_effect(_reverb_bus_idx, _reverb_effect)

	# Clear primary pool (routed through Reverb so room acoustics apply)
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer3D.new()
		p.bus = "Reverb"
		p.max_distance = 48.0
		p.unit_size = 8.0
		add_child(p)
		_3d_pool.append(p)

	# Muffled pool — same spatial settings but on Muffled bus
	for i in range(MUFFLED_POOL_SIZE):
		var p := AudioStreamPlayer3D.new()
		p.bus = "Muffled"
		p.max_distance = 48.0
		p.unit_size = 8.0
		add_child(p)
		_muffled_pool.append(p)

	for i in range(UI_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_ui_pool.append(p)

	# AudioEffectAmplify on Master bus for tinnitus ducking
	_amplify_effect = AudioEffectAmplify.new()
	_amplify_effect.volume_db = 0.0
	AudioServer.add_bus_effect(0, _amplify_effect)

	# Dedicated looping Shepard tone player — volume driven by enemy proximity
	_shepard_player = AudioStreamPlayer.new()
	_shepard_player.bus = "Master"
	_shepard_player.volume_db = -80.0
	add_child(_shepard_player)
	var shepard_stream := SoundSynthesizer.get_stream("shepard_tone")
	if shepard_stream:
		_shepard_player.stream = shepard_stream
		_shepard_player.play()

	GameEvents.sound_requested.connect(_on_sound_requested)

func set_player_ref(player: Node3D) -> void:
	_player_ref = player

func set_shepard_volume(volume_db: float) -> void:
	if _shepard_player and is_instance_valid(_shepard_player):
		_shepard_player.volume_db = clamp(volume_db, -80.0, -8.0)

func trigger_tinnitus(duration: float = 8.0) -> void:
	if not _amplify_effect:
		return
	play_ui("tinnitus")
	_amplify_effect.volume_db = -22.0
	if _tinnitus_tween and _tinnitus_tween.is_valid():
		_tinnitus_tween.kill()
	_tinnitus_tween = create_tween()
	_tinnitus_tween.tween_property(_amplify_effect, "volume_db", 0.0, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func set_room_reverb(room_size: float, damping: float, wet: float) -> void:
	if not _reverb_effect:
		return
	_reverb_effect.room_size = clamp(room_size, 0.1, 1.0)
	_reverb_effect.damping = clamp(damping, 0.1, 1.0)
	_reverb_effect.wet = clamp(wet, 0.0, 0.6)

func _on_sound_requested(sound_id: String, position: Vector3, _intensity: float) -> void:
	var resolved: String = String(ALIASES.get(sound_id, sound_id))
	if SoundSynthesizer.get_stream(resolved) == null:
		resolved = _resolve_fallback_sound(sound_id)
	if _is_ui_sound(sound_id):
		play_ui(resolved)
	else:
		play_3d(resolved, position)

func _resolve_fallback_sound(sound_id: String) -> String:
	if sound_id.begins_with("hazard_") or sound_id.begins_with("pressure_dump"):
		return "enemy_death"
	if sound_id == "door_forced" or sound_id == "sector_bulkhead_release" or sound_id.begins_with("door_forced"):
		return "door_slam"
	if sound_id in ["button", "telemetry_ping", "heartbeat", "comms"] or sound_id.begins_with("equipment_pickup"):
		return "pickup"
	if sound_id == "reload" or sound_id.begins_with("reload_"):
		return "reload_mag_in"
	if sound_id == "gunshot" or sound_id.begins_with("gunshot_"):
		return "gunshot_light"
	return "interact"

func _is_ui_sound(sound_id: String) -> bool:
	return UI_SOUND_IDS.has(sound_id)

# Returns true if there is a wall (StaticBody3D layer 1) between world_position and the player.
func _is_occluded(world_position: Vector3) -> bool:
	if not _player_ref or not is_instance_valid(_player_ref):
		return false
	var space := _player_ref.get_world_3d().direct_space_state
	if not space:
		return false
	var target := _player_ref.global_position + Vector3.UP * 1.2
	var query := PhysicsRayQueryParameters3D.create(world_position, target)
	query.collision_mask = 1  # static world geometry only
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return false
	# If hit collider is the player itself, not occluded
	var col = hit.get("collider")
	return col != _player_ref

func play_3d(sound_id: String, world_position: Vector3, pitch_scale: float = 1.0) -> void:
	var stream: AudioStream = SoundSynthesizer.get_stream(sound_id)
	if stream == null:
		return
	var occluded := _is_occluded(world_position)
	if occluded:
		var player := _muffled_pool[_muffled_cursor % MUFFLED_POOL_SIZE]
		_muffled_cursor += 1
		player.stream = stream
		player.global_position = world_position
		player.pitch_scale = pitch_scale * randf_range(0.93, 1.07)
		player.play()
	else:
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
