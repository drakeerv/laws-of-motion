extends RigidBody3D
class_name Rocket

@export var max_force: float = 1000.0
@export var throttle: float = 0.0
@export var fuel = 1.0
@export var fuel_consumption_rate: float = 0.1

func _ready():
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if fuel > 0:
		fuel = max(0, fuel - (fuel_consumption_rate * throttle * delta))
		$Engine.throttle = throttle
		var force = Vector3.UP * (max_force * throttle)
		apply_force(force * delta, $Engine.global_transform.origin)
	else:
		$Engine.throttle = 0.0
