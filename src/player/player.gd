extends CharacterBody2D

@export var speed := 200
@export var arrow_scene: PackedScene

@onready var input := $PlayerInput



func _physics_process(delta):
	var motion = Vector2(
		input.get_action_strength("move_left") - input.get_action_strength("move_right"),
		input.get_action_strength("move_down") - input.get_action_strength("move_up")
	).normalized()

	velocity = motion * speed
	move_and_slide()


func _on_player_input_just_pressed(ev: InputEvent):
	if ev.is_action_pressed("fire"):
		var arrow = arrow_scene.instantiate()
		var dir = global_position.direction_to(get_global_mouse_position())
		arrow.dir = dir
		arrow.global_position = global_position
		get_tree().current_scene.add_child(arrow)
