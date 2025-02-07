extends Node3D
class_name CameraManager

@export var mounts: Array[Node3D]
@onready var camera: Camera3D = $Camera
var current_mount_index: int = 0

func _ready():
	reparent_camera(mounts[0])

func reparent_camera(new_parent: Node3D) -> void:
	camera.reparent(new_parent)
	# Reset transforms after reparenting
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	camera.scale = Vector3.ONE

func next_mount() -> void:
	current_mount_index = (current_mount_index + 1) % mounts.size()
	reparent_camera(mounts[current_mount_index])
