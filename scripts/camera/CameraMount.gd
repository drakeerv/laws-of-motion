extends Node3D
class_name CameraMount

# Behavior flags
@export var look_at_target: bool = true
@export var disconnected_follow: bool = false

# Follow configuration
@export var follow_speed: float = 5.0
@export var rotation_speed: float = 5.0
@export var look_at_node: Node3D

# Internal state
var target_position: Vector3
var initial_rotation: Quaternion
var world_position: Vector3
var local_offset: Vector3  # Replace position_offset with this

func _ready() -> void:
    initial_rotation = quaternion
    world_position = global_position
    local_offset = position  # Store initial local offset

func _physics_process(delta: float) -> void:
    if disconnected_follow:
        var target_world_pos = get_parent().global_position + local_offset
        world_position = world_position.lerp(target_world_pos, follow_speed * delta)
        global_position = world_position
    else:
        position = local_offset
    
    if look_at_target and look_at_node:
        # Look at target using global transform
        var target_pos = look_at_node.global_position
        global_transform = global_transform.looking_at(target_pos, Vector3.UP)