extends RigidBody3D
class_name Rocket

signal launch_completed
signal max_altitude_reached(height: float)

# Launch Configuration
@export var launch_stabilization_distance: float = 5.0
var launch_complete: bool = false
var initial_position: Vector3
var launch_started: bool = false
var after_launch_callback: Callable

# Thrust Configuration
@export var max_force: float = 500.0
@export var thrust_randomness: float = 0.05
@export var throttle_curve: Curve

# Fuel System
@export var fuel: float = 1.0
@export var fuel_consumption_rate: float = 0.5

# Components
@onready var rocket_engine: RocketEngine = $RocketEngine
@onready var rng = RandomNumberGenerator.new()

# Fin Configuration
@export var air_density: float = 1.225  # kg/m³ at sea level
@export var fin_area: float = 0.02  # m² (total area of all fins)
@export var fin_lift_coefficient: float = 0.8  # Reduced from 2.0
@export var fin_distance_from_cg: float = 1.0  # Distance from CG to fins
@export var max_stabilization_torque: float = 50.0  # Limit maximum torque
@export var angular_damping: float = 0.85  # Damping factor

var current_air_resistance: float = 0.0

# Physics tracking
var previous_velocity: Vector3
var current_acceleration: Vector3

var max_altitude: float = 0.0
var max_altitude_callback: Callable
var previous_altitude: float = 0.0
var falling: bool = false

var fall_detection_threshold: float = 0.1  # meters

func _ready() -> void:
	previous_velocity = Vector3.ZERO
	_setup_physics()
	_initialize_launch()
	# Lock all axes initially
	axis_lock_linear_x = true
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true

func _setup_physics() -> void:
	set_physics_process(true)
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = true

func _initialize_launch() -> void:
	initial_position = global_position

func _physics_process(delta: float) -> void:
	# Calculate acceleration
	current_acceleration = (linear_velocity - previous_velocity) / delta
	previous_velocity = linear_velocity
	
	# Track max altitude
	var current_altitude = global_position.y
	if current_altitude > max_altitude:
		max_altitude = current_altitude
		previous_altitude = current_altitude
	elif not falling and (previous_altitude - current_altitude) > fall_detection_threshold:
		print("Max altitude reached: ", max_altitude)
		falling = true
		max_altitude_reached.emit(max_altitude)
		if max_altitude_callback.is_valid():
			print("Calling max altitude callback")
			max_altitude_callback.call(max_altitude)
		else:
			print("Max altitude callback not valid")
	previous_altitude = current_altitude

	if fuel <= 0:
		rocket_engine.throttle = 0.0
		return
		
	var effective_throttle = calculate_throttle()
	handle_launch_phase()
	
	if launch_started:
		apply_thrust(effective_throttle, delta)
		apply_fin_stabilization(delta)
		update_fuel(effective_throttle, delta)
	else:
		rocket_engine.throttle = 0.0

func calculate_throttle() -> float:
	return throttle_curve.sample(fuel)

func start_launch(callback: Callable = Callable(), max_height_callback: Callable = Callable()) -> void:
	if not launch_complete:
		launch_started = true
		after_launch_callback = callback
		max_altitude_callback = max_height_callback
		rocket_engine.skip_to_launch()

func handle_launch_phase() -> void:
	if not launch_started or launch_complete:
		return
	
	if global_position.distance_to(initial_position) >= launch_stabilization_distance:
		_complete_launch()

func _complete_launch() -> void:
	launch_complete = true
	# Unlock all axes after launch stabilization
	axis_lock_linear_x = false
	axis_lock_linear_z = false
	axis_lock_angular_x = false
	axis_lock_angular_y = false
	axis_lock_angular_z = false
	angular_velocity = Vector3.ZERO
	launch_completed.emit()
	if after_launch_callback.is_valid():
		after_launch_callback.call()

func apply_thrust(throttle: float, delta: float) -> void:
	var random_factor = 1.0 + (rng.randf_range(-thrust_randomness, thrust_randomness))
	var thrust_force = (max_force * throttle * random_factor) * global_transform.basis.y
	apply_force(thrust_force * delta, rocket_engine.global_transform.origin)
	rocket_engine.throttle = throttle

func apply_fin_stabilization(delta: float) -> void:
	var velocity = linear_velocity
	
	# Calculate air resistance
	current_air_resistance = 0.5 * air_density * velocity.length_squared() * fin_area
		
	# Apply angular damping to prevent oscillations
	angular_velocity *= angular_damping
		
	# Calculate angle of attack (angle between velocity and rocket's up vector)
	var normalized_velocity = velocity.normalized()
	var rocket_up = global_transform.basis.y
	var angle_of_attack = acos(clamp(normalized_velocity.dot(rocket_up), -1.0, 1.0))
	
	# Calculate crossproduct to determine rotation direction
	var cross_product = normalized_velocity.cross(rocket_up)
	
	# Calculate fin force with smoother response curve
	var velocity_squared = velocity.length_squared()
	var fin_force = 0.5 * air_density * velocity_squared * fin_area * fin_lift_coefficient * sin(angle_of_attack)
	
	# Apply corrective torque with limits
	var torque_direction = -cross_product.normalized()
	var raw_torque = torque_direction * fin_force * fin_distance_from_cg
	var clamped_torque = raw_torque.limit_length(max_stabilization_torque)
	apply_torque(clamped_torque * delta)

func update_fuel(throttle: float, delta: float) -> void:
	fuel = max(0, fuel - (fuel_consumption_rate * throttle * delta))

func get_speed() -> float:
	return linear_velocity.length()

func get_air_resistance() -> float:
	return current_air_resistance

func get_acceleration() -> float:
	return current_acceleration.length()

func get_altitude() -> float:
	return global_position.y

func get_angle_of_attack() -> float:
	var velocity = linear_velocity
	if velocity.length() < 0.1:
		return 0.0
	var normalized_velocity = velocity.normalized()
	var rocket_up = global_transform.basis.y
	return rad_to_deg(acos(clamp(normalized_velocity.dot(rocket_up), -1.0, 1.0)))

func get_angular_velocity_total() -> float:
	return angular_velocity.length()
