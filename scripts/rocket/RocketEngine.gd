extends Node3D
class_name RocketEngine

@export var throttle: float = 1.0
@onready var exhaust: MeshInstance3D = $Exhaust
var current_throttle: float = 0.0
var throttle_speed: float = 5.0

func _process(delta):
	current_throttle = lerp(current_throttle, throttle, throttle_speed * delta)
	(exhaust.mesh as Mesh).surface_get_material(0).set_shader_parameter("throttle", current_throttle)

func skip_to_launch():
	throttle = 1.0
	current_throttle = 1.0
