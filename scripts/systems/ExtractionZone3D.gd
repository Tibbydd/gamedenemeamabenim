extends Area3D
class_name ExtractionZone3D

var radius: float = 2.75
var display_name: String = "Extraction Zone"
var marker_light: OmniLight3D
var ring_mesh: MeshInstance3D
var pulse_time: float = 0.0
var used: bool = false

func configure(new_radius: float = 2.75) -> void:
	radius = new_radius
	_build_zone()

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)

func get_display_name() -> String:
	return display_name

func _process(delta: float) -> void:
	pulse_time += delta
	var pulse: float = 0.5 + sin(pulse_time * 3.2) * 0.5
	if marker_light:
		marker_light.light_energy = 2.2 + pulse * 1.4
	if ring_mesh:
		var scale_value: float = 1.0 + pulse * 0.08
		ring_mesh.scale = Vector3(scale_value, 1.0, scale_value)

func _build_zone() -> void:
	var collision: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = radius
	collision.shape = sphere
	add_child(collision)
	ring_mesh = MeshInstance3D.new()
	ring_mesh.name = "ExtractionRing"
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.035
	cylinder.radial_segments = 48
	ring_mesh.mesh = cylinder
	ring_mesh.position.y = 0.035
	ring_mesh.material_override = EffectMaterialCache.get_material(Color(0.12, 0.82, 0.95, 0.68), 1.15)
	add_child(ring_mesh)
	for index in range(4):
		var angle: float = float(index) * TAU / 4.0
		var arrow: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.32, 0.05, 1.1)
		arrow.mesh = box
		arrow.position = Vector3(cos(angle) * (radius + 0.42), 0.09, sin(angle) * (radius + 0.42))
		arrow.rotation.y = -angle
		arrow.material_override = EffectMaterialCache.get_material(Color(0.16, 0.95, 1.0), 0.95)
		add_child(arrow)
	marker_light = OmniLight3D.new()
	marker_light.name = "ExtractionPulseLight"
	marker_light.light_color = Color(0.28, 0.9, 1.0)
	marker_light.omni_range = 13.0
	marker_light.shadow_enabled = true
	marker_light.position = Vector3(0.0, 1.4, 0.0)
	add_child(marker_light)

func _on_body_entered(body: Node3D) -> void:
	if used:
		return
	if body is PlayerControllerFPS:
		used = true
		GameEvents.end_run(true, "extraction_complete")
