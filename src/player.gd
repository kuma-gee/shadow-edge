extends CharacterBody2D

@export var speed := 300

@onready var input := $PlayerInput

func _physics_process(delta):
	var motion = Vector2(
		input.get_action_strength("move_left") - input.get_action_strength("move_right"),
		input.get_action_strength("move_down") - input.get_action_strength("move_up")
	).normalized()

	velocity = motion * speed
	move_and_slide()
