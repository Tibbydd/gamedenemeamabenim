extends StaticBody3D
class_name HiddenRouteTrigger3D

var route_id: String = ""
var exit_position: Vector3 = Vector3.ZERO
var route_kind: String = "vent"
var mesh_instance: MeshInstance3D

func configure(new_route_id: String, new_route_kind: String, size: Vector3, color: Color, destination: Vector3) -> void:
	route_id = new_route_id
	route_kind = new_route_kind
	exit_position = destination
	collision_layer = 1
	collision_mask = 1 | 8
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	add_child(collision)
	mesh_instance = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = EffectMaterialCache.get_material(color, 0.15)
	add_child(mesh_instance)

func use(actor: Node) -> void:
	if not (actor is PlayerControllerFPS):
		return
	var player := actor as PlayerControllerFPS
	if route_kind in ["vent", "crawlspace"] and not player.is_crouching:
		player.notify_service_failure("Too tight. Crouch before entering.")
		return
	GameEvents.emit_player_noise(global_position, 9.0 if route_kind == "vent" else 6.0)
	GameEvents.request_sound("movement", global_position, 0.55)
	player.global_position = exit_position
	player.play_spawn_intro("HIDDEN ROUTE\n%s" % route_id.replace("_", " ").to_upper(), "crawl" if route_kind in ["vent", "crawlspace"] else "catwalk")
