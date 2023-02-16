extends Node2D

@export var arrow_scene: PackedScene

@onready var firerate_timer: Timer = $FireRate
@onready var arrow_sprite: Sprite2D = $Arrow

var can_fire = true

func fire():
	if not can_fire: return
	
	var arrow = arrow_scene.instantiate()
	arrow.global_rotation = global_rotation
	arrow.global_position = global_position
	get_tree().current_scene.add_child(arrow)
	can_fire = false
	arrow_sprite.hide()
	firerate_timer.start()


func _on_fire_rate_timeout():
	can_fire = true
	arrow_sprite.show()
