extends Control
class_name UI

@export var rocket: Rocket

func _process(_delta: float) -> void:
	$Layout/TopBar.value = rocket.fuel * 100
	
	$Layout/Split/LeftPanel/Info.text = """[b]Flight Data:[/b]
Speed: %.1f m/s
Acceleration: %.1f m/s²
Altitude: %.1f m
Angle of Attack: %.1f°
Angular Velocity: %.2f rad/s
Air Resistance: %.2f N""" % [
		rocket.get_speed(),
		rocket.get_acceleration(),
		rocket.get_altitude(),
		rocket.get_angle_of_attack(),
		rocket.get_angular_velocity_total(),
		rocket.get_air_resistance()
	]
	
	$Layout/Split/RightPanel/Info.text = """[b]Engine Status:[/b]
Thrust: %.1f%%
Fuel: %.1f%%
Force: %.1f N""" % [
		rocket.throttle_curve.sample(rocket.fuel) * 100,
		rocket.fuel * 100,
		rocket.max_force * rocket.throttle_curve.sample(rocket.fuel)
	]

func set_description(text: String) -> void:
	$Layout/Split/LeftPanel/Description.text = "[i]%s[/i]" % text
