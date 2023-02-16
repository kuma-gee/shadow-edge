extends Node2D

@export var arrow_scene: PackedScene

@onready var firerate_timer: Timer = $FireRate

var can_fire = true

func fire():
	if not can_fire: return
	
	var arrow = arrow_scene.instantiate()
	arrow.global_rotation = global_rotation
	arrow.global_position = global_position
	get_tree().current_scene.add_child(arrow)
	can_fire = false
	firerate_timer.start()


func _on_fire_rate_timeout():
	can_fire = true
