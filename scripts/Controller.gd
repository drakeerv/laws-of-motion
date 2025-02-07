extends Node

@export var camera_manager: CameraManager
@export var rocket: Rocket
@export var ui: UI

enum State {
	FIRSTLAW,
	PRELAUNCH,
	LAUNCHING,
	SECONDLAW,
	INFLIGHT,
	THIRDLAW,
	LANDING
}

var state: State

func _ready():
	change_state(State.FIRSTLAW)

func _input(event: InputEvent) -> void:
	match state:
		State.FIRSTLAW:
			if event.is_action_pressed("Interact"):
				change_state(State.PRELAUNCH)
		State.PRELAUNCH:
			if event.is_action_pressed("Interact"):
				change_state(State.LAUNCHING)
		State.SECONDLAW:
			if event.is_action_pressed("Interact"):
				change_state(State.INFLIGHT)
		State.THIRDLAW:
			if event.is_action_pressed("Interact"):
				change_state(State.LANDING)

func change_state(new_state: State):
	state = new_state

	match state:
		State.FIRSTLAW:
			ui.set_description("[b]Newton’s First Law (Inertia):[/b] An object at rest stays at rest, and an object in motion stays in motion unless acted upon by an external force. The rocket will not move until we apply force through its engines.")
		State.PRELAUNCH:
			ui.set_description("[b]Pre-Launch:[/b] The rocket is stationary, held in place by gravity. Press Space to ignite the engines and apply force, setting the rocket in motion.")
			camera_manager.next_mount()
		State.LAUNCHING:
			rocket.start_launch(
				func(): 
					Engine.time_scale = 0.1
					change_state(State.SECONDLAW),
				func(_height): 
					Engine.time_scale = 1.0
					change_state(State.THIRDLAW)
			)
			ui.set_description("[b]Lift-Off![/b] The engines generate thrust, overcoming inertia and launching the rocket. Objects in motion stay in motion unless acted upon. Press Space to continue.")
		State.SECONDLAW:
			Engine.time_scale = 0.1
			camera_manager.next_mount()
			ui.set_description("[b]Newton’s Second Law (F = ma):[/b] The rocket’s acceleration depends on the force of thrust and its mass. As fuel burns, the rocket becomes lighter, increasing acceleration.")
		State.INFLIGHT:
			Engine.time_scale = 1.0
			camera_manager.next_mount()
			ui.set_description("[b]In Motion:[/b] The rocket continues accelerating as long as thrust is applied. Once fuel runs out, gravity will slow it down. Wait for it to reach maximum altitude.")
		State.THIRDLAW:
			Engine.time_scale = 0.1
			camera_manager.next_mount()
			ui.set_description("[b]Newton’s Third Law (Action-Reaction):[/b] The rocket expels exhaust gases downward (action), and in response, it is propelled upward (reaction). This principle governs all rocket propulsion.")
		State.LANDING:
			Engine.time_scale = 1.0
			ui.set_description("[b]Descent:[/b] With no more thrust, gravity pulls the rocket back down. The principles of motion apply in both ascent and descent, demonstrating Newton’s Laws in full.")
