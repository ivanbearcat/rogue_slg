extends Node2D

const hero_property = {
	"soldier": {"move": 3, "init_vec": Vector2i(3, 3)},
	"archer": {"move": 2, "init_vec": Vector2i(3, 2)},
	"mage": {"move": 2, "init_vec": Vector2i(2, 2)}
	}

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var grids: Node2D = $grids
@onready var heros: Node2D = $heros
const GRID = preload("res://scenes/grid.tscn")
const HERO = preload("res://scenes/hero.tscn")
var grid_size = Vector2i(16, 16)
var start_pos = Vector2i(16, 16)
const grid_offset = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
var all_grid_dict: Dictionary

func _ready() -> void:
	# 生成网格
	var removable_map_vec =  Vector2i(7, 7)
	for x in range(removable_map_vec.x):
		for y in range(removable_map_vec.y):
			var grid = GRID.instantiate()
			grid.grid_index = Vector2i(x, y)
			grid.position = Vector2i(x * grid_size.x + start_pos.x, y * grid_size.y + start_pos.y)
			all_grid_dict[Vector2i(x, y)] = grid
			grids.add_child(grid)
	# 生成英雄
	for hero_name in hero_property:
		var hero = HERO.instantiate()
		hero.hero_name = hero_name
		hero.hero_grid_index = hero_property[hero_name].init_vec
		hero.hero_move = hero_property[hero_name].move
		hero.position = Vector2i(hero_property[hero_name].init_vec.x * grid_size.x + start_pos.x, hero_property[hero_name].init_vec.y * grid_size.y + start_pos.y)
		Current.hero = hero
		Current.hero_grid_index_dict[hero.hero_grid_index] = hero.name
		#var callable = Callable(self, "_on_hero_cmd")
		hero.connect("hero_cmd", _on_hero_cmd)
		heros.add_child(hero)
	

func _on_hero_cmd(cmd_name):
	call(cmd_name)

func show_move_range():
	Current.movable_array.append(Current.hero.hero_grid_index)
	var grid_index_array = [Current.hero.hero_grid_index]
	var next_iter_grid_index_array: Array
	# 根据移动力决定迭代次数
	for i in range(Current.hero.hero_move):
		# 从原点找四周可以移动的格子，四个格子作为下次迭代的原点继续迭代
		for grid_index in grid_index_array:
			for offset in grid_offset:
				var next_grid_index = grid_index + offset
				# 判断有英雄或者敌人占位
				if Current.hero_grid_index_dict.has(next_grid_index) or Current.enemy_grid_index_dict.has(next_grid_index):
					continue
				# 判断是否已经加入可移动数组
				if next_grid_index in Current.movable_array:
					continue
				# 可移动数组
				Current.movable_array.append(next_grid_index)
				# 下次迭代用的数组
				next_iter_grid_index_array.append(next_grid_index)
		grid_index_array = next_iter_grid_index_array
		next_iter_grid_index_array = []
	# 显示可移动范围
	for grid_index in all_grid_dict:
		if grid_index in Current.movable_array:
			all_grid_dict[grid_index].range.visible = true
	
	#print(Current.movable_array)

func hide_move_range():
	Current.movable_array = []
	for grid_index in all_grid_dict:
		all_grid_dict[grid_index].range.visible = false
	
