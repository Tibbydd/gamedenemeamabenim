extends Control

var _scanline_timer: float = 0.0
var _flicker_timer: float = 0.0
var _title_label: Label
var _subtitle_label: Label
var _start_btn: Button
var _settings_btn: Button
var _quit_btn: Button
var _settings_panel: Panel
var _controls_label: Label
var _version_label: Label

func _ready() -> void:
	_build_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta: float) -> void:
	_scanline_timer += delta
	_flicker_timer += delta
	if _flicker_timer > randf_range(6.0, 14.0) and _title_label:
		_do_title_flicker()
		_flicker_timer = 0.0

func _do_title_flicker() -> void:
	var tween := _title_label.create_tween()
	tween.tween_property(_title_label, "modulate:a", 0.35, 0.04)
	tween.tween_property(_title_label, "modulate:a", 1.0, 0.06)
	tween.tween_property(_title_label, "modulate:a", 0.55, 0.03)
	tween.tween_property(_title_label, "modulate:a", 1.0, 0.08)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.026, 0.030, 0.038)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_build_scanlines()
	_build_left_panel()
	_build_right_controls()
	_build_settings_panel()

func _build_scanlines() -> void:
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	for i in range(0, 1080, 4):
		var line := ColorRect.new()
		line.color = Color(0.0, 0.0, 0.0, 0.12)
		line.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		line.offset_top = float(i)
		line.offset_bottom = float(i) + 1.0
		canvas.add_child(line)

func _build_left_panel() -> void:
	var panel := VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	panel.offset_left = 88.0
	panel.offset_top = -260.0
	panel.offset_right = 560.0
	panel.offset_bottom = 260.0
	add_child(panel)

	_title_label = Label.new()
	_title_label.text = "PERCEPTION BREACH"
	_title_label.add_theme_font_size_override("font_size", 56)
	_title_label.add_theme_color_override("font_color", Color(0.88, 0.98, 0.92))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.6, 0.4, 0.55))
	_title_label.add_theme_constant_override("shadow_offset_x", 3)
	_title_label.add_theme_constant_override("shadow_offset_y", 3)
	panel.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.text = "STATION: UNRESPONSIVE  ·  UNKNOWN FLOOR"
	_subtitle_label.add_theme_font_size_override("font_size", 14)
	_subtitle_label.add_theme_color_override("font_color", Color(0.48, 0.72, 0.62, 0.78))
	panel.add_child(_subtitle_label)

	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 42)
	panel.add_child(spacer1)

	_start_btn = _make_button("[ ENTER STATION ]", Color(0.72, 1.0, 0.82))
	_start_btn.pressed.connect(_on_start)
	panel.add_child(_start_btn)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	panel.add_child(spacer2)

	_settings_btn = _make_button("[ CONTROLS ]", Color(0.58, 0.78, 0.68))
	_settings_btn.pressed.connect(_on_settings)
	panel.add_child(_settings_btn)

	var spacer3 := Control.new()
	spacer3.custom_minimum_size = Vector2(0, 10)
	panel.add_child(spacer3)

	_quit_btn = _make_button("[ DISCONNECT ]", Color(0.72, 0.42, 0.38))
	_quit_btn.pressed.connect(_on_quit)
	panel.add_child(_quit_btn)

	var spacer4 := Control.new()
	spacer4.custom_minimum_size = Vector2(0, 48)
	panel.add_child(spacer4)

	_version_label = Label.new()
	_version_label.text = "PROTOTYPE BUILD  ·  BREACH PROTOCOL α"
	_version_label.add_theme_font_size_override("font_size", 12)
	_version_label.add_theme_color_override("font_color", Color(0.32, 0.48, 0.42, 0.6))
	panel.add_child(_version_label)

func _build_right_controls() -> void:
	var lore_label := Label.new()
	lore_label.text = (
		"COGNITIVE ANCHOR\n" +
		"SYSTEM NOMINAL\n\n" +
		"The facility is not responding\n" +
		"to standard neural handshakes.\n\n" +
		"Last survivor: unaccounted.\n" +
		"Station status: compromised.\n\n" +
		"Proceed at your own risk."
	)
	lore_label.add_theme_font_size_override("font_size", 15)
	lore_label.add_theme_color_override("font_color", Color(0.42, 0.62, 0.56, 0.72))
	lore_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	lore_label.offset_left = -480.0
	lore_label.offset_top = -140.0
	lore_label.offset_right = -88.0
	lore_label.offset_bottom = 160.0
	add_child(lore_label)

func _build_settings_panel() -> void:
	_settings_panel = Panel.new()
	_settings_panel.visible = false
	_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_settings_panel.offset_left = -340.0
	_settings_panel.offset_top = -260.0
	_settings_panel.offset_right = 340.0
	_settings_panel.offset_bottom = 260.0
	add_child(_settings_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.07, 0.96)
	style.border_color = Color(0.42, 0.78, 0.62, 0.65)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	_settings_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 32.0
	vbox.offset_top = 24.0
	vbox.offset_right = -32.0
	vbox.offset_bottom = -24.0
	_settings_panel.add_child(vbox)

	var title := Label.new()
	title.text = "CONTROL REFERENCE"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.78, 1.0, 0.88))
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(sp)

	_controls_label = Label.new()
	_controls_label.text = (
		"WASD          Move\n" +
		"SPACE         Jump\n" +
		"CTRL          Crouch (hold)\n" +
		"Z             Prone  (hold to dive-roll)\n" +
		"SHIFT         Sprint\n" +
		"ALT           Stealth step\n" +
		"LMB           Fire\n" +
		"RMB           Aim\n" +
		"R             Reload\n" +
		"F             Shove / Throw\n" +
		"E             Interact / Pick up\n" +
		"H             Magazine check\n" +
		"I             Inspect weapon\n" +
		"B             Quick bandage\n" +
		"T             Trauma kit\n" +
		"X             Neural stabilizer\n" +
		"TAB           Inventory\n" +
		"F3            Debug overlay\n" +
		"ESC / ENTER   Release / Capture mouse"
	)
	_controls_label.add_theme_font_size_override("font_size", 15)
	_controls_label.add_theme_color_override("font_color", Color(0.72, 0.92, 0.82))
	vbox.add_child(_controls_label)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(sp2)

	var close_btn := _make_button("[ CLOSE ]", Color(0.62, 0.88, 0.72))
	close_btn.pressed.connect(_on_close_settings)
	vbox.add_child(close_btn)

func _make_button(text_value: String, accent_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text_value
	btn.custom_minimum_size = Vector2(280, 46)
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style_normal.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.45)
	style_normal.border_width_left = 1
	style_normal.border_width_right = 1
	style_normal.border_width_top = 1
	style_normal.border_width_bottom = 1
	var style_hover := style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color(accent_color.r * 0.1, accent_color.g * 0.1, accent_color.b * 0.1, 0.55)
	style_hover.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.9)
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("focus", style_normal)
	btn.add_theme_color_override("font_color", accent_color)
	btn.add_theme_color_override("font_hover_color", Color(accent_color.r, accent_color.g, accent_color.b, 1.0))
	btn.add_theme_font_size_override("font_size", 18)
	return btn

func _on_start() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/PrototypeArena.tscn")
	)

func _on_settings() -> void:
	_settings_panel.visible = true
	_settings_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_settings_panel, "modulate:a", 1.0, 0.22)

func _on_close_settings() -> void:
	var tween := create_tween()
	tween.tween_property(_settings_panel, "modulate:a", 0.0, 0.18)
	tween.tween_callback(func() -> void: _settings_panel.visible = false)

func _on_quit() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.28)
	tween.tween_callback(func() -> void: get_tree().quit())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _settings_panel and _settings_panel.visible:
		_on_close_settings()
