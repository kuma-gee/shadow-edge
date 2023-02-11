class_name LegacyTileMap
extends TileMap

func map_to_world(map_pos) -> Vector2:
	return map_to_local(Vector2i(map_pos)) - Vector2(tile_set.tile_size) / 2
	
func world_to_map(pos: Vector2) -> Vector2:
	return local_to_map(pos)
