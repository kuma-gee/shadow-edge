extends Node2D

@export var arrow_scene: PackedScene

func fire():
	var arrow = arrow_scene.instantiate()
	arrow.global_rotation = global_rotation
	arrow.global_position = global_position
	get_tree().current_scene.add_child(arrow)
