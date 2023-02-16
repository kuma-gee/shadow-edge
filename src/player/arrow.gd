extends CharacterBody2D

@export var dir := Vector2.UP
@export var speed := 1000
@export var deaccel := 1000

@onready var light_effect: Effect = $PointLight2D/Effect
@onready var free_timer: Timer = $FreeTimer
@onready var decrease_timer: Timer = $DecreaseTimer

var stopped = false

func _ready():
	velocity = dir.rotated(global_rotation) * speed

func _physics_process(delta):
	velocity = velocity.move_toward(Vector2.ZERO, deaccel * delta)
	move_and_slide()
	
	var collision = get_last_slide_collision()
	if collision and not stopped:
		velocity = Vector2.ZERO

func _process(delta):
	if velocity.length() == 0 and not stopped:
		decrease_timer.start()
		stopped = true

func _on_effect_finished():
	free_timer.start()


func _on_free_timer_timeout():
	queue_free()


func _on_decrease_timer_timeout():
	light_effect.end_value = 0.0
	light_effect.start()

