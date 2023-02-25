extends Node2D

const PLAYER = preload("res://src/player/player.tscn")

@onready var dungeon := $MSTDungeon

func _on_mst_dungeon_genereated():
	print("Finished")
