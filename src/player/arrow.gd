extends CharacterBody2D

@export var dir := Vector2.UP
@export var speed := 1000
@export var deaccel := 1000

@onready var light_effect: Effect = $PointLight2D/Effect
@onready var free_timer: Timer = $FreeTimer

var stopped = false

func _ready():
	velocity = dir * speed
	rotation = dir.angle_to(Vector2.UP) * -1

func _physics_process(delta):
	velocity = velocity.move_toward(Vector2.ZERO, deaccel * delta)
	move_and_slide()
	
	var collision = get_last_slide_collision()
	if collision and not stopped:
		velocity = Vector2.ZERO

func _process(delta):
	if velocity.length() == 0 and not stopped:
		light_effect.end_value = 0.0
		light_effect.start()
		stopped = true

func _on_effect_finished():
	free_timer.start()


func _on_free_timer_timeout():
	queue_free()
