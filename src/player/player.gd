extends CharacterBody2D

enum {
	WALK,
	ROLL,
}

@export var speed := 200

@export var roll_deaccel := 800
@export var roll_speed := 500

@onready var input := $PlayerInput
@onready var hand := $Hand
@onready var sprite := $Sprite2D

var _state = WALK

func _aim_dir() -> Vector2:
	return global_position.direction_to(get_global_mouse_position())

func _process(delta):
	var dir = _aim_dir()
	hand.rotation = dir.angle_to(Vector2.UP) * -1

func _physics_process(delta):
	match _state:
		ROLL:
			_roll_state(delta)
		WALK:
			_walk_state(delta)
	
	move_and_slide()

func _motion_dir():
	return Vector2(
		input.get_action_strength("move_left") - input.get_action_strength("move_right"),
		input.get_action_strength("move_down") - input.get_action_strength("move_up")
	).normalized()

func _walk_state(delta: float):
	var motion = _motion_dir()
	velocity = motion * speed
	
	var anim = "run" if velocity.length() > 0 else "default"
	sprite.play(anim)
	
	var aim = _aim_dir()
	sprite.flip_h = sign(aim.x) == -1

func _roll_state(delta: float):
	velocity = velocity.move_toward(Vector2.ZERO, roll_deaccel * delta)
	if velocity.length() < 0.1:
		_state = WALK

func _on_player_input_just_pressed(ev: InputEvent):
	if ev.is_action_pressed("fire"):
		hand.get_child(0).fire()
	elif ev.is_action_pressed("roll"):
		var motion = _motion_dir()
		if motion.length() > 0:
			velocity = motion * roll_speed
			_state = ROLL
