extends Node

# Procedurally synthesized SFX using AudioStreamWAV PCM.
# Generates buffers once at startup; AudioRouter plays them by ID.

const SAMPLE_RATE := 22050
var sounds: Dictionary = {}

func _ready() -> void:
	sounds["gunshot_light"] = _make_stream(_synth_gunshot(0.18, 0.22, 520.0))
	sounds["gunshot_heavy"] = _make_stream(_synth_gunshot(0.28, 0.32, 280.0))
	sounds["gunshot_thermal"] = _make_stream(_synth_gunshot_thermal())
	sounds["suppressed_gunshot"] = _make_stream(_synth_suppressed_gunshot())
	sounds["footstep_hard"] = _make_stream(_synth_footstep(0.08, 1100.0))
	sounds["footstep_soft"] = _make_stream(_synth_footstep(0.06, 640.0))
	sounds["footstep_metal"] = _make_stream(_synth_footstep_metal())
	sounds["footstep_wet"] = _make_stream(_synth_footstep_wet())
	sounds["enemy_alert"] = _make_stream(_synth_alert())
	sounds["enemy_death"] = _make_stream(_synth_death())
	sounds["enemy_hit"] = _make_stream(_synth_enemy_hit())
	sounds["enemy_heavy_hit"] = _make_stream(_synth_enemy_heavy_hit())
	sounds["howler_death"] = _make_stream(_synth_howler_death())
	sounds["reload_click"] = _make_stream(_synth_click(0.055, 1800.0))
	sounds["reload_mag_out"] = _make_stream(_synth_reload_mag_out())
	sounds["reload_mag_in"] = _make_stream(_synth_reload_mag_in())
	sounds["interact"] = _make_stream(_synth_click(0.04, 2200.0))
	sounds["pickup"] = _make_stream(_synth_pickup())
	sounds["ambient_hum"] = _make_stream(_synth_ambient_hum())
	sounds["ambient_drip"] = _make_stream(_synth_ambient_drip())
	sounds["ambient_clank"] = _make_stream(_synth_ambient_clank())
	sounds["ambient_electric"] = _make_stream(_synth_ambient_electric())
	sounds["ambient_pipe_groan"] = _make_stream(_synth_ambient_pipe_groan())
	sounds["ambient_distant_impact"] = _make_stream(_synth_ambient_distant_impact())
	sounds["objective_complete"] = _make_stream(_synth_objective_complete())
	sounds["extraction_beacon"] = _make_stream(_synth_extraction_beacon())
	sounds["door_open"] = _make_stream(_synth_door_open())
	sounds["door_slam"] = _make_stream(_synth_door_slam())
	sounds["danger_alarm"] = _make_stream(_synth_danger_alarm())
	sounds["bone_crack"] = _make_stream(_synth_bone_crack())
	sounds["cauterize"] = _make_stream(_synth_cauterize())
	sounds["injector"] = _make_stream(_synth_injector())
	sounds["enemy_grunt"] = _make_stream(_synth_enemy_grunt())
	sounds["enemy_detect"] = _make_stream(_synth_enemy_detect())
	sounds["enemy_search"] = _make_stream(_synth_enemy_search())
	sounds["enemy_windup"] = _make_stream(_synth_enemy_windup())
	sounds["heartbeat"] = _make_stream(_synth_heartbeat())
	sounds["breath_exhale"] = _make_stream(_synth_breath_exhale())
	sounds["shepard_tone"] = _make_shepard_stream()
	sounds["tinnitus"] = _make_stream(_synth_tinnitus())

func get_stream(sound_id: String) -> AudioStream:
	return sounds.get(sound_id, null)

# ── Synthesis helpers ─────────────────────────────────────────────────────────

func _make_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	# Convert float32 → int16 PCM bytes
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v := int(clamp(samples[i], -1.0, 1.0) * 32767.0)
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	stream.data = bytes
	return stream

func _synth_gunshot(duration: float, noise_decay: float, tone_hz: float) -> PackedFloat32Array:
	var n := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t / noise_decay)
		var noise := randf_range(-1.0, 1.0)
		var tone := sin(TAU * tone_hz * t) * exp(-t * 28.0)
		samples[i] = (noise * 0.72 + tone * 0.38) * env * 0.85
	return samples

func _synth_gunshot_thermal() -> PackedFloat32Array:
	var duration := 0.38
	var n := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t / 0.18) * (1.0 - exp(-t * 60.0))
		var whoosh := sin(TAU * lerp(320.0, 80.0, t / duration) * t)
		var crackle := randf_range(-1.0, 1.0) * exp(-t * 8.0)
		samples[i] = (whoosh * 0.55 + crackle * 0.45) * env * 0.88
	return samples

func _synth_footstep(duration: float, freq: float) -> PackedFloat32Array:
	var n := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t / (duration * 0.28))
		var click := sin(TAU * freq * t) * exp(-t * 90.0)
		var thud := sin(TAU * (freq * 0.18) * t) * exp(-t * 25.0)
		samples[i] = (click * 0.5 + thud * 0.5 + randf_range(-0.15, 0.15) * exp(-t * 40.0)) * env
	return samples

func _synth_alert() -> PackedFloat32Array:
	var duration := 0.55
	var n := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t / 0.22) * smoothstep(0.0, 0.02, t)
		var rise: float = lerp(180.0, 680.0, clamp(t / 0.18, 0.0, 1.0))
		var tone := sin(TAU * rise * t)
		var growl := sin(TAU * 95.0 * t) * 0.4
		samples[i] = (tone * 0.6 + growl + randf_range(-0.08, 0.08)) * env * 0.75
	return samples

func _synth_death() -> PackedFloat32Array:
	var duration := 0.48
	var n := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t / 0.18)
		var thud := sin(TAU * 60.0 * t) * exp(-t * 12.0)
		var noise := randf_range(-1.0, 1.0) * exp(-t * 18.0)
		samples[i] = (thud * 0.65 + noise * 0.35) * env * 0.82
	return samples

func _synth_howler_death() -> PackedFloat32Array:
	var duration := 0.72
	var n := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := (1.0 - t / duration) * smoothstep(0.0, 0.03, t)
		var shriek: float = sin(TAU * lerp(480.0, 120.0, t / duration) * t)
		var growl := sin(TAU * 88.0 * t) * 0.55
		samples[i] = (shriek * 0.55 + growl + randf_range(-0.12, 0.12) * exp(-t * 5.0)) * env * 0.78
	return samples

func _synth_click(duration: float, freq: float) -> PackedFloat32Array:
	var n := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t / (duration * 0.3))
		samples[i] = sin(TAU * freq * t) * env * 0.65
	return samples

func _synth_ambient_hum() -> PackedFloat32Array:
	var duration: float = 3.2
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var edge_fade: float = smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(duration - 0.08, duration, t))
		samples[i] = (
			sin(TAU * 48.0 * t) * 0.18
			+ sin(TAU * 52.0 * t) * 0.12
			+ randf_range(-0.04, 0.04) * exp(-t * 0.5)
		) * edge_fade
	return samples

func _synth_ambient_drip() -> PackedFloat32Array:
	var duration: float = 0.28
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		samples[i] = (
			sin(TAU * 620.0 * t) * exp(-t * 18.0) * 0.45
			+ sin(TAU * 310.0 * t) * exp(-t * 8.0) * 0.22
		)
	return samples

func _synth_ambient_clank() -> PackedFloat32Array:
	var duration: float = 0.55
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		samples[i] = (
			sin(TAU * 88.0 * t) * exp(-t * 6.0) * 0.55
			+ randf_range(-1.0, 1.0) * exp(-t * 22.0) * 0.35
		)
	return samples

func _synth_ambient_electric() -> PackedFloat32Array:
	var duration: float = 0.38
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		samples[i] = (
			randf_range(-1.0, 1.0) * exp(-t * 4.0) * 0.42
			+ sin(TAU * 280.0 * t) * exp(-t * 12.0) * 0.28
		)
	return samples

func _synth_objective_complete() -> PackedFloat32Array:
	var duration: float = 0.54
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var tones: Array[float] = [420.0, 560.0, 740.0]
	var burst_duration: float = 0.12
	var gap_duration: float = 0.06
	for tone_index in range(tones.size()):
		var start_time: float = float(tone_index) * (burst_duration + gap_duration)
		var start_sample: int = int(start_time * SAMPLE_RATE)
		var burst_samples: int = int(burst_duration * SAMPLE_RATE)
		for sample_offset in range(burst_samples):
			var sample_index: int = start_sample + sample_offset
			if sample_index >= n:
				break
			var t: float = float(sample_offset) / float(SAMPLE_RATE)
			samples[sample_index] = sin(TAU * tones[tone_index] * t) * exp(-t * 28.0) * 0.62
	return samples

func _synth_extraction_beacon() -> PackedFloat32Array:
	var duration: float = 0.72
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var sweep: float = lerp(180.0, 440.0, t / duration)
		var env: float = smoothstep(0.0, 0.04, t) * (1.0 - smoothstep(0.68, 0.72, t))
		samples[i] = (sin(TAU * sweep * t) * 0.55 + sin(TAU * 92.0 * t) * 0.22) * env
	return samples

func _synth_door_open() -> PackedFloat32Array:
	var duration: float = 0.42
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		samples[i] = (
			randf_range(-1.0, 1.0) * 0.58 * exp(-t * 5.0)
			+ sin(TAU * 72.0 * t) * 0.38 * exp(-t * 8.0)
		)
	return samples

func _synth_suppressed_gunshot() -> PackedFloat32Array:
	var duration: float = 0.22
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t / 0.06) * (1.0 - exp(-t * 180.0))
		var subsonic: float = sin(TAU * 95.0 * t) * exp(-t * 22.0)
		var thump: float = randf_range(-1.0, 1.0) * exp(-t * 28.0)
		var hiss: float = randf_range(-1.0, 1.0) * exp(-t * 6.0) * 0.18
		samples[i] = (subsonic * 0.52 + thump * 0.38 + hiss) * env * 0.58
	return samples

func _synth_footstep_metal() -> PackedFloat32Array:
	var duration: float = 0.14
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t / (duration * 0.22))
		var ring: float = sin(TAU * 1400.0 * t) * exp(-t * 55.0)
		var clank: float = randf_range(-1.0, 1.0) * exp(-t * 62.0)
		var resonance: float = sin(TAU * 280.0 * t) * exp(-t * 18.0)
		samples[i] = (ring * 0.45 + clank * 0.38 + resonance * 0.22) * env
	return samples

func _synth_footstep_wet() -> PackedFloat32Array:
	var duration: float = 0.12
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t / (duration * 0.35))
		var squish: float = randf_range(-1.0, 1.0) * exp(-t * 35.0)
		var low: float = sin(TAU * 88.0 * t) * exp(-t * 22.0)
		samples[i] = (squish * 0.62 + low * 0.28) * env * 0.72
	return samples

func _synth_enemy_hit() -> PackedFloat32Array:
	var duration: float = 0.18
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - exp(-t * 120.0)) * exp(-t / 0.07)
		var thud: float = sin(TAU * 72.0 * t) * exp(-t * 16.0)
		var flesh: float = randf_range(-1.0, 1.0) * exp(-t * 32.0)
		var crunch: float = randf_range(-0.4, 0.4) * exp(-t * 80.0)
		samples[i] = (thud * 0.48 + flesh * 0.38 + crunch * 0.22) * env * 0.82
	return samples

func _synth_enemy_heavy_hit() -> PackedFloat32Array:
	var duration: float = 0.28
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - exp(-t * 80.0)) * exp(-t / 0.11)
		var impact: float = sin(TAU * 48.0 * t) * exp(-t * 9.0)
		var spray: float = randf_range(-1.0, 1.0) * exp(-t * 22.0)
		var crack: float = sin(TAU * 180.0 * t) * exp(-t * 45.0)
		samples[i] = (impact * 0.55 + spray * 0.32 + crack * 0.18) * env * 0.9
	return samples

func _synth_reload_mag_out() -> PackedFloat32Array:
	var duration: float = 0.18
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t / 0.055)
		var scrape: float = randf_range(-1.0, 1.0) * exp(-t * 28.0)
		var click: float = sin(TAU * 2200.0 * t) * exp(-t * 95.0)
		samples[i] = (scrape * 0.55 + click * 0.38) * env * 0.68
	return samples

func _synth_reload_mag_in() -> PackedFloat32Array:
	var duration: float = 0.12
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - exp(-t * 220.0)) * exp(-t / 0.04)
		var snap: float = sin(TAU * 1800.0 * t) * exp(-t * 88.0)
		var thunk: float = sin(TAU * 180.0 * t) * exp(-t * 28.0)
		samples[i] = (snap * 0.52 + thunk * 0.42) * env * 0.78
	return samples

func _synth_pickup() -> PackedFloat32Array:
	var duration: float = 0.18
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var tones: Array[float] = [660.0, 880.0]
	for tone_index in range(tones.size()):
		var start_t: float = float(tone_index) * 0.06
		var start_s: int = int(start_t * SAMPLE_RATE)
		for j in range(n - start_s):
			var t: float = float(j) / float(SAMPLE_RATE)
			samples[start_s + j] += sin(TAU * tones[tone_index] * t) * exp(-t * 38.0) * 0.48
	return samples

func _synth_ambient_pipe_groan() -> PackedFloat32Array:
	var duration: float = 1.8
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = smoothstep(0.0, 0.18, t) * (1.0 - smoothstep(duration - 0.38, duration, t))
		var pitch: float = lerp(38.0, 52.0, sin(t * 0.8) * 0.5 + 0.5)
		samples[i] = (
			sin(TAU * pitch * t) * 0.42
			+ sin(TAU * pitch * 2.1 * t) * 0.18
			+ randf_range(-0.06, 0.06)
		) * env * 0.55
	return samples

func _synth_ambient_distant_impact() -> PackedFloat32Array:
	var duration: float = 0.82
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - exp(-t * 45.0)) * exp(-t / 0.28)
		samples[i] = (
			sin(TAU * 42.0 * t) * exp(-t * 5.0) * 0.58
			+ randf_range(-1.0, 1.0) * exp(-t * 12.0) * 0.28
		) * env * 0.62
	return samples

func _synth_door_slam() -> PackedFloat32Array:
	var duration: float = 0.55
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - exp(-t * 320.0)) * exp(-t / 0.12)
		samples[i] = (
			sin(TAU * 55.0 * t) * exp(-t * 6.0) * 0.65
			+ randf_range(-1.0, 1.0) * exp(-t * 18.0) * 0.42
		) * env * 0.88
	return samples

func _synth_danger_alarm() -> PackedFloat32Array:
	var duration: float = 1.2
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var cycle: float = fmod(t, 0.3)
		var tone: float = 480.0 if cycle < 0.15 else 380.0
		var env: float = smoothstep(0.0, 0.015, cycle) * (1.0 - smoothstep(0.135, 0.15, cycle if cycle < 0.15 else cycle - 0.15))
		samples[i] = sin(TAU * tone * t) * env * 0.72
	return samples

func _synth_bone_crack() -> PackedFloat32Array:
	var duration: float = 0.14
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = (1.0 - exp(-t * 420.0)) * exp(-t / 0.038)
		samples[i] = (randf_range(-1.0, 1.0) * exp(-t * 55.0) * 0.62 + sin(TAU * 320.0 * t) * exp(-t * 88.0) * 0.28) * env
	return samples

func _synth_cauterize() -> PackedFloat32Array:
	var duration: float = 0.65
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = smoothstep(0.0, 0.02, t) * (1.0 - smoothstep(0.55, 0.65, t))
		var sizzle: float = randf_range(-1.0, 1.0) * (0.72 + sin(t * 18.0) * 0.18)
		samples[i] = sizzle * env * 0.58
	return samples

func _synth_injector() -> PackedFloat32Array:
	var duration: float = 0.22
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var hiss: float = randf_range(-1.0, 1.0) * exp(-t * 8.0) * 0.38
		var click_env: float = exp(-t * 120.0)
		var click: float = sin(TAU * 2800.0 * t) * click_env * 0.55
		samples[i] = hiss + click
	return samples

# Low, guttural grinding-throat grunt
func _synth_enemy_grunt() -> PackedFloat32Array:
	var duration: float = 0.38
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t * 5.5) * smoothstep(0.0, 0.04, t)
		var base: float = sin(TAU * 68.0 * t)
		var rough: float = sin(TAU * 112.0 * t) * 0.42 + sin(TAU * 185.0 * t) * 0.22
		var gravel: float = randf_range(-1.0, 1.0) * 0.18
		samples[i] = (base + rough + gravel) * env * 0.62
	return samples

# Sharp staccato detect-chirp: enemy has spotted the player
func _synth_enemy_detect() -> PackedFloat32Array:
	var duration: float = 0.28
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t * 22.0)
		var chirp: float = sin(TAU * lerp(420.0, 680.0, t / duration) * t) * 0.68
		var click: float = sin(TAU * 2400.0 * t) * exp(-t * 80.0) * 0.50
		var growl: float = sin(TAU * 95.0 * t) * exp(-t * 12.0) * 0.38
		samples[i] = (chirp + click + growl) * env
	return samples

# Quiet clicking / searching sound — enemy is hunting
func _synth_enemy_search() -> PackedFloat32Array:
	var duration: float = 0.18
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = exp(-t * 28.0) * smoothstep(0.0, 0.01, t)
		var click: float = sin(TAU * 1600.0 * t) * 0.58
		var sub: float = sin(TAU * 88.0 * t) * 0.28
		samples[i] = (click + sub) * env * 0.55
	return samples

# Sub-bass heartbeat thud — two layered pulses (lub-dub)
func _synth_heartbeat() -> PackedFloat32Array:
	var duration: float = 0.48
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		# Lub — primary beat at t=0
		var lub := sin(TAU * 62.0 * t) * exp(-t * 14.0) * 0.80
		lub += randf_range(-1.0, 1.0) * exp(-t * 22.0) * 0.22
		# Dub — secondary beat at t=0.12
		var t2 := t - 0.12
		var dub := 0.0
		if t2 > 0.0:
			dub = sin(TAU * 52.0 * t2) * exp(-t2 * 18.0) * 0.55
			dub += randf_range(-1.0, 1.0) * exp(-t2 * 28.0) * 0.14
		samples[i] = clamp((lub + dub) * 0.78, -1.0, 1.0)
	return samples

# Soft exhale breath — shaped white noise with slow rise and natural fade
func _synth_breath_exhale() -> PackedFloat32Array:
	var duration: float = 1.35
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var progress: float = t / duration
		# Breath envelope: rises fast, decays slowly, like an exhale
		var env: float = sin(progress * PI) * 0.62 + sin(progress * PI * 2.0) * 0.12
		env *= smoothstep(0.0, 0.06, t) * smoothstep(0.0, 0.08, duration - t)
		var noise: float = randf_range(-1.0, 1.0)
		# Low-pass character: blend in a low tone for that breathy quality
		var tone: float = sin(TAU * 280.0 * t) * 0.08 + sin(TAU * 680.0 * t) * 0.04
		samples[i] = (noise * 0.78 + tone) * env * 0.55
	return samples

# Heavy windup charge before attack
func _make_shepard_stream() -> AudioStreamWAV:
	# Auditory illusion of endlessly descending pitch (Shepard tone).
	# 8 oscillators at octave intervals scroll downward continuously over 4s then loop.
	var duration := 4.0
	var n := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var n_oct := 8
	var base_freq := 27.5
	var phases := PackedFloat32Array()
	phases.resize(n_oct)
	for i in range(n):
		var t_norm := float(i) / float(n)
		var val := 0.0
		for k in range(n_oct):
			var oct_pos := fmod(float(k) / float(n_oct) + t_norm, 1.0)
			var freq := base_freq * pow(2.0, oct_pos * float(n_oct))
			var amp := sin(PI * oct_pos)
			phases[k] += freq / float(SAMPLE_RATE)
			val += sin(TAU * phases[k]) * amp
		samples[i] = val / float(n_oct) * 0.38
	var stream := _make_stream(samples)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n - 1
	return stream

func _synth_tinnitus() -> PackedFloat32Array:
	# Pure high-frequency ring that fades over 3.5s — triggered by nearby explosions.
	var duration := 3.5
	var n := int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-t * 0.55) * sin(PI * t / duration)
		samples[i] = sin(TAU * 4200.0 * t) * env * 0.5
	return samples

func _synth_enemy_windup() -> PackedFloat32Array:
	var duration: float = 0.45
	var n: int = int(duration * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t: float = float(i) / float(SAMPLE_RATE)
		var progress: float = t / duration
		var env: float = progress * exp(-progress * 1.8)
		var freq: float = lerp(80.0, 220.0, progress)
		var tone: float = sin(TAU * freq * t) * 0.55
		var gravel: float = randf_range(-1.0, 1.0) * progress * 0.28
		var scrape: float = sin(TAU * 340.0 * t) * (1.0 - progress) * 0.18
		samples[i] = (tone + gravel + scrape) * env * 0.75
	return samples
