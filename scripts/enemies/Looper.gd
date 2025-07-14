extends Enemy
class_name Looper

# Looper - Predictable but persistent enemy
# Behavior: Follows patterns, replicates movements, creates duplicates

var movement_pattern: Array[Vector2] = []
var pattern_index: int = 0
var pattern_recording: bool = true
var recording_timer: float = 0.0
var recording_interval: float = 0.5
var max_pattern_length: int = 10
var duplicate_spawn_timer: float = 0.0
var duplicate_spawn_interval: float = 15.0
var max_duplicates: int = 2
var current_duplicates: int = 0

func _ready() -> void:
	enemy_type = EnemyType.LOOPER
	
	# Moderate stats with focus on persistence
	max_health = 50.0
	health = max_health
	move_speed = 70.0
	base_move_speed = move_speed
	attack_damage = 15.0
	detection_range = 100.0
	attack_range = 30.0
	
	super._ready()
	
	# Start recording movement pattern
	start_pattern_recording()

func _process(delta: float) -> void:
	super._process(delta)
	
	# Update pattern recording
	if pattern_recording:
		recording_timer += delta
		if recording_timer >= recording_interval:
			record_movement_point()
			recording_timer = 0.0
	
	# Duplicate spawning
	duplicate_spawn_timer += delta
	if duplicate_spawn_timer >= duplicate_spawn_interval and current_duplicates < max_duplicates:
		spawn_duplicate()
		duplicate_spawn_timer = 0.0

func start_pattern_recording() -> void:
	pattern_recording = true
	movement_pattern.clear()
	pattern_index = 0
	print("Looper starting pattern recording")

func record_movement_point() -> void:
	if movement_pattern.size() < max_pattern_length:
		movement_pattern.append(global_position)
	else:
		# Pattern complete, start looping
		pattern_recording = false
		pattern_index = 0
		print("Looper pattern recording complete, starting loop")

func apply_chase_modifier(direction: Vector2, delta: float) -> void:
	# Looper becomes more predictable but faster when chasing
	if not pattern_recording and movement_pattern.size() > 0:
		# Follow the recorded pattern while chasing
		follow_movement_pattern(delta)
	else:
		# Standard chase behavior while recording
		move_speed = base_move_speed * 1.2

func follow_movement_pattern(delta: float) -> void:
	if movement_pattern.is_empty():
		return
	
	var target_point = movement_pattern[pattern_index]
	var direction = (target_point - global_position).normalized()
	
	# Move towards pattern point
	velocity = direction * move_speed * 1.5
	
	# Check if reached point
	if global_position.distance_to(target_point) < 15.0:
		pattern_index = (pattern_index + 1) % movement_pattern.size()

func apply_attack_effects() -> void:
	# Creates temporal echoes during attack
	create_temporal_echo()
	
	# Chance to reset player position to previous location
	if randf() < 0.2:
		apply_position_reset()

func create_temporal_echo() -> void:
	# Create a fading copy of the looper
	var echo = Sprite2D.new()
	echo.texture = sprite_node.texture
	echo.global_position = global_position
	echo.modulate = Color.YELLOW
	echo.modulate.a = 0.6
	
	get_parent().add_child(echo)
	
	# Fade out the echo
	var tween = create_tween()
	tween.tween_property(echo, "modulate:a", 0.0, 1.0)
	tween.tween_callback(echo.queue_free)

func apply_position_reset() -> void:
	# Try to reset player to a previous position
	if target_player and target_player.has_method("get_state_for_rewind"):
		print("Looper attempting position reset on player")
		
		# Visual effect
		var reset_effect = ColorRect.new()
		reset_effect.size = Vector2(60, 60)
		reset_effect.position = Vector2(-30, -30)
		reset_effect.color = Color.YELLOW
		reset_effect.color.a = 0.5
		target_player.add_child(reset_effect)
		
		var effect_tween = create_tween()
		effect_tween.tween_property(reset_effect, "scale", Vector2(2, 2), 0.3)
		effect_tween.parallel().tween_property(reset_effect, "modulate:a", 0.0, 0.3)
		effect_tween.tween_callback(reset_effect.queue_free)

func spawn_duplicate() -> void:
	if current_duplicates >= max_duplicates:
		return
	
	print("Looper spawning duplicate")
	
	# Create duplicate looper
	var duplicate = preload("res://scripts/enemies/Looper.gd").new()
	duplicate.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	duplicate.emotion_type = emotion_type
	duplicate.max_health = max_health * 0.7  # Weaker duplicate
	duplicate.health = duplicate.max_health
	duplicate.movement_pattern = movement_pattern.duplicate()  # Copy pattern
	duplicate.pattern_recording = false  # Don't record new pattern
	duplicate.is_duplicate = true
	
	get_parent().add_child(duplicate)
	current_duplicates += 1
	
	# Connect to duplicate death to track count
	duplicate.died.connect(_on_duplicate_died)
	
	# Visual spawn effect
	create_spawn_effect(duplicate.global_position)

var is_duplicate: bool = false

func create_spawn_effect(pos: Vector2) -> void:
	# Create swirling spawn effect
	var effect_node = Node2D.new()
	get_parent().add_child(effect_node)
	effect_node.global_position = pos
	
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.position = Vector2(-3, -3)
		particle.color = Color.YELLOW
		effect_node.add_child(particle)
		
		var angle = (i / 8.0) * TAU
		var radius = 30.0
		var start_pos = Vector2(cos(angle), sin(angle)) * radius
		particle.position = start_pos
		
		var tween = create_tween()
		tween.tween_property(particle, "position", Vector2.ZERO, 0.8)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.8)
	
	# Clean up effect
	var cleanup_tween = create_tween()
	cleanup_tween.tween_delay(1.0)
	cleanup_tween.tween_callback(effect_node.queue_free)

func _on_duplicate_died() -> void:
	current_duplicates -= 1
	print("Looper duplicate died, remaining: ", current_duplicates)

func execute_injected_behavior(delta: float) -> void:
	match injection_type:
		"friendly":
			# Shares movement pattern with player (helpful escort)
			share_pattern_with_player()
		"aggressive":
			# Spawns more duplicates and attacks relentlessly
			super.execute_injected_behavior(delta)
			duplicate_spawn_interval = 8.0  # Faster spawning
			if current_duplicates < 4:  # More duplicates allowed
				max_duplicates = 4
		"static":
			# Becomes a stationary pattern broadcaster
			velocity = Vector2.ZERO
			if state_timer > 2.0:
				broadcast_pattern_disruption()
				state_timer = 0.0
		"confused":
			# Pattern becomes random and chaotic
			randomize_movement_pattern()
			super.execute_injected_behavior(delta)

func share_pattern_with_player() -> void:
	# Creates visual guides for player movement
	if target_player and movement_pattern.size() > 0:
		create_pattern_guides()

func create_pattern_guides() -> void:
	# Show pattern points as helpful guides
	for i in range(movement_pattern.size()):
		var guide = ColorRect.new()
		guide.size = Vector2(8, 8)
		guide.position = Vector2(-4, -4)
		guide.color = Color.GREEN
		guide.color.a = 0.7
		guide.global_position = movement_pattern[i]
		
		get_parent().add_child(guide)
		
		# Fade out guide
		var tween = create_tween()
		tween.tween_delay(i * 0.2)
		tween.tween_property(guide, "modulate:a", 0.0, 1.0)
		tween.tween_callback(guide.queue_free)

func broadcast_pattern_disruption() -> void:
	# Disrupts other enemies' movement patterns
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy == self or enemy.global_position.distance_to(global_position) > 100:
			continue
		
		# Apply movement disruption
		if enemy.has_method("apply_stun"):
			enemy.apply_stun(1.0)
		
		# Visual disruption effect
		var disruption = ColorRect.new()
		disruption.size = Vector2(20, 20)
		disruption.position = Vector2(-10, -10)
		disruption.color = Color.YELLOW
		enemy.add_child(disruption)
		
		var tween = create_tween()
		tween.tween_property(disruption, "scale", Vector2(2, 2), 0.5)
		tween.parallel().tween_property(disruption, "modulate:a", 0.0, 0.5)
		tween.tween_callback(disruption.queue_free)

func randomize_movement_pattern() -> void:
	# Scramble the movement pattern
	for i in range(movement_pattern.size()):
		var random_offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
		movement_pattern[i] += random_offset
	
	print("Looper pattern randomized")

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	
	# When damaged, creates a defensive pattern
	if health < max_health * 0.5:
		create_defensive_pattern()

func create_defensive_pattern() -> void:
	# Generate circular defensive movement pattern
	movement_pattern.clear()
	var center = global_position
	
	for i in range(8):
		var angle = (i / 8.0) * TAU
		var radius = 60.0
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		movement_pattern.append(point)
	
	pattern_index = 0
	pattern_recording = false
	print("Looper created defensive pattern")

func die() -> void:
	# Cleanup duplicates when main looper dies
	if not is_duplicate:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if enemy.has_method("get") and enemy.get("is_duplicate") == true:
				if enemy.emotion_type == emotion_type:  # Same type duplicates
					enemy.queue_free()
	
	# Create pattern explosion effect
	create_pattern_explosion()
	
	super.die()

func create_pattern_explosion() -> void:
	# Visual effect showing the pattern breaking apart
	for point in movement_pattern:
		var fragment = ColorRect.new()
		fragment.size = Vector2(4, 4)
		fragment.color = Color.YELLOW
		fragment.global_position = point
		
		get_parent().add_child(fragment)
		
		var direction = (point - global_position).normalized()
		var target = point + direction * 100
		
		var tween = create_tween()
		tween.tween_property(fragment, "global_position", target, 1.0)
		tween.parallel().tween_property(fragment, "modulate:a", 0.0, 1.0)
		tween.tween_callback(fragment.queue_free)