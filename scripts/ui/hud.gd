extends CanvasLayer

@onready var hp_bar: ProgressBar = $Root/Top/HpBar
@onready var energy_bar: ProgressBar = $Root/Top/EnergyBar
@onready var scan_button: Button = $Root/Bottom/ScanButton
@onready var end_panel: ColorRect = $EndPanel
@onready var end_label: Label = $EndPanel/Center/VBox/EndLabel

var player: Node = null
var ended: bool = false

func _ready() -> void:
	end_panel.visible = false
	scan_button.pressed.connect(_on_scan_button)
	GameEvents.player_died.connect(func(): _show_end("MIND LOST", Color(1.0, 0.35, 0.4)))
	GameEvents.player_won.connect(func(): _show_end("MEMORY RECOVERED", Color(0.35, 1.0, 0.55)))
	call_deferred("_bind_player")

func _bind_player() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	if player == null:
		return
	hp_bar.value = player.hp
	energy_bar.value = player.energy
	scan_button.disabled = not player.can_scan()

func _on_scan_button() -> void:
	Input.action_press("hack_scan")
	Input.action_release("hack_scan")

func _show_end(text: String, color: Color) -> void:
	if ended:
		return
	ended = true
	end_panel.visible = true
	end_label.text = text
	end_label.modulate = color
	scan_button.disabled = true

func _unhandled_input(event: InputEvent) -> void:
	if not ended:
		return
	var trigger := false
	if event is InputEventKey and event.pressed:
		trigger = true
	elif event is InputEventMouseButton and event.pressed:
		trigger = true
	elif event is InputEventScreenTouch and event.pressed:
		trigger = true
	if trigger:
		get_tree().reload_current_scene()
