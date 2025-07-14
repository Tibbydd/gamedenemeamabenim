extends CharacterBody2D
class_name Enemy

# Base enemy class for CURSOR: Fragments of the Forgotten
signal died
signal player_detected
signal lost_player
signal state_changed(new_state: String)

# Enemy types
enum EnemyType {
	CORRUPTOR,
	LOOPER,
	PHANTOM_MEMORY
}

# AI States
enum AIState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	STUNNED,
	CORRUPTED,
	FLEEING
}

# Base stats
var enemy_type: EnemyType = EnemyType.CORRUPTOR
var emotion_type: String = "neutral"
var health: float = 50.0
var max_health: float = 50.0
var move_speed: float = 80.0
var base_move_speed: float = 80.0
var attack_damage: float = 15.0
var detection_range: float = 120.0
var attack_range: float = 40.0

# AI variables
var current_state: AIState = AIState.IDLE
var target_player: Node2D = null
var last_known_player_position: Vector2 = Vector2.ZERO
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var state_timer: float = 0.0
var aggro_timer: float = 0.0
var max_aggro_time: float = 8.0

# Pathfinding
var path: Array[Vector2] = []
var path_index: int = 0
var stuck_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO

# Status effects
var is_stunned: bool = false
var stun_duration: float = 0.0
var is_code_injected: bool = false
var injection_type: String = ""
var injection_duration: float = 0.0
var is_filtered: bool = false
var filter_duration: float = 0.0

# Visual effects
var sprite_node: Sprite2D
var health_bar: ProgressBar
var detection_circle: Node2D

# Combat
var attack_cooldown: float = 0.0
var max_attack_cooldown: float = 1.5

func _ready() -> void:
	# Setup sprite
	setup_visual_components()
	
	# Initialize AI
	initialize_ai()
	
	# Add to enemies group
	add_to_group("enemies")
	
	# Find player
	find_player()
	
	# Generate patrol points
	generate_patrol_points()

func _process(delta: float) -> void:
	update_timers(delta)
	update_ai_state(delta)
	update_visual_effects(delta)

func _physics_process(delta: float) -> void:
	if is_stunned or is_filtered:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	execute_ai_behavior(delta)
	apply_movement(delta)

func setup_visual_components() -> void:
	# Create sprite
	sprite_node = Sprite2D.new()
	add_child(sprite_node)
	
	# Generate enemy sprite based on type and emotion
	var sprite_texture = SpriteGenerator.create_enemy_sprite(
		get_enemy_type_string(), 
		emotion_type
	)
	sprite_node.texture = sprite_texture
	
	# Create health bar
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(30, 4)
	health_bar.position = Vector2(-15, -20)
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = false
	add_child(health_bar)
	
	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12
	collision.shape = shape
	add_child(collision)

func initialize_ai() -> void:
	current_state = AIState.IDLE
	state_timer = 0.0
	
	# Customize stats based on enemy type
	match enemy_type:
		EnemyType.CORRUPTOR:
			max_health = 60.0
			move_speed = 90.0
			attack_damage = 20.0
			detection_range = 100.0
		EnemyType.LOOPER:
			max_health = 40.0
			move_speed = 60.0
			attack_damage = 12.0
			detection_range = 80.0
		EnemyType.PHANTOM_MEMORY:
			max_health = 80.0
			move_speed = 120.0
			attack_damage = 8.0
			detection_range = 150.0
	
	health = max_health
	base_move_speed = move_speed

func find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func generate_patrol_points() -> void:
	# Generate random patrol points around spawn position
	var spawn_pos = global_position
	for i in range(3):
		var angle = randf() * TAU
		var distance = randf_range(60, 120)
		var point = spawn_pos + Vector2(cos(angle), sin(angle)) * distance
		patrol_points.append(point)

func update_timers(delta: float) -> void:
	state_timer += delta
	
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	if aggro_timer > 0:
		aggro_timer -= delta
		if aggro_timer <= 0:
			lose_player()
	
	# Status effects
	if is_stunned:
		stun_duration -= delta
		if stun_duration <= 0:
			is_stunned = false
	
	if is_code_injected:
		injection_duration -= delta
		if injection_duration <= 0:
			is_code_injected = false
			injection_type = ""
	
	if is_filtered:
		filter_duration -= delta
		if filter_duration <= 0:
			is_filtered = false

func update_ai_state(delta: float) -> void:
	if not target_player or is_stunned or is_filtered:
		return
	
	var distance_to_player = global_position.distance_to(target_player.global_position)
	
	# State transitions
	match current_state:
		AIState.IDLE:
			if distance_to_player < detection_range:
				change_state(AIState.CHASE)
			elif state_timer > 2.0:
				change_state(AIState.PATROL)
		
		AIState.PATROL:
			if distance_to_player < detection_range:
				change_state(AIState.CHASE)
			elif has_reached_patrol_point():
				next_patrol_point()
		
		AIState.CHASE:
			if distance_to_player > detection_range * 1.5:
				change_state(AIState.PATROL)
			elif distance_to_player < attack_range:
				change_state(AIState.ATTACK)
		
		AIState.ATTACK:
			if distance_to_player > attack_range * 1.2:
				change_state(AIState.CHASE)
			elif attack_cooldown <= 0:
				perform_attack()

func execute_ai_behavior(delta: float) -> void:
	if is_code_injected:
		execute_injected_behavior(delta)
		return
	
	match current_state:
		AIState.IDLE:
			velocity = Vector2.ZERO
		
		AIState.PATROL:
			move_towards_patrol_point(delta)
		
		AIState.CHASE:
			chase_player(delta)
		
		AIState.ATTACK:
			face_player()
			velocity = velocity.lerp(Vector2.ZERO, delta * 5)

func execute_injected_behavior(delta: float) -> void:
	match injection_type:
		"friendly":
			# Move away from player gently
			if target_player:
				var direction = (global_position - target_player.global_position).normalized()
				velocity = direction * move_speed * 0.3
		
		"aggressive":
			# Always chase aggressively
			if target_player:
				chase_player(delta)
				move_speed = base_move_speed * 1.5
		
		"static":
			# Don't move
			velocity = Vector2.ZERO
		
		"confused":
			# Move randomly
			if state_timer > 1.0:
				var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				velocity = random_direction * move_speed * 0.5
				state_timer = 0.0

func move_towards_patrol_point(delta: float) -> void:
	if patrol_points.is_empty():
		return
	
	var target_point = patrol_points[current_patrol_index]
	var direction = (target_point - global_position).normalized()
	velocity = direction * move_speed

func chase_player(delta: float) -> void:
	if not target_player:
		return
	
	last_known_player_position = target_player.global_position
	aggro_timer = max_aggro_time
	
	var direction = (target_player.global_position - global_position).normalized()
	velocity = direction * move_speed
	
	# Apply enemy-specific chase behavior
	apply_chase_modifier(direction, delta)

func apply_chase_modifier(direction: Vector2, delta: float) -> void:
	# Override in child classes for specific behaviors
	pass

func face_player() -> void:
	if target_player:
		var direction = (target_player.global_position - global_position).normalized()
		# Rotate sprite to face player (optional)

func perform_attack() -> void:
	if not target_player or attack_cooldown > 0:
		return
	
	var distance = global_position.distance_to(target_player.global_position)
	if distance <= attack_range:
		# Deal damage to player
		if target_player.has_method("take_damage"):
			target_player.take_damage(attack_damage)
		
		# Apply attack effects
		apply_attack_effects()
		
		attack_cooldown = max_attack_cooldown
		
		# Visual attack effect
		create_attack_effect()

func apply_attack_effects() -> void:
	# Override in child classes for specific attack effects
	pass

func create_attack_effect() -> void:
	# Create visual attack effect
	var tween = create_tween()
	tween.tween_property(sprite_node, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.1)

func has_reached_patrol_point() -> bool:
	if patrol_points.is_empty():
		return true
	
	var target_point = patrol_points[current_patrol_index]
	return global_position.distance_to(target_point) < 20.0

func next_patrol_point() -> void:
	current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	state_timer = 0.0

func change_state(new_state: AIState) -> void:
	if current_state == new_state:
		return
	
	# Exit current state
	exit_state(current_state)
	
	# Enter new state
	current_state = new_state
	state_timer = 0.0
	enter_state(new_state)
	
	state_changed.emit(get_state_string(new_state))

func enter_state(state: AIState) -> void:
	match state:
		AIState.CHASE:
			player_detected.emit()
			health_bar.visible = true
		AIState.PATROL:
			health_bar.visible = false

func exit_state(state: AIState) -> void:
	match state:
		AIState.CHASE:
			lost_player.emit()

func lose_player() -> void:
	if current_state == AIState.CHASE:
		change_state(AIState.PATROL)

func apply_movement(delta: float) -> void:
	move_and_slide()
	
	# Check if stuck
	if global_position.distance_to(last_position) < 5.0:
		stuck_timer += delta
		if stuck_timer > 2.0:
			# Try to unstuck
			velocity += Vector2(randf_range(-50, 50), randf_range(-50, 50))
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	
	last_position = global_position

func update_visual_effects(delta: float) -> void:
	# Update health bar
	if health_bar:
		health_bar.value = health
	
	# Status effect visuals
	if is_stunned:
		sprite_node.modulate = Color.YELLOW.lerp(Color.WHITE, sin(state_timer * 10) * 0.5 + 0.5)
	elif is_code_injected:
		sprite_node.modulate = Color.GREEN.lerp(Color.WHITE, sin(state_timer * 5) * 0.5 + 0.5)
	elif is_filtered:
		sprite_node.modulate = Color.BLUE.lerp(Color.WHITE, sin(state_timer * 3) * 0.5 + 0.5)
	else:
		sprite_node.modulate = Color.WHITE

func take_damage(amount: float) -> void:
	health -= amount
	health = max(0, health)
	
	# Flash effect
	var tween = create_tween()
	tween.tween_property(sprite_node, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		die()

func die() -> void:
	died.emit()
	
	# Death effect
	var tween = create_tween()
	tween.parallel().tween_property(sprite_node, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.5)
	
	await tween.finished
	queue_free()

# Hack tool effects
func apply_code_injection(injection_type: String) -> void:
	is_code_injected = true
	self.injection_type = injection_type
	injection_duration = 5.0
	
	print("Code injection applied: ", injection_type)

func apply_filter(duration: float) -> void:
	is_filtered = true
	filter_duration = duration
	
	# Make enemy non-threatening
	velocity = Vector2.ZERO
	current_state = AIState.IDLE
	
	print("Enemy filtered for ", duration, " seconds")

func apply_stun(duration: float) -> void:
	is_stunned = true
	stun_duration = duration
	velocity = Vector2.ZERO
	
	print("Enemy stunned for ", duration, " seconds")

# Utility functions
func get_enemy_type_string() -> String:
	match enemy_type:
		EnemyType.CORRUPTOR: return "Corruptor"
		EnemyType.LOOPER: return "Looper"
		EnemyType.PHANTOM_MEMORY: return "PhantomMemory"
		_: return "Unknown"

func get_state_string(state: AIState) -> String:
	match state:
		AIState.IDLE: return "Idle"
		AIState.PATROL: return "Patrol"
		AIState.CHASE: return "Chase"
		AIState.ATTACK: return "Attack"
		AIState.STUNNED: return "Stunned"
		AIState.CORRUPTED: return "Corrupted"
		AIState.FLEEING: return "Fleeing"
		_: return "Unknown"

func get_emotion_type() -> String:
	return emotion_type

func set_emotion_type(emotion: String) -> void:
	emotion_type = emotion
	
	# Regenerate sprite with new emotion
	if sprite_node:
		var new_texture = SpriteGenerator.create_enemy_sprite(
			get_enemy_type_string(), 
			emotion_type
		)
		sprite_node.texture = new_texture