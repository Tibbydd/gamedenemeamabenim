extends Enemy
class_name Corruptor

# Corruptor - Aggressive corruption-spreading enemy
# Behavior: Direct assault, spreads corruption, becomes stronger when player is hurt

var corruption_radius: float = 60.0
var corruption_damage: float = 5.0
var corruption_timer: float = 0.0
var corruption_interval: float = 2.0
var rage_multiplier: float = 1.0
var player_last_health: float = 100.0

func _ready() -> void:
	enemy_type = EnemyType.CORRUPTOR
	
	# Enhanced stats for aggressive behavior
	max_health = 75.0
	health = max_health
	move_speed = 100.0
	base_move_speed = move_speed
	attack_damage = 25.0
	detection_range = 140.0
	attack_range = 35.0
	
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	
	# Corruption spreading
	corruption_timer += delta
	if corruption_timer >= corruption_interval:
		spread_corruption()
		corruption_timer = 0.0
	
	# Check player health for rage mode
	if target_player and target_player.has_method("get"):
		var current_health = target_player.health
		if current_health < player_last_health:
			enter_rage_mode()
		player_last_health = current_health

func apply_chase_modifier(direction: Vector2, delta: float) -> void:
	# Corruptor gets faster as it chases
	move_speed = base_move_speed * (1.0 + rage_multiplier)
	
	# Zigzag pattern to make it harder to avoid
	var zigzag = sin(state_timer * 3.0) * 30.0
	var perpendicular = Vector2(-direction.y, direction.x)
	velocity += perpendicular * zigzag

func apply_attack_effects() -> void:
	# Corruption blast
	create_corruption_blast()
	
	# Chance to cause fear effect
	if randf() < 0.3:
		apply_fear_effect()

func create_corruption_blast() -> void:
	# Find all entities in corruption radius
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# Create circular area
	var shape = CircleShape2D.new()
	shape.radius = corruption_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1  # Player layer
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(corruption_damage)
			
			# Visual corruption effect on player
			if body.has_method("apply_corruption_effect"):
				body.apply_corruption_effect(2.0)
	
	# Visual effect
	create_corruption_visual_effect()

func create_corruption_visual_effect() -> void:
	# Create expanding corruption ring
	var effect_node = Node2D.new()
	get_parent().add_child(effect_node)
	effect_node.global_position = global_position
	
	# Create multiple rings for effect
	for i in range(3):
		var ring = ColorRect.new()
		ring.size = Vector2(10, 10)
		ring.position = Vector2(-5, -5)
		ring.color = Color.RED
		ring.color.a = 0.6
		effect_node.add_child(ring)
		
		var delay = i * 0.1
		var tween = create_tween()
		tween.tween_delay(delay)
		tween.parallel().tween_property(ring, "size", Vector2(corruption_radius * 2, corruption_radius * 2), 0.5)
		tween.parallel().tween_property(ring, "position", Vector2(-corruption_radius, -corruption_radius), 0.5)
		tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.5)
	
	# Clean up effect
	var cleanup_tween = create_tween()
	cleanup_tween.tween_delay(1.0)
	cleanup_tween.tween_callback(effect_node.queue_free)

func apply_fear_effect() -> void:
	# Slow down player temporarily
	if target_player and target_player.has_method("set_move_speed_modifier"):
		target_player.set_move_speed_modifier(0.5)
		
		# Remove effect after 3 seconds
		var fear_timer = create_tween()
		fear_timer.tween_delay(3.0)
		fear_timer.tween_callback(func(): 
			if target_player and target_player.has_method("reset_move_speed"):
				target_player.reset_move_speed()
		)

func spread_corruption() -> void:
	if current_state != AIState.CHASE and current_state != AIState.ATTACK:
		return
	
	# Find nearby tiles to corrupt
	var dungeon_renderer = get_tree().get_first_node_in_group("dungeon_renderer")
	if not dungeon_renderer:
		return
	
	# Create corruption particles
	create_corruption_particles()

func create_corruption_particles() -> void:
	# Spawn corruption particles around the corruptor
	var particles_container = get_tree().get_first_node_in_group("effects")
	if not particles_container:
		return
	
	for i in range(5):
		var particle = create_corruption_particle()
		particles_container.add_child(particle)
		
		var angle = randf() * TAU
		var distance = randf_range(20, 50)
		var target_pos = global_position + Vector2(cos(angle), sin(angle)) * distance
		
		particle.global_position = global_position
		
		var tween = create_tween()
		tween.tween_property(particle, "global_position", target_pos, 1.0)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.0)
		tween.tween_callback(particle.queue_free)

func create_corruption_particle() -> Node2D:
	var particle = ColorRect.new()
	particle.size = Vector2(4, 4)
	particle.position = Vector2(-2, -2)
	particle.color = Color.RED
	return particle

func enter_rage_mode() -> void:
	rage_multiplier = min(rage_multiplier + 0.2, 2.0)
	
	# Visual rage effect
	var rage_tween = create_tween()
	rage_tween.tween_property(sprite_node, "modulate", Color.RED, 0.2)
	rage_tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.2)
	
	print("Corruptor entering rage mode! Multiplier: ", rage_multiplier)

func execute_injected_behavior(delta: float) -> void:
	match injection_type:
		"friendly":
			# Becomes a protector, attacks other enemies
			find_and_attack_enemies()
		"aggressive":
			# Extreme aggression
			super.execute_injected_behavior(delta)
			move_speed = base_move_speed * 2.0
			attack_damage = 35.0
		"static":
			# Becomes a corruption turret
			velocity = Vector2.ZERO
			if state_timer > 1.0:
				spread_corruption()
				state_timer = 0.0
		"confused":
			# Random corruption blasts
			super.execute_injected_behavior(delta)
			if randf() < 0.1:
				create_corruption_blast()

func find_and_attack_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy: Enemy = null
	var closest_distance: float = INF
	
	for enemy in enemies:
		if enemy == self:
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance and distance < detection_range:
			closest_distance = distance
			closest_enemy = enemy
	
	if closest_enemy:
		# Attack the enemy
		var direction = (closest_enemy.global_position - global_position).normalized()
		velocity = direction * move_speed
		
		if closest_distance < attack_range:
			closest_enemy.take_damage(attack_damage)
			create_attack_effect()

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	
	# Corruptor gets more aggressive when hurt
	if health < max_health * 0.5:
		enter_rage_mode()
		
		# Spread corruption when severely damaged
		if health < max_health * 0.25:
			create_corruption_blast()

func die() -> void:
	# Death corruption explosion
	create_corruption_blast()
	create_corruption_blast()  # Double explosion
	
	super.die()