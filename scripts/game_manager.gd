extends Node2D

const hero_property = {
	"soldier": {"name": "soldier", "move": 3, "init_vec": Vector2i(3, 3)},
	"archer": {"name": "archer", "move": 2, "init_vec": Vector2i(3, 2)},
	"mage": {"name": "mage", "move": 2, "init_vec": Vector2i(2, 2)}
	}

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var grids: Node2D = $grids
@onready var heros: Node2D = $heros
@onready var buildings: Node2D = $buildings
@onready var enemys: Node2D = $enemys
@onready var turn_button: Button = $turn_button

var grid_size = Vector2i(16, 16)
var start_pos = Vector2i(16, 16)
const grid_offset = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
var all_grid_dict: Dictionary
var astar: AStarGrid2D
var removable_map_vec =  Vector2i(7, 7)
var slime_create_array: Array
var grow_up_slime_array: Array


func _ready() -> void:	
	# 生成网格
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
	# 生成英雄的家
	var hero_home_instantiate = SceneManager.create_scene("hero_home")
	hero_home_instantiate.position = _grid_index_to_position(removable_map_vec / 2)
	buildings.add_child(hero_home_instantiate)
	# 随机生成敌人的家
	var margin_grid: Array[Vector2i]
	# 计算所有地图边缘地块
	for x in range(removable_map_vec.x):
		for y in range(removable_map_vec.y):
			if x == 0 or x == range(removable_map_vec.x).max() or y == 0 or y == range(removable_map_vec.y).max():
				margin_grid.append(Vector2i(x, y))
	# 从边缘地块随机3块生成巢穴
	while true:
		if Current.enemy_home_array.size() >= 5: 
			break
		var grid_index = margin_grid.pick_random()
		if Current.enemy_home_array == [] or not Current.enemy_home_grid_index_array.has(grid_index):
			var enemy_home_instantiate = SceneManager.create_scene("enemy_home")
			enemy_home_instantiate.position = _grid_index_to_position(grid_index)
			enemy_home_instantiate.enemy_home_grid_index = grid_index
			Current.enemy_home_array.append(enemy_home_instantiate)	
			buildings.add_child(enemy_home_instantiate)
	# 预生成史莱姆和警告信息
	_slime_create_ai()


func _process(delta: float) -> void:
	pass
			
	

func _grid_index_to_position(grid_index: Vector2i) -> Vector2i:
	return Vector2i(grid_index.x * grid_size.x + start_pos.x, grid_index.y * grid_size.y + start_pos.y)

func _position_to_grid_index(position: Vector2i) -> Vector2i:
	return Vector2i((position.x - start_pos.x) / grid_size.x, (position.y - start_pos.y) / grid_size.y)

# 史莱姆生成
func _slime_create_ai():
	while true:
		# 限制史莱姆创建数量，限制无史莱姆占位的巢穴
		if slime_create_array.size() >= 3 or Current.available_enemy_home.size() <= 2: 
			break
		# 生成史莱姆的巢穴判断重复
		var is_unique := true
		var enemy_home = Current.available_enemy_home.pick_random()
		for slime in slime_create_array:
			if slime.enemy_grid_index == enemy_home.enemy_home_grid_index:
				is_unique = false
		if is_unique == false:
			continue
		# 根据选择的巢穴生成史莱姆
		var enemy_instantiate = SceneManager.create_scene("slime_small")
		enemy_instantiate.position = _grid_index_to_position(enemy_home.enemy_home_grid_index)
		enemy_instantiate.enemy_grid_index = enemy_home.enemy_home_grid_index
		slime_create_array.append(enemy_instantiate)
		enemy_home.warning.visible = true
	if Current.all_enemy_array.size() > 0:
		if grow_up_slime_array.size() < 1:
			grow_up_slime_array.append(Current.all_enemy_array.pick_random())
			for slime in grow_up_slime_array:
				slime.warning.visible = true
		
# 史莱姆移动
func _slime_move_ai():
	for enemy in Current.all_enemy_array:
		var movable_grid_array: Array
		for offset in grid_offset:
			var next_grid_index = enemy.enemy_grid_index + offset
			# 判断是否有英雄、史莱姆、巢穴占位者超出边界
			if Current.all_hero_grid_index_array.has(next_grid_index) or \
			Current.enemy_grid_index_array.has(next_grid_index) or \
			Current.enemy_home_grid_index_array.has(next_grid_index) or \
			next_grid_index.x < 0 or \
			next_grid_index.x > removable_map_vec.x - 1 or \
			next_grid_index.y < 0 or \
			next_grid_index.y > removable_map_vec.y - 1:
				continue
			movable_grid_array.append(next_grid_index)
		# 从可移动数组中随机一个移动
		if movable_grid_array.size() > 0:
			var target_grid = movable_grid_array.pick_random()
			var target_position: Vector2 = _grid_index_to_position(target_grid)
			enemy.target_position = target_position
			enemy.enemy_grid_index = target_grid

# 史莱姆成长
func _slime_grow_up_ai():
	var slime_type
	#var slime_target_position
	if grow_up_slime_array.size() > 0:
		for slime in grow_up_slime_array:
			var slime_grid_index = slime.enemy_grid_index
			if slime.enemy_type == 1:
				slime_type = "slime_middle"
				slime.queue_free()
				await get_tree().create_timer(0.1).timeout
			elif slime.enemy_type == 2:
				slime_type = "slime_big"
				slime.queue_free()
				await get_tree().create_timer(0.1).timeout
			elif slime.enemy_type == 3:
				tile_map_layer.set_cell(slime_grid_index + start_pos, 0, Vector2i(17,1), 0)
			if slime_type != null:
				var slime_instantiate = SceneManager.create_scene(slime_type)
				slime_instantiate.position = _grid_index_to_position(slime_grid_index)
				slime_instantiate.enemy_grid_index = slime_grid_index
				enemys.add_child(slime_instantiate)
			
			
# 设置英雄信息
func set_hero_properties(hero: Hero, properties: Dictionary):
	hero.hero_name = properties.name
	hero.hero_grid_index = properties.init_vec
	hero.hero_move = properties.move
	hero.position = _grid_index_to_position(properties.init_vec)
	Current.all_hero_dict[hero.hero_name] = hero
	hero.hero_cmd.connect(_on_hero_cmd)

# 可变参数信号
func _on_hero_cmd(cmd_name):
	call(cmd_name)

# 显示英雄移动网格
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
				if Current.all_hero_grid_index_array.has(next_grid_index) or \
				Current.enemy_grid_index_array.has(next_grid_index) or \
				Current.enemy_home_grid_index_array.has(next_grid_index):
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
	
# 隐藏英雄移动网格
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


func _on_button_pressed() -> void:
	Current.turn = "enemy_turn"
	turn_button.visible = false
	# 生成并移动史莱姆
	for enemy_home in Current.enemy_home_array:
		enemy_home.warning.visible = false
	for enemy in slime_create_array:
		enemys.add_child(enemy)
	_slime_move_ai()
	while Current.has_move_slime:
		await get_tree().create_timer(0.1).timeout
	slime_create_array.clear()
	# 史莱姆成长
	_slime_grow_up_ai()
	for slime in grow_up_slime_array:
		slime.warning.visible = false
	grow_up_slime_array.clear()
	await get_tree().create_timer(0.1).timeout
	# 史莱姆预生成和告警信息
	_slime_create_ai()
	Current.turn = "hero_turn"
	turn_button.visible = true
