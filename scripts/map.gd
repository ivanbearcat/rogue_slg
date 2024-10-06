extends Node2D

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var grids: Node2D = $grids
const GRID = preload("res://scenes/grid.tscn")
var grid_size = Vector2i(16, 16)
var start_pos = Vector2i(16, 16)

func _ready() -> void:
	var removable_map_vec =  Vector2i(7, 7)
	for x in range(removable_map_vec.x):
		for y in range(removable_map_vec.y):
			var grid = GRID.instantiate()
			grid.grid_index = Vector2i(x, y)
			print(Vector2i(x * grid_size.x + start_pos.x, y * grid_size.y + start_pos.y))
			grid.position = Vector2i(x * grid_size.x + start_pos.x, y * grid_size.y + start_pos.y)
			grids.add_child(grid)

func _process(delta: float) -> void:
	pass
