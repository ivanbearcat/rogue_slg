extends Node2D

const hero_property = {
	"soldier": {"name": "soldier", "move": 3, "init_vec": Vector2i(3, 3)},
	"archer": {"name": "archer", "move": 2, "init_vec": Vector2i(3, 2)},
	"mage": {"name": "mage", "move": 2, "init_vec": Vector2i(2, 2)}
	}

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var grids: Node2D = $grids
@onready var heros: Node2D = $heros

var grid_size = Vector2i(16, 16)
var start_pos = Vector2i(16, 16)
const grid_offset = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
var all_grid_dict: Dictionary
var astar: AStarGrid2D

func _ready() -> void:
	# 生成网格
	var removable_map_vec =  Vector2i(7, 7)
	for x in range(removable_map_vec.x):
		for y in range(removable_map_vec.y):
			var grid = SceneManager.create_scene("grid")
			grid.grid_index = Vector2i(x, y)
			grid.position = Vector2i(x * grid_size.x + start_pos.x, y * grid_size.y + start_pos.y)
			all_grid_dict[Vector2i(x, y)] = grid
			grids.add_child(grid)
	# 生成英雄
	for hero_name in hero_property:
		var hero_instantiate = SceneManager.create_scene("hero")
		set_hero_properties(hero_instantiate, hero_property[hero_name])
		heros.add_child(hero_instantiate)
	# 配置Astar寻路
	astar = AStarGrid2D.new()
	astar.region = tile_map_layer.get_used_rect()
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
# 设置英雄信息
func set_hero_properties(hero: Hero, properties: Dictionary):
	hero.hero_name = properties.name
	hero.hero_grid_index = properties.init_vec
	hero.hero_move = properties.move
	hero.position = Vector2i(properties.init_vec.x * grid_size.x + start_pos.x, properties.init_vec.y * grid_size.y + start_pos.y)
	#Current.hero = hero
	Current.all_hero_dict[hero.hero_name] = hero
	hero.hero_cmd.connect(_on_hero_cmd)

# 可变参数信号
func _on_hero_cmd(cmd_name):
	call(cmd_name)

# 显示移动网格
func show_move_range():
	var hero = Current.hero
	Current.movable_grid_index_array.append(hero.hero_grid_index)
	var grid_index_array = [hero.hero_grid_index]
	var next_iter_grid_index_array: Array
	# 根据移动力决定迭代次数
	for i in range(hero.hero_move):
		# 从原点找四周可以移动的格子，四个格子作为下次迭代的原点继续迭代
		for grid_index in grid_index_array:
			for offset in grid_offset:
				var next_grid_index = grid_index + offset
				# 判断有英雄或者敌人占位
				if Current.all_hero_grid_index_array.has(next_grid_index) or Current.enemy_grid_index_array.has(next_grid_index):
					continue
				# 判断是否已经加入可移动数组
				if next_grid_index in Current.movable_grid_index_array:
					continue
				# 可移动数组
				Current.movable_grid_index_array.append(next_grid_index)
				# 下次迭代用的数组
				next_iter_grid_index_array.append(next_grid_index)
		grid_index_array = next_iter_grid_index_array
		next_iter_grid_index_array = []
	# 显示可移动范围
	for grid_index in all_grid_dict:
		if grid_index in Current.movable_grid_index_array:
			all_grid_dict[grid_index].range.visible = true
	
	#print(Current.movable_array)

# 隐藏移动网格
func hide_move_range():
	Current.movable_grid_index_array = []
	for grid_index in all_grid_dict:
		all_grid_dict[grid_index].range.visible = false

# 英雄移动路径	
func hero_move():
	if Current.id_path.size() > 0:
		return
	var hero = Current.clicked_hero
	var target_grid_index = Current.grid_index
	# 判断目标位置不在移动围内或有其他棋子，则不能移动
	if not Current.movable_grid_index_array.has(target_grid_index) \
	or Current.all_hero_grid_index_array.has(target_grid_index) \
	or Current.enemy_grid_index_array.has(target_grid_index):
		return
	Current.id_path = astar.get_id_path(hero.hero_grid_index, target_grid_index)
	print(Current.id_path)
	
