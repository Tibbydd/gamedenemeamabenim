extends Area3D
class_name DoorLockHousing3D

var parent_door: FacilityDoor3D
var armor: float = 18.0

func setup(door: FacilityDoor3D, side_offset: float) -> void:
	parent_door = door
	collision_layer = 4
	collision_mask = 8
	position = Vector3(side_offset, 0.12, -0.08)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.24, 0.38, 0.16)
	collision.shape = shape
	add_child(collision)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = EffectMaterialCache.get_material(Color(0.46, 0.26, 0.1), 0.25)
	add_child(mesh_instance)

func apply_hit(damage: float, hit_position: Vector3, hit_direction: Vector3, weapon_name: String) -> void:
	if parent_door:
		parent_door.apply_lock_hit(max(0.0, damage - armor), hit_position, hit_direction, weapon_name)
