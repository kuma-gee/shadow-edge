extends Node2D

const PLAYER = preload("res://src/player/player.tscn")

@onready var dungeon := $MSTDungeon

func _on_mst_dungeon_genereated():
	var player = PLAYER.instantiate()
	add_child(player)
	player.global_position = dungeon.get_player_spawn()
	
	var x = load("res://src/enemy/enemy.tscn").instantiate()
	add_child(x)
	x.global_position = player.global_position
