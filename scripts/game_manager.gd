extends Node2D

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var grids: Node2D = $grids
@onready var heros: Node2D = $heros
const GRID = preload("res://scenes/grid.tscn")
const HERO = preload("res://scenes/hero.tscn")
var grid_size = Vector2i(16, 16)
var start_pos = Vector2i(16, 16)

func _ready() -> void:
	# 生成网格
	var removable_map_vec =  Vector2i(7, 7)
	for x in range(removable_map_vec.x):
		for y in range(removable_map_vec.y):
			var grid = GRID.instantiate()
			grid.grid_index = Vector2i(x, y)
			print(Vector2i(x * grid_size.x + start_pos.x, y * grid_size.y + start_pos.y))
			grid.position = Vector2i(x * grid_size.x + start_pos.x, y * grid_size.y + start_pos.y)
			grids.add_child(grid)
	# 生成英雄
	var hero_init_vec = Vector2i(removable_map_vec.x / 2, removable_map_vec.y / 2)
	var hero = HERO.instantiate()
	hero.hero_type = "soldier"
	hero.grid_index = hero_init_vec
	hero.position = Vector2i(hero_init_vec.x * grid_size.x + start_pos.x, hero_init_vec.y * grid_size.y + start_pos.y)
	heros.add_child(hero)
	
	hero_init_vec = Vector2i(3, 2)
	hero = HERO.instantiate()
	hero.hero_type = "archer"
	hero.grid_index = hero_init_vec
	hero.position = Vector2i(hero_init_vec.x * grid_size.x + start_pos.x, hero_init_vec.y * grid_size.y + start_pos.y)
	heros.add_child(hero)
	
	hero_init_vec = Vector2i(2, 2)
	hero = HERO.instantiate()
	hero.hero_type = "mage"
	hero.grid_index = hero_init_vec
	hero.position = Vector2i(hero_init_vec.x * grid_size.x + start_pos.x, hero_init_vec.y * grid_size.y + start_pos.y)
	heros.add_child(hero)

func _process(delta: float) -> void:
	pass
