extends Node
class_name EffectsManager

# Visual effects management for CURSOR: Fragments of the Forgotten

static func create_glitch_effect(target_node: Node2D, duration: float = 0.5) -> void:
	# Create digital glitch effect
	var original_position = target_node.position
	var glitch_intensity = 5.0
	
	var tween = target_node.create_tween()
	tween.set_loops(int(duration * 10))  # 10 glitches per second
	
	for i in range(int(duration * 10)):
		var offset = Vector2(
			randf_range(-glitch_intensity, glitch_intensity),
			randf_range(-glitch_intensity, glitch_intensity)
		)
		tween.tween_property(target_node, "position", original_position + offset, 0.05)
		tween.tween_property(target_node, "position", original_position, 0.05)

static func create_data_stream_effect(start_pos: Vector2, end_pos: Vector2, parent: Node2D, color: Color = Color.CYAN) -> void:
	# Create flowing data stream between two points
	var stream_container = Node2D.new()
	parent.add_child(stream_container)
	stream_container.global_position = start_pos
	
	var particle_count = 8
	for i in range(particle_count):
		var particle = ColorRect.new()
		particle.size = Vector2(3, 3)
		particle.color = color
		particle.position = Vector2.ZERO
		stream_container.add_child(particle)
		
		var delay = i * 0.1
		var tween = particle.create_tween()
		tween.tween_delay(delay)
		tween.tween_property(particle, "global_position", end_pos, 1.0)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.0)
		tween.tween_callback(particle.queue_free)
	
	# Clean up container
	var cleanup_tween = parent.create_tween()
	cleanup_tween.tween_delay(2.0)
	cleanup_tween.tween_callback(stream_container.queue_free)

static func create_explosion_effect(center: Vector2, parent: Node2D, color: Color = Color.WHITE, size: float = 50.0) -> void:
	# Create explosion particle effect
	var explosion_container = Node2D.new()
	parent.add_child(explosion_container)
	explosion_container.global_position = center
	
	var particle_count = 15
	for i in range(particle_count):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = color
		particle.position = Vector2(-2, -2)
		explosion_container.add_child(particle)
		
		var angle = (i / float(particle_count)) * TAU
		var distance = randf_range(size * 0.5, size)
		var target_pos = Vector2(cos(angle), sin(angle)) * distance
		
		var tween = particle.create_tween()
		tween.parallel().tween_property(particle, "position", target_pos, 0.8)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.8)
		tween.tween_callback(particle.queue_free)
	
	# Clean up container
	var cleanup_tween = parent.create_tween()
	cleanup_tween.tween_delay(1.0)
	cleanup_tween.tween_callback(explosion_container.queue_free)

static func create_screen_flash(color: Color = Color.WHITE, duration: float = 0.2) -> void:
	# Create fullscreen flash effect
	var main_scene = Engine.get_main_loop().current_scene
	if not main_scene:
		return
	
	var flash = ColorRect.new()
	flash.color = color
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Make it fullscreen
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	main_scene.add_child(flash)
	
	var tween = flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_callback(flash.queue_free)

static func create_pulse_effect(target_node: Node2D, scale_multiplier: float = 1.5, duration: float = 0.3) -> void:
	# Create pulsing scale effect
	var original_scale = target_node.scale
	
	var tween = target_node.create_tween()
	tween.tween_property(target_node, "scale", original_scale * scale_multiplier, duration * 0.5)
	tween.tween_property(target_node, "scale", original_scale, duration * 0.5)

static func create_digital_noise_particles(center: Vector2, parent: Node2D, count: int = 10, color: Color = Color.CYAN) -> void:
	# Create scattered digital noise particles
	for i in range(count):
		var particle = ColorRect.new()
		particle.size = Vector2(2, 2)
		particle.color = color
		
		var angle = randf() * TAU
		var distance = randf_range(20, 80)
		var spawn_pos = center + Vector2(cos(angle), sin(angle)) * distance
		particle.global_position = spawn_pos
		
		parent.add_child(particle)
		
		# Flicker effect
		var tween = particle.create_tween()
		tween.set_loops(3)
		tween.tween_property(particle, "modulate:a", 0.0, 0.1)
		tween.tween_property(particle, "modulate:a", 1.0, 0.1)
		tween.tween_callback(particle.queue_free)

static func create_scan_lines_effect(target_node: Node2D, line_count: int = 5, duration: float = 1.0) -> void:
	# Create scanning lines effect
	var bounds = target_node.get_viewport_rect()
	
	for i in range(line_count):
		var line = ColorRect.new()
		line.size = Vector2(bounds.size.x, 2)
		line.color = Color.CYAN
		line.color.a = 0.3
		line.position = Vector2(0, -10)
		target_node.add_child(line)
		
		var delay = i * 0.1
		var tween = line.create_tween()
		tween.tween_delay(delay)
		tween.tween_property(line, "position:y", bounds.size.y + 10, duration)
		tween.tween_callback(line.queue_free)

static func apply_cyberpunk_button_style(button: Button) -> void:
	# Apply cyberpunk styling to buttons
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.1, 0.3, 0.8)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color.CYAN
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.2, 0.2, 0.4, 0.9)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 2
	style_hover.border_color = Color.WHITE
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.3, 0.3, 0.5, 1.0)
	style_pressed.border_width_left = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_top = 2
	style_pressed.border_width_bottom = 2
	style_pressed.border_color = Color.GREEN
	style_pressed.corner_radius_top_left = 4
	style_pressed.corner_radius_top_right = 4
	style_pressed.corner_radius_bottom_left = 4
	style_pressed.corner_radius_bottom_right = 4
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	
	# Text styling
	button.add_theme_color_override("font_color", Color.CYAN)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.GREEN)

static func apply_cyberpunk_panel_style(panel: Panel) -> void:
	# Apply cyberpunk styling to panels
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.15, 0.9)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color.CYAN
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	panel.add_theme_stylebox_override("panel", style)

static func apply_cyberpunk_progressbar_style(progress_bar: ProgressBar) -> void:
	# Apply cyberpunk styling to progress bars
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style_bg.border_width_left = 1
	style_bg.border_width_right = 1
	style_bg.border_width_top = 1
	style_bg.border_width_bottom = 1
	style_bg.border_color = Color(0.3, 0.3, 0.3)
	
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color.CYAN
	style_fg.corner_radius_top_left = 2
	style_fg.corner_radius_top_right = 2
	style_fg.corner_radius_bottom_left = 2
	style_fg.corner_radius_bottom_right = 2
	
	progress_bar.add_theme_stylebox_override("background", style_bg)
	progress_bar.add_theme_stylebox_override("fill", style_fg)

static func create_hologram_effect(target_node: Node2D, duration: float = 2.0) -> void:
	# Create holographic appearance effect
	var original_modulate = target_node.modulate
	
	var tween = target_node.create_tween()
	tween.set_loops()
	tween.tween_property(target_node, "modulate:a", 0.6, 0.5)
	tween.tween_property(target_node, "modulate:a", 0.9, 0.5)
	
	# Add slight blue tint
	target_node.modulate = original_modulate * Color(0.8, 0.9, 1.2, 1.0)
	
	# Clean up after duration
	if duration > 0:
		var cleanup_tween = target_node.create_tween()
		cleanup_tween.tween_delay(duration)
		cleanup_tween.tween_callback(func():
			tween.kill()
			target_node.modulate = original_modulate
		)

static func create_loading_dots(parent: Control, position: Vector2, color: Color = Color.CYAN) -> Node2D:
	# Create animated loading dots
	var container = Node2D.new()
	parent.add_child(container)
	container.position = position
	
	for i in range(3):
		var dot = ColorRect.new()
		dot.size = Vector2(6, 6)
		dot.color = color
		dot.position = Vector2(i * 10, 0)
		container.add_child(dot)
		
		var tween = dot.create_tween()
		tween.set_loops()
		tween.tween_delay(i * 0.2)
		tween.tween_property(dot, "modulate:a", 0.3, 0.3)
		tween.tween_property(dot, "modulate:a", 1.0, 0.3)
	
	return container

static func create_matrix_rain_effect(parent: Node2D, duration: float = 3.0) -> void:
	# Create Matrix-style digital rain effect
	var viewport_size = parent.get_viewport_rect().size
	var char_size = Vector2(8, 12)
	var columns = int(viewport_size.x / char_size.x)
	
	for col in range(columns):
		if randf() < 0.3:  # Not every column gets rain
			create_rain_column(parent, col * char_size.x, char_size, duration)

static func create_rain_column(parent: Node2D, x_pos: float, char_size: Vector2, duration: float) -> void:
	# Create a single column of matrix rain
	var column_height = parent.get_viewport_rect().size.y
	var char_count = int(column_height / char_size.y) + 5
	
	for i in range(char_count):
		var char_label = Label.new()
		char_label.text = str(randi_range(0, 9))  # Random digits
		char_label.add_theme_color_override("font_color", Color.GREEN)
		char_label.position = Vector2(x_pos, -char_size.y * i)
		parent.add_child(char_label)
		
		var tween = char_label.create_tween()
		tween.tween_property(char_label, "position:y", column_height + char_size.y, duration)
		tween.parallel().tween_property(char_label, "modulate:a", 0.0, duration * 0.8)
		tween.tween_callback(char_label.queue_free)