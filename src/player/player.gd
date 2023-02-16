extends CharacterBody2D

@export var speed := 200

@onready var input := $PlayerInput
@onready var hand := $Hand

func _process(delta):
	var dir = global_position.direction_to(get_global_mouse_position())
	hand.rotation = dir.angle_to(Vector2.UP) * -1

func _physics_process(delta):
	var motion = Vector2(
		input.get_action_strength("move_left") - input.get_action_strength("move_right"),
		input.get_action_strength("move_down") - input.get_action_strength("move_up")
	).normalized()

	velocity = motion * speed
	move_and_slide()


func _on_player_input_just_pressed(ev: InputEvent):
	if ev.is_action_pressed("fire"):
		hand.get_child(0).fire()
