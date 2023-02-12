extends CharacterBody2D

@export var dir := Vector2.UP
@export var speed := 400

func _physics_process(delta):
	velocity = dir * speed
	rotation = dir.angle_to(Vector2.UP) * -1
	move_and_slide()
