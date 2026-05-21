extends Node

# Procedurally synthesized SFX using AudioStreamWAV PCM.
# Generates buffers once at startup; AudioRouter plays them by ID.

const SAMPLE_RATE := 22050
var sounds: Dictionary = {}

func _ready() -> void:
	sounds["gunshot_light"] = _make_stream(_synth_gunshot(0.18, 0.22, 520.0))
	sounds["gunshot_heavy"] = _make_stream(_synth_gunshot(0.28, 0.32, 280.0))
	sounds["gunshot_thermal"] = _make_stream(_synth_gunshot_thermal())
	sounds["footstep_hard"] = _make_stream(_synth_footstep(0.08, 1100.0))
	sounds["footstep_soft"] = _make_stream(_synth_footstep(0.06, 640.0))
	sounds["enemy_alert"] = _make_stream(_synth_alert())
	sounds["enemy_death"] = _make_stream(_synth_death())
	sounds["howler_death"] = _make_stream(_synth_howler_death())
	sounds["reload_click"] = _make_stream(_synth_click(0.055, 1800.0))
	sounds["interact"] = _make_stream(_synth_click(0.04, 2200.0))
	sounds["ambient_hum"] = _make_stream(_synth_ambient_hum())
	sounds["ambient_drip"] = _make_stream(_synth_ambient_drip())
	sounds["ambient_clank"] = _make_stream(_synth_ambient_clank())
	sounds["ambient_electric"] = _make_stream(_synth_ambient_electric())
	sounds["objective_complete"] = _make_stream(_synth_objective_complete())
	sounds["extraction_beacon"] = _make_stream(_synth_extraction_beacon())
	sounds["door_open"] = _make_stream(_synth_door_open())

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
