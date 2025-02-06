extends Experiment

func _physics_process(delta: float) -> void:
	if enabled and Input.is_action_just_pressed("Interact"):
		var cardboard = $Cardboard
		if cardboard:
			cardboard.apply_central_impulse(Vector3.RIGHT)
