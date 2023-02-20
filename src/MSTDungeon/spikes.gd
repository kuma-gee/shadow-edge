extends Area2D

@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D

@onready var start := $SpikeStart
@onready var end := $SpikeEnd

func _on_spike_end_timeout():
	sprite.play_backwards("default")
	start.start()


func _on_spike_start_timeout():
	sprite.play("default")
	end.start()


func _on_sprite_2d_frame_changed():
	collision.disabled = sprite.frame < 2
