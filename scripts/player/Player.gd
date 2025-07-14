extends CharacterBody2D

# Player controller for CURSOR: Fragments of the Forgotten
# Handles touch-based movement and cursor abilities

signal health_changed(new_health: float)
signal death
signal state_saved(state_data: Dictionary)

# Player stats
var health: float = 100.0
var max_health: float = 100.0
var move_speed: float = 200.0
var base_move_speed: float = 200.0

# Movement system
var target_position: Vector2
var is_moving: bool = false
var movement_smoothing: float = 10.0

# Touch input
var touch_start_position: Vector2
var is_touching: bool = false
var touch_threshold: float = 10.0  # Minimum distance to start movement

# Digital effects
var digital_trail_points: Array[Vector2] = []
var max_trail_points: int = 20
var trail_update_timer: float = 0.0
var trail_update_interval: float = 0.05

# Player state for rewind system
var state_history: Array[Dictionary] = []
var max_state_history: int = 300  # 5 seconds at 60 FPS

# Status effects
var is_hacking: bool = false
var is_invulnerable: bool = false
var invulnerability_time: float = 0.0

# Node references
@onready var sprite: ColorRect = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var touch_area: Area2D = $TouchArea
@onready var digital_trail: Line2D = $DigitalTrail

func _ready() -> void:
	print("Player initialized")
	
	# Set initial position
	target_position = global_position
	
	# Connect touch signals
	touch_area.input_event.connect(_on_touch_area_input)
	
	# Setup digital effects
	setup_digital_effects()
	
	# Add to player group
	add_to_group("player")

func _process(delta: float) -> void:
	# Handle movement
	handle_movement(delta)
	
	# Update digital trail
	update_digital_trail(delta)
	
	# Update status effects
	update_status_effects(delta)
	
	# Save state for rewind system
	save_state_snapshot()

func _input(event: InputEvent) -> void:
	# Handle touch input for movement
	if event is InputEventScreenTouch:
		handle_touch_input(event)
	elif event is InputEventScreenDrag:
		handle_drag_input(event)
	
	# Handle mouse input for desktop testing
	elif event is InputEventMouseButton:
		handle_mouse_input(event)
	elif event is InputEventMouseMotion and is_touching:
		handle_mouse_drag(event)

func handle_touch_input(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_start_position = event.position
		is_touching = true
		print("Touch started at: ", event.position)
	else:
		is_touching = false
		# If touch released, stop movement
		target_position = global_position
		is_moving = false

func handle_drag_input(event: InputEventScreenDrag) -> void:
	if is_touching:
		# Convert screen position to world position
		var camera = get_viewport().get_camera_2d()
		var world_pos = camera.to_global(camera.to_local(event.position))
		
		# Check if drag distance is significant enough
		var drag_distance = event.position.distance_to(touch_start_position)
		if drag_distance > touch_threshold:
			set_target_position(world_pos)

func handle_mouse_input(event: InputEventMouseButton) -> void:
	# Desktop testing with mouse
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_touching = true
			touch_start_position = event.position
		else:
			is_touching = false
			target_position = global_position
			is_moving = false

func handle_mouse_drag(event: InputEventMouseMotion) -> void:
	# Desktop testing with mouse drag
	var world_pos = get_global_mouse_position()
	set_target_position(world_pos)

func set_target_position(world_pos: Vector2) -> void:
	# Check if the target position is walkable
	if is_position_walkable(world_pos):
		target_position = world_pos
		is_moving = true
		print("Moving to: ", world_pos)

func is_position_walkable(pos: Vector2) -> bool:
	# Check collision with walls using tilemap
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 4  # Environment layer (walls)
	query.exclude = [self]
	
	var result = space_state.intersect_point(query)
	return result.is_empty()

func handle_movement(delta: float) -> void:
	if not is_moving:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Calculate direction to target
	var direction = (target_position - global_position)
	var distance = direction.length()
	
	# Stop if we're close enough to target
	if distance < 5.0:
		is_moving = false
		velocity = Vector2.ZERO
		global_position = target_position
	else:
		# Move towards target
		direction = direction.normalized()
		velocity = direction * move_speed
	
	# Apply movement
	move_and_slide()
	
	# Check for collisions and stop if hit wall
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider().is_in_group("walls"):
				is_moving = false
				target_position = global_position

func update_digital_trail(delta: float) -> void:
	trail_update_timer += delta
	
	if trail_update_timer >= trail_update_interval:
		trail_update_timer = 0.0
		
		# Add current position to trail
		digital_trail_points.append(global_position)
		
		# Limit trail length
		if digital_trail_points.size() > max_trail_points:
			digital_trail_points.pop_front()
		
		# Update Line2D points
		if digital_trail:
			var local_points: PackedVector2Array = []
			for point in digital_trail_points:
				local_points.append(to_local(point))
			digital_trail.points = local_points

func setup_digital_effects() -> void:
	# Setup sprite glow effect
	if sprite:
		sprite.color = Color(0.3, 0.8, 1.0, 1.0)  # Cyan cursor color
		
		# Add a subtle glow animation
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(sprite, "modulate:a", 0.7, 1.0)
		tween.tween_property(sprite, "modulate:a", 1.0, 1.0)

func update_status_effects(delta: float) -> void:
	# Update invulnerability
	if is_invulnerable:
		invulnerability_time -= delta
		if invulnerability_time <= 0:
			is_invulnerable = false
			# Reset sprite transparency
			sprite.modulate.a = 1.0

func save_state_snapshot() -> void:
	# Save current state for time rewind
	var state = {
		"position": global_position,
		"health": health,
		"timestamp": Time.get_ticks_msec(),
		"is_moving": is_moving,
		"target_position": target_position
	}
	
	state_history.append(state)
	
	# Limit history size
	if state_history.size() > max_state_history:
		state_history.pop_front()
	
	state_saved.emit(state)

func restore_state(state: Dictionary) -> void:
	# Restore state from time rewind
	global_position = state.get("position", global_position)
	health = state.get("health", health)
	is_moving = state.get("is_moving", false)
	target_position = state.get("target_position", global_position)
	
	# Update UI
	health_changed.emit(health)
	
	print("State restored to: ", global_position)

func take_damage(amount: float) -> void:
	if is_invulnerable:
		return
	
	health -= amount
	health = max(0, health)
	
	# Update GameManager
	GameManager.player_health = health
	
	# Emit signal
	health_changed.emit(health)
	
	# Check for death
	if health <= 0:
		die()
	else:
		# Become temporarily invulnerable
		become_invulnerable(1.0)
		
		# Visual feedback
		flash_damage_effect()

func heal(amount: float) -> void:
	health += amount
	health = min(max_health, health)
	
	# Update GameManager
	GameManager.player_health = health
	
	# Emit signal
	health_changed.emit(health)
	
	print("Player healed for ", amount, ". Current health: ", health)

func become_invulnerable(duration: float) -> void:
	is_invulnerable = true
	invulnerability_time = duration
	
	# Visual effect - make sprite semi-transparent
	sprite.modulate.a = 0.5

func flash_damage_effect() -> void:
	# Flash red when taking damage
	var original_color = sprite.color
	sprite.color = Color.RED
	
	var tween = create_tween()
	tween.tween_property(sprite, "color", original_color, 0.2)

func die() -> void:
	print("Player died!")
	
	# Emit death signal
	death.emit()
	
	# Visual death effect
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(self, "scale", Vector2(0.1, 0.1), 1.0)
	
	# Disable collision
	collision_shape.disabled = true
	
	# Stop movement
	is_moving = false
	velocity = Vector2.ZERO

func respawn(spawn_position: Vector2) -> void:
	print("Player respawning at: ", spawn_position)
	
	# Reset stats
	health = max_health
	GameManager.player_health = health
	
	# Reset position
	global_position = spawn_position
	target_position = spawn_position
	is_moving = false
	
	# Reset visual effects
	sprite.modulate.a = 1.0
	scale = Vector2.ONE
	
	# Re-enable collision
	collision_shape.disabled = false
	
	# Reset status effects
	is_invulnerable = false
	invulnerability_time = 0.0
	
	# Clear trail
	digital_trail_points.clear()
	if digital_trail:
		digital_trail.points = PackedVector2Array()
	
	# Emit signal
	health_changed.emit(health)

func _on_touch_area_input(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# Handle direct touch on player for hack tool usage
	if event is InputEventScreenTouch and event.pressed:
		print("Player touched directly")
		# Could trigger context menu for hack tools here

func get_movement_direction() -> Vector2:
	if is_moving:
		return (target_position - global_position).normalized()
	return Vector2.ZERO

func is_player_moving() -> bool:
	return is_moving and velocity.length() > 10.0

func set_move_speed_modifier(modifier: float) -> void:
	move_speed = base_move_speed * modifier

func reset_move_speed() -> void:
	move_speed = base_move_speed

# Hack tool integration
func apply_time_rewind_effect() -> void:
	# Visual effect for time rewind
	var effect_tween = create_tween()
	effect_tween.tween_property(sprite, "modulate", Color.CYAN, 0.1)
	effect_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func apply_digital_breach_effect() -> void:
	# Visual effect for digital breach
	var effect_tween = create_tween()
	effect_tween.tween_property(sprite, "modulate", Color.GREEN, 0.2)
	effect_tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func get_state_for_rewind() -> Dictionary:
	return {
		"position": global_position,
		"health": health,
		"timestamp": Time.get_ticks_msec()
	}