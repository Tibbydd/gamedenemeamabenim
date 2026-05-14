extends CharacterBody3D
class_name PlayerControllerFPS

signal died(reason: String)

var walk_speed: float = 5.2
var sprint_speed: float = 8.1
var crouch_speed: float = 2.9
var acceleration: float = 13.0
var air_control: float = 2.0
var gravity: float = 18.0
var stamina: float = 100.0
var max_stamina: float = 100.0
var stamina_recovery: float = 18.0
var sprint_stamina_cost: float = 24.0

var yaw: float = 0.0
var pitch: float = 0.0
var is_crouching: bool = false
var run_finished: bool = false
var noise_timer: float = 0.0

var head: Node3D
var camera: Camera3D
var collision_shape: CollisionShape3D
var capsule_shape: CapsuleShape3D
var weapon: WeaponController
var build_system: BuildPlacementSystem
var health: PlayerHealthBodyParts
var mental: MentalStateManager
var weapon_pivot: Node3D
var muzzle_marker: Node3D
var weapon_default_position: Vector3 = Vector3(0.34, -0.34, -0.62)
var weapon_obstructed_position: Vector3 = Vector3(0.12, -0.12, -0.28)
var barrel_obstruction: float = 0.0
var barrel_push_side: float = 0.0
var shove_cooldown: float = 0.0
var shove_cooldown_time: float = 0.85
var intro_lock_timer: float = 0.0
var intro_duration: float = 1.05
var intro_start_head_y: float = 1.08
var intro_start_roll: float = 0.0
var intro_message_active: bool = false
var allow_restart: bool = false

var hud_layer: CanvasLayer
var ammo_label: Label
var body_label: Label
var status_label: Label
var timer_label: Label
var treatment_label: Label
var crosshair_label: Label
var end_label: Label
var corruption_overlay: ColorRect

func _ready() -> void:
	add_to_group("player")
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity", gravity)
	_build_collision()
	_build_camera()
	_build_systems()
	_build_hud()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _build_collision() -> void:
	collision_layer = 1
	collision_mask = 1 | 2
	capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 0.34
	capsule_shape.height = 1.55
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "BodyCollision"
	collision_shape.shape = capsule_shape
	collision_shape.position.y = 0.86
	add_child(collision_shape)

func _build_camera() -> void:
	head = Node3D.new()
	head.name = "Head"
	head.position.y = 1.58
	add_child(head)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera.fov = 75.0
	head.add_child(camera)
	_build_weapon_visual()

func _build_weapon_visual() -> void:
	weapon_pivot = Node3D.new()
	weapon_pivot.name = "WeaponPivot"
	weapon_pivot.position = weapon_default_position
	camera.add_child(weapon_pivot)
	var grip := MeshInstance3D.new()
	grip.name = "PistolGrip"
	var grip_mesh := BoxMesh.new()
	grip_mesh.size = Vector3(0.18, 0.34, 0.16)
	grip.mesh = grip_mesh
	grip.position = Vector3(0.0, -0.12, 0.1)
	grip.rotation_degrees.x = -12.0
	grip.material_override = _make_weapon_material(Color(0.08, 0.09, 0.1), 0.0)
	weapon_pivot.add_child(grip)
	var receiver := MeshInstance3D.new()
	receiver.name = "PistolReceiver"
	var receiver_mesh := BoxMesh.new()
	receiver_mesh.size = Vector3(0.22, 0.16, 0.46)
	receiver.mesh = receiver_mesh
	receiver.position = Vector3(0.0, 0.02, -0.2)
	receiver.material_override = _make_weapon_material(Color(0.15, 0.18, 0.19), 0.0)
	weapon_pivot.add_child(receiver)
	var barrel := MeshInstance3D.new()
	barrel.name = "PistolBarrel"
	var barrel_mesh := BoxMesh.new()
	barrel_mesh.size = Vector3(0.09, 0.08, 0.48)
	barrel.mesh = barrel_mesh
	barrel.position = Vector3(0.0, 0.045, -0.62)
	barrel.material_override = _make_weapon_material(Color(0.35, 0.44, 0.43), 0.35)
	weapon_pivot.add_child(barrel)
	muzzle_marker = Node3D.new()
	muzzle_marker.name = "Muzzle"
	muzzle_marker.position = Vector3(0.0, 0.045, -0.88)
	weapon_pivot.add_child(muzzle_marker)

func _make_weapon_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material

func _build_systems() -> void:
	health = PlayerHealthBodyParts.new()
	health.name = "PlayerHealthBodyParts"
	add_child(health)
	health.died.connect(_on_health_died)
	mental = MentalStateManager.new()
	mental.name = "MentalStateManager"
	add_child(mental)
	weapon = WeaponController.new()
	weapon.name = "WeaponController"
	add_child(weapon)
	weapon.setup(self, camera, muzzle_marker, health, mental)
	build_system = BuildPlacementSystem.new()
	build_system.name = "BuildPlacementSystem"
	add_child(build_system)
	build_system.setup(self, camera)

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "PrototypeHUD"
	add_child(hud_layer)
	corruption_overlay = ColorRect.new()
	corruption_overlay.color = Color(0.1, 0.8, 0.9, 0.0)
	corruption_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corruption_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(corruption_overlay)
	crosshair_label = Label.new()
	crosshair_label.text = "+"
	crosshair_label.add_theme_font_size_override("font_size", 28)
	crosshair_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.95))
	crosshair_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hud_layer.add_child(crosshair_label)
	var left_panel := VBoxContainer.new()
	left_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	left_panel.offset_left = 24.0
	left_panel.offset_top = 18.0
	left_panel.offset_right = 680.0
	left_panel.offset_bottom = 420.0
	hud_layer.add_child(left_panel)
	status_label = _make_hud_label("COGNITIVE LINK: STABLE  0%")
	timer_label = _make_hud_label("SURVIVE: 03:00")
	ammo_label = _make_hud_label("M-7: 12 / 48")
	body_label = _make_hud_label("")
	treatment_label = _make_hud_label("")
	left_panel.add_child(status_label)
	left_panel.add_child(timer_label)
	left_panel.add_child(ammo_label)
	left_panel.add_child(body_label)
	left_panel.add_child(treatment_label)
	end_label = _make_hud_label("")
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_label.add_theme_font_size_override("font_size", 34)
	end_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	end_label.offset_left = -520.0
	end_label.offset_right = 520.0
	end_label.offset_top = -120.0
	end_label.offset_bottom = 120.0
	hud_layer.add_child(end_label)
	mental.setup(camera, corruption_overlay, status_label)

func _make_hud_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.95))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not run_finished:
		yaw -= event.relative.x * InputBus.mouse_sensitivity
		var y_sign := -1.0 if InputBus.invert_y else 1.0
		pitch -= event.relative.y * InputBus.mouse_sensitivity * y_sign
		pitch = clamp(pitch, deg_to_rad(-82.0), deg_to_rad(82.0))
		rotation.y = yaw
		head.rotation.x = pitch
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif event.keycode == KEY_ENTER:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_interact(event):
			_try_interact()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_build_next(event):
			build_system.cycle_next()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_build_place(event):
			build_system.try_place()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_reload(event):
			weapon.start_reload()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_quick_bandage(event):
			health.start_quick_bandage()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_trauma_kit(event):
			health.start_trauma_kit()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_injector(event):
			health.use_injector()
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_neural_stabilizer(event):
			health.use_neural_stabilizer(mental)
		elif not run_finished and intro_lock_timer <= 0.0 and InputBus.wants_shove(event):
			_try_shove()
		elif run_finished and allow_restart and InputBus.wants_restart(event):
			get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	if run_finished or health.is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if intro_lock_timer > 0.0:
		intro_lock_timer = max(0.0, intro_lock_timer - delta)
		velocity = Vector3.ZERO
		move_and_slide()
		var intro_blend := smoothstep(0.0, 1.0, 1.0 - intro_lock_timer / intro_duration)
		head.position.y = lerp(intro_start_head_y, 1.58, intro_blend)
		camera.rotation.z = lerp(intro_start_roll, 0.0, intro_blend)
		weapon_pivot.position = weapon_obstructed_position.lerp(weapon_default_position, intro_blend)
		weapon_pivot.rotation = Vector3(deg_to_rad(-28.0 * (1.0 - intro_blend)), 0.0, 0.0)
		if intro_lock_timer <= 0.0 and intro_message_active:
			end_label.text = ""
			intro_message_active = false
		return
	var move_input := InputBus.get_move_vector()
	is_crouching = InputBus.wants_crouch()
	var wish_dir := (global_transform.basis * Vector3(move_input.x, 0.0, move_input.y)).normalized()
	var speed := _get_target_speed(move_input)
	var control := acceleration if is_on_floor() else air_control
	var target_velocity := wish_dir * speed
	velocity.x = lerp(velocity.x, target_velocity.x, clamp(control * delta, 0.0, 1.0))
	velocity.z = lerp(velocity.z, target_velocity.z, clamp(control * delta, 0.0, 1.0))
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.05
	move_and_slide()
	_update_stamina(move_input, delta)
	_update_crouch(delta)
	_update_weapon_obstruction(delta)
	shove_cooldown = max(0.0, shove_cooldown - delta)
	_emit_movement_noise(delta, move_input, speed)

func _process(delta: float) -> void:
	_update_hud()

func _get_target_speed(move_input: Vector2) -> float:
	var movement_penalty := health.get_movement_modifier() * health.get_stamina_modifier()
	if is_crouching:
		return crouch_speed * movement_penalty
	if InputBus.wants_sprint() and stamina > 1.0 and move_input.length() > 0.1:
		return sprint_speed * movement_penalty
	return walk_speed * movement_penalty

func _update_stamina(move_input: Vector2, delta: float) -> void:
	var sprinting := InputBus.wants_sprint() and move_input.length() > 0.1 and not is_crouching
	if sprinting:
		stamina = max(0.0, stamina - sprint_stamina_cost * delta)
	else:
		stamina = min(max_stamina, stamina + stamina_recovery * health.get_stamina_modifier() * delta)

func _update_crouch(delta: float) -> void:
	var target_head_y := 1.08 if is_crouching else 1.58
	head.position.y = lerp(head.position.y, target_head_y, delta * 10.0)
	capsule_shape.height = lerp(capsule_shape.height, 1.05 if is_crouching else 1.55, delta * 10.0)
	collision_shape.position.y = lerp(collision_shape.position.y, 0.62 if is_crouching else 0.86, delta * 10.0)

func _emit_movement_noise(delta: float, move_input: Vector2, speed: float) -> void:
	noise_timer -= delta
	if move_input.length() <= 0.1 or noise_timer > 0.0:
		return
	var loudness := 8.0
	if speed > walk_speed:
		loudness = 24.0
	elif is_crouching:
		loudness = 3.0
	GameEvents.emit_player_noise(global_position, loudness)
	noise_timer = 0.45 if is_crouching else 0.28

func _update_hud() -> void:
	if not ammo_label:
		return
	ammo_label.text = "%s: %s" % [weapon.data.weapon_name, weapon.get_ammo_display()]
	var body_text := ""
	for line in health.get_status_lines():
		body_text += line + "\n"
	body_label.text = body_text
	if health.active_treatment.is_empty():
		var foul_text := "   BARREL FOULED" if barrel_obstruction > 0.55 else ""
		var build_text := ""
		if build_system:
			build_text = "   G %s   C NEXT" % build_system.get_selected_status()
		treatment_label.text = "E USE   F SHOVE   B BANDAGE   T TRAUMA KIT   V INJECTOR   X STABILIZER" + build_text + foul_text
	else:
		treatment_label.text = "TREATING: %s %.1fs" % [health.active_treatment.to_upper(), health.treatment_time_left]

func _update_weapon_obstruction(delta: float) -> void:
	if not camera or not weapon_pivot:
		return
	var forward := -camera.global_transform.basis.z
	var wall_obstruction := _get_forward_obstruction(forward)
	var enemy_interference := _get_close_enemy_interference(forward)
	barrel_obstruction = max(wall_obstruction, enemy_interference.x)
	barrel_push_side = enemy_interference.y
	if wall_obstruction > enemy_interference.x:
		barrel_push_side = 0.0
	var target_position := weapon_default_position.lerp(weapon_obstructed_position, barrel_obstruction)
	if abs(barrel_push_side) > 0.01:
		target_position.x += barrel_push_side * barrel_obstruction * 0.18
	weapon_pivot.position = weapon_pivot.position.lerp(target_position, clamp(delta * 14.0, 0.0, 1.0))
	var target_rotation := Vector3(
		deg_to_rad(-20.0 * barrel_obstruction),
		deg_to_rad(24.0 * barrel_push_side * barrel_obstruction),
		deg_to_rad(10.0 * barrel_push_side * barrel_obstruction)
	)
	weapon_pivot.rotation = weapon_pivot.rotation.lerp(target_rotation, clamp(delta * 12.0, 0.0, 1.0))
	weapon.set_barrel_interference(barrel_obstruction, barrel_push_side)

func _get_forward_obstruction(forward: Vector3) -> float:
	var start := camera.global_position
	var end := start + forward * 1.15
	var query := PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [get_rid()]
	query.collision_mask = 1 | 2 | 4
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return 0.0
	var distance := start.distance_to(hit.get("position"))
	return clamp(1.0 - distance / 1.15, 0.0, 1.0)

func _get_close_enemy_interference(forward: Vector3) -> Vector2:
	var best_amount := 0.0
	var best_side := 0.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node3D):
			continue
		var to_enemy: Vector3 = enemy.global_position + Vector3.UP - camera.global_position
		var distance := to_enemy.length()
		if distance > 1.35:
			continue
		var forward_dot := forward.dot(to_enemy.normalized())
		if forward_dot < 0.35:
			continue
		var local_enemy := camera.global_transform.affine_inverse() * enemy.global_position
		var side := sign(local_enemy.x)
		if side == 0.0:
			side = 1.0 if randf() > 0.5 else -1.0
		var amount := clamp(1.0 - (distance - 0.35) / 1.0, 0.0, 1.0) * forward_dot
		if amount > best_amount:
			best_amount = amount
			best_side = side
	return Vector2(best_amount, best_side)

func _try_shove() -> void:
	if shove_cooldown > 0.0 or health.is_dead or not health.active_treatment.is_empty():
		return
	shove_cooldown = shove_cooldown_time
	GameEvents.emit_player_noise(global_position, 20.0)
	var shoved := false
	var forward := -camera.global_transform.basis.z
	GameEvents.emit_environment_impulse(camera.global_position + forward * 1.0, 1.55, 9.0, self, "player_shove")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node3D):
			continue
		var to_enemy: Vector3 = enemy.global_position + Vector3.UP - camera.global_position
		var distance := to_enemy.length()
		if distance > 1.75:
			continue
		if forward.dot(to_enemy.normalized()) < 0.25:
			continue
		if enemy.has_method("apply_shove"):
			enemy.apply_shove(global_position, 7.5, 0.55)
			shoved = true
	if shoved:
		weapon_pivot.position += Vector3(0.0, 0.06, 0.08)

func _try_interact() -> void:
	var start := camera.global_position
	var forward := -camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(start, start + forward * 2.6)
	query.exclude = [get_rid()]
	query.collision_mask = 1 | 2 | 4
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		GameEvents.emit_environment_impulse(start + forward * 1.2, 0.9, 2.5, self, "use_air_push")
		return
	var collider = hit.get("collider")
	var hit_position: Vector3 = hit.get("position")
	if collider and collider.has_method("use"):
		collider.use(self)
	else:
		GameEvents.emit_environment_impulse(hit_position, 0.8, 2.5, self, "use_push")

func set_run_time(remaining_seconds: float, extraction_active: bool) -> void:
	if not timer_label:
		return
	var minutes := int(remaining_seconds / 60.0)
	var seconds := int(remaining_seconds) % 60
	var extraction_text := "EXTRACT ONLINE" if extraction_active else "EXTRACT LOCKED"
	timer_label.text = "SURVIVE: %02d:%02d   %s   STAM %d" % [minutes, seconds, extraction_text, int(stamina)]

func show_end_state(success: bool, reason: String) -> void:
	run_finished = true
	allow_restart = true
	if weapon:
		weapon.set_process(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	end_label.text = ("%s\n%s\nPress R to restart" % ["EXTRACTED" if success else "DEAD", reason])
	end_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65) if success else Color(1.0, 0.25, 0.25))

func show_death_handoff(reason: String) -> void:
	run_finished = true
	allow_restart = false
	if weapon:
		weapon.set_process(false)
	end_label.text = "SURVIVOR LOST\n%s\nFacility state persists" % reason
	end_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))

func play_spawn_intro(entry_text: String, intro_style: String = "door") -> void:
	run_finished = false
	allow_restart = false
	_configure_intro_style(intro_style)
	intro_lock_timer = intro_duration
	intro_message_active = true
	if head:
		head.position.y = intro_start_head_y
	if camera:
		camera.rotation.z = intro_start_roll
	if weapon_pivot:
		weapon_pivot.position = weapon_obstructed_position
		weapon_pivot.rotation = Vector3(deg_to_rad(-28.0), 0.0, 0.0)
	if weapon:
		weapon.set_process(true)
	if end_label:
		end_label.text = entry_text
		end_label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.88))
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _configure_intro_style(intro_style: String) -> void:
	intro_duration = 1.05
	intro_start_head_y = 1.08
	intro_start_roll = 0.0
	if intro_style == "crawl":
		intro_duration = 1.25
		intro_start_head_y = 0.52
		intro_start_roll = deg_to_rad(-8.0)
	elif intro_style == "fall":
		intro_duration = 1.2
		intro_start_head_y = 3.05
		intro_start_roll = deg_to_rad(12.0)
	elif intro_style == "catwalk":
		intro_duration = 1.35
		intro_start_head_y = 2.65
		intro_start_roll = deg_to_rad(-20.0)
	elif intro_style == "shaft":
		intro_duration = 1.3
		intro_start_head_y = 2.45
		intro_start_roll = deg_to_rad(18.0)
	elif intro_style == "pod":
		intro_duration = 1.15
		intro_start_head_y = 1.0
		intro_start_roll = deg_to_rad(24.0)
	elif intro_style == "tumble":
		intro_duration = 1.4
		intro_start_head_y = 1.95
		intro_start_roll = deg_to_rad(-32.0)

func _on_health_died(reason: String) -> void:
	died.emit(reason)
