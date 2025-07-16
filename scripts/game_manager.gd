extends Node2D

const hero_property = {
	"soldier": {"name": "soldier", "movement": 3, "init_vec": Vector2i(3, 3)},
	"archer": {"name": "archer", "movement": 2, "init_vec": Vector2i(3, 2)},
	"mage": {"name": "mage", "movement": 2, "init_vec": Vector2i(2, 2)}
	}

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var grids: Node2D = $grids
@onready var heros: Node2D = $heros
@onready var buildings: Node2D = $buildings
@onready var enemys: Node2D = $enemys
@onready var turn_button: Button = %turn_button
@onready var reroll_label: Label = %reroll_label
@onready var turn_label: Label = %turn_label
#@onready var left_side_ui: MarginContainer = $UI/left_side_ui
@onready var hero_skill: Control = $hero_skill
@onready var skill_system: Node2D = $skill_system
@onready var skill_1_ui: MarginContainer
@onready var total_score: Label = %total_score
## 骰型板
@onready var one_score: Label = %one_score
@onready var two_score: Label = %two_score
@onready var three_score: Label = %three_score
@onready var four_score: Label = %four_score
@onready var five_score: Label = %five_score
@onready var six_score: Label = %six_score
@onready var none_percent: Label = %none_percent
@onready var duizi_percent: Label = %duizi_percent
@onready var shunzi_percent: Label = %shunzi_percent
@onready var tongse_percent: Label = %tongse_percent
@onready var tongdui_percent: Label = %tongdui_percent
@onready var tongshun_percent: Label = %tongshun_percent
@onready var base_score: Label = %base_score
@onready var percent_score: Label = %percent_score
## 骰型板框线
@onready var one_score_frame: PanelContainer = %one_score_frame
@onready var two_score_frame: PanelContainer = %two_score_frame
@onready var three_score_frame: PanelContainer = %three_score_frame
@onready var four_score_frame: PanelContainer = %four_score_frame
@onready var five_score_frame: PanelContainer = %five_score_frame
@onready var six_score_frame: PanelContainer = %six_score_frame
@onready var none_percent_frame: PanelContainer = %none_percent_frame
@onready var duizi_percent_frame: PanelContainer = %duizi_percent_frame
@onready var shunzi_percent_frame: PanelContainer = %shunzi_percent_frame
@onready var tongse_percent_frame: PanelContainer = %tongse_percent_frame
@onready var tongdui_percent_frame: PanelContainer = %tongdui_percent_frame
@onready var tongshun_percent_frame: PanelContainer = %tongshun_percent_frame
## 骰子UI父级
@onready var dice_list: HBoxContainer = %dice_list
## 经验条
@onready var exp_bar: TextureProgressBar = %exp_bar
## 经验条刻度池
@onready var exp_bar_scale_pool: HBoxContainer = %exp_bar_scale_pool
@onready var exp_label: Label = %exp_label

## 格子像素大小
var grid_size = Vector2i(16, 16)
## 起始格子位置
var start_pos = Vector2i(16, 16)
## 格子位置上下左右偏移
const grid_offset = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
## 所有格子字典
var all_grid_dict: Dictionary
## astar寻路
var astar: AStarGrid2D
## 最大可移动的地图块
var _removable_map_vec =  Vector2i(7, 7)
## 史莱姆创建列表
var _slime_create_array: Array
## 回合计数
var count_round := 0
## 带有骰子点数的动画图片索引
var dice_point: Array = [0, 2, 4, 6, 8, 10]
## 史莱姆场景列表
var slime_scene_array := ['slime_small', 'slime_small_red', 'slime_small_yellow', 'slime_small_blue']
## 边缘格子列表
var _margin_grid: Array[Vector2i]
## 颜色
var color := {
	"alpha0": "cc080800",
	"red": "cc0808"
}


func _ready() -> void:
	## 测试
	#for i in range(20):
		#await _add_exp(1)

	
	## 设置基础倍率
	Current.none_percent = 100
	Current.duizi_percent = 150
	Current.shunzi_percent = 160
	Current.tongse_percent = 140
	Current.tongdui_percent = 300
	Current.tongshun_percent = 320
	## 生成网格
	for x in range(_removable_map_vec.x):
		for y in range(_removable_map_vec.y):
			var grid = SceneManager.create_scene("grid")
			grid.grid_index = Vector2i(x, y)
			grid.position = Vector2i(x * grid_size.x + start_pos.x, y * grid_size.y + start_pos.y)
			all_grid_dict[Vector2i(x, y)] = grid
			grids.add_child(grid)
			grid.grid_cmd.connect(_on_grid_cmd)
	## 生成英雄
	var hero_instantiate = SceneManager.create_scene("hero")
	_set_hero_properties(hero_instantiate, hero_property["soldier"])
	heros.add_child(hero_instantiate)
	_set_hero_skill_scripts(hero_instantiate)
	## 配置Astar寻路
	astar = AStarGrid2D.new()
	astar.region = tile_map_layer.get_used_rect()
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	## 计算所有地图边缘地块
	for x in range(_removable_map_vec.x):
		for y in range(_removable_map_vec.y):
			if x == 0 or x == range(_removable_map_vec.x).max() or y == 0 or y == range(_removable_map_vec.y).max():
				_margin_grid.append(Vector2i(x, y))
	## 预生成史莱姆和警告信息
	_create_slime()
	_create_power_slime()
	_enemy_turn()

func _grid_index_to_position(grid_index: Vector2i) -> Vector2i:
	return Vector2i(grid_index.x * grid_size.x + start_pos.x, grid_index.y * grid_size.y + start_pos.y)

func _position_to_grid_index(position: Vector2i) -> Vector2i:
	return Vector2i((position.x - start_pos.x) / grid_size.x, (position.y - start_pos.y) / grid_size.y)

## 史莱姆生成
func _create_slime():
	## 边缘地块随机生成3个史莱姆
	var available_grid_array: Array[Vector2i]
	var create_slime_grid_index_array: Array[Vector2i]
	var slime_num: int
	for grid_index in _margin_grid:
		if ! grid_index in Current.all_enemy_grid_index_array:
			available_grid_array.append(grid_index)
	if available_grid_array.size() > 0:
		slime_num = clamp(available_grid_array.size(), 1, 3)
		while create_slime_grid_index_array.size() < slime_num:
			var grid_index = available_grid_array.pick_random()
			if ! grid_index in create_slime_grid_index_array:
				create_slime_grid_index_array.append(grid_index)
		for grid_index in create_slime_grid_index_array:
			var slime_sence = slime_scene_array.pick_random()
			var enemy_instantiate = SceneManager.create_scene(slime_sence)
			enemy_instantiate.position = _grid_index_to_position(grid_index)
			enemy_instantiate.enemy_grid_index = grid_index
			_slime_create_array.append(enemy_instantiate)
			var grids_array = grids.get_children()
			for grid in grids_array:
				if grid.grid_index == grid_index:
					grid.warning.visible = true
## 添加能量史莱姆
func _create_power_slime():
	#if Current.all_enemy_array.size() > 0:
		#if Current.transformable_slime_array.size() < 1:
			#Current.transformable_slime_array.append(Current.all_enemy_array.pick_random())
			#for slime in Current.transformable_slime_array:
				#slime.warning.visible = true
				#print(slime)
	if Current.power_slime == null:
		Current.power_slime = Current.all_enemy_array.pick_random()
		if Current.power_slime is Slime:
			Current.power_slime.animated_sprite_2d.material.set_shader_parameter("is_high_light", true)

		
## 史莱姆移动
func _slime_move_ai():
	for enemy in Current.all_enemy_array:
		var movable_grid_array: Array
		for offset in grid_offset:
			var next_grid_index = enemy.enemy_grid_index + offset
			## 判断是否有英雄、史莱姆、巢穴占位者超出边界
			if Current.all_hero_grid_index_array.has(next_grid_index) or \
			Current.all_enemy_grid_index_array.has(next_grid_index) or \
			Current.enemy_home_grid_index_array.has(next_grid_index) or \
			next_grid_index.x < 0 or \
			next_grid_index.x > _removable_map_vec.x - 1 or \
			next_grid_index.y < 0 or \
			next_grid_index.y > _removable_map_vec.y - 1:
				continue
			movable_grid_array.append(next_grid_index)
		## 从可移动数组中随机一个移动
		if movable_grid_array.size() > 0:
			var target_grid = movable_grid_array.pick_random()
			var target_position: Vector2 = _grid_index_to_position(target_grid)
			enemy.target_position = target_position
			enemy.enemy_grid_index = target_grid


## 史莱姆重掷
func slime_reroll(slime: Node2D):
	var slime_grid_index = slime.enemy_grid_index
	## 获取史莱姆颜色
	#var regex = RegEx.new()
	#regex.compile(".*(?<name>slime.*)\\.tscn")
	#var result = regex.search(slime.scene_file_path)
	#var slime_color = Tools.fetch_slime_scene(slime)
	#if slime_color:
		#var copy_slime_scene_array = slime_scene_array.duplicate()
		#copy_slime_scene_array.pop_at(copy_slime_scene_array.find(slime_color))
	slime.queue_free()
	var slime_sence = slime_scene_array.pick_random()
	var slime_instantiate = SceneManager.create_scene(slime_sence)
	slime_instantiate.position = _grid_index_to_position(slime_grid_index)
	slime_instantiate.enemy_grid_index = slime_grid_index
	enemys.add_child(slime_instantiate)
	_roll_dice(slime_instantiate)	


##设置验条刻度
func _set_exp_bar_scale(num_now: int, num_max: int) -> void:
	exp_label.text = str(num_now) + '/' + str(num_max)


## 增加经验
func add_exp(new_exp: int) -> void:
	Current.exp += new_exp
	exp_bar.value = Current.exp
	_set_exp_bar_scale(Current.exp, Current.require_exp)
	## 等待1秒让一次攻击下的史莱姆经验全加上再升级
	await Tools.time_sleep(1)
	_check_level_up()


## 检查并升级
func _check_level_up() -> void:
	if Current.exp >= Current.require_exp:
		Current.level += 1
		if Current.require_exp < 7:
			Current.require_exp += 1
		Current.exp = 0
		exp_bar.value = 0
		exp_bar.max_value = Current.require_exp
		_set_exp_bar_scale(Current.exp, Current.require_exp)
	


## 设置英雄信息
func _set_hero_properties(hero: Hero, properties: Dictionary):
	hero.hero_name = properties.name
	Current.hero = hero
	hero.hero_movement = properties.movement
	hero.position = _grid_index_to_position(properties.init_vec)
	#Current.all_hero_dict[hero.hero_name] = hero
	hero.hero_cmd.connect(_on_hero_cmd)
	var hero_skills_ui = SceneManager.create_scene(hero.hero_name + "_skills")
	hero_skill.add_child(hero_skills_ui)
	## onready后无法获取到代码新增的节点skill_1_ui，在此处添加了场景树之后可以获取，但无法使用唯一标识获取
	skill_1_ui = hero_skill.get_node("MarginContainer/HBoxContainer/skill_1")
	

## 设置3技能的状态脚本
func _set_hero_skill_scripts(hero: Hero):
	var script_path_1 = "res://scripts/skills_state/" + hero.hero_name + "_skill_1.gd"
	var script_path_2 = "res://scripts/skills_state/" + hero.hero_name + "_skill_2.gd"
	var script_path_3 = "res://scripts/skills_state/" + hero.hero_name + "_skill_3.gd"
	var script_1 = load(script_path_1)
	var script_2 = load(script_path_2)
	var script_3 = load(script_path_3)
	hero.skill_1.set_script(script_1)
	hero.skill_2.set_script(script_2)
	hero.skill_3.set_script(script_3)

## 可变参数信号
func _on_hero_cmd(cmd_name):
	call(cmd_name)
	
func _on_grid_cmd(cmd_name):
	call(cmd_name)

## 投骰子动画
func _roll_dice(slime_instantiate):
	slime_instantiate.dice.play("roll")
	await get_tree().create_timer(1.0).timeout
	slime_instantiate.dice.stop()
	slime_instantiate.dice.set_frame_and_progress(dice_point.pick_random(), 0)
	

## 显示英雄移动网格
func show_move_range():
	var hero = Current.hero
	Current.movable_grid_index_array.append(hero.hero_grid_index)
	var grid_index_array = [hero.hero_grid_index]
	var next_iter_grid_index_array: Array
	## 根据移动力决定迭代次数
	for i in range(hero.hero_movement):
		## 从原点找四周可以移动的格子，四个格子作为下次迭代的原点继续迭代
		for grid_index in grid_index_array:
			for offset in grid_offset:
				var next_grid_index = grid_index + offset
				## 判断有英雄或者敌人占位
				if Current.all_hero_grid_index_array.has(next_grid_index) or \
				Current.all_enemy_grid_index_array.has(next_grid_index) or \
				Current.enemy_home_grid_index_array.has(next_grid_index):
					continue
				## 判断是否已经加入可移动数组
				if next_grid_index in Current.movable_grid_index_array:
					continue
				## 可移动数组
				Current.movable_grid_index_array.append(next_grid_index)
				## 下次迭代用的数组
				next_iter_grid_index_array.append(next_grid_index)
		grid_index_array = next_iter_grid_index_array
		next_iter_grid_index_array = []
	## 显示可移动范围
	for grid_index in all_grid_dict:
		if grid_index in Current.movable_grid_index_array:
			all_grid_dict[grid_index].range.visible = true
	
## 隐藏英雄移动网格
func hide_move_range():
	Current.movable_grid_index_array = []
	for grid_index in all_grid_dict:
		all_grid_dict[grid_index].range.visible = false

## 英雄移动路径	
func hero_move():
	if Current.id_path.size() > 0:
		return
	var hero = Current.clicked_hero
	var target_grid_index = Current.grid_index
	## 判断目标位置不在移动围内或有其他棋子，则不能移动
	if not Current.movable_grid_index_array.has(target_grid_index) \
	or Current.all_hero_grid_index_array.has(target_grid_index) \
	or Current.all_enemy_grid_index_array.has(target_grid_index):
		return
	Current.id_path = astar.get_id_path(hero.hero_grid_index, target_grid_index)
	print(Current.id_path)

## 显示技能可点击范围
func show_skill_range():
	skill_system.show_skill_range(Current.clicked_hero.hero_name, Current.skill_num)

## 隐藏技能可点击范围
func hide_skill_range():
	skill_system.hide_skill_range()

## 显示技能伤害范围
func show_skill_attack():
	skill_system.show_skill_attack(Current.clicked_hero.hero_name, Current.skill_num)

## 隐藏技能伤害范围
func hide_skill_attack():
	skill_system.hide_skill_attack()

## 技能结算
func skill_attack():
	await skill_system.skill_attack()
	_enemy_turn()

## 重掷按钮按下
func _on_reroll_button_pressed() -> void:
	if Current.reroll_times > 0:
		CursorManager.change_cursor("reroll")
	else:
		## 无法重掷效果
		pass

## 跳过回合按钮按下
func _on_turn_button_pressed() -> void:
	_enemy_turn()
	
## 敌人回合
func _enemy_turn():
	Current.turn = "enemy_turn"
	turn_button.disabled = true
	## 生成并移动史莱姆
	var grids_array = grids.get_children()
	for grid in grids_array:
		grid.warning.visible = false
	for enemy in _slime_create_array:
		enemys.add_child(enemy)
		_roll_dice(enemy)
	_slime_move_ai()
	while Current.has_move_slime:
		await get_tree().create_timer(0.1).timeout
	_slime_create_array.clear()
	## 史莱姆重掷
	#_slime_grow_up_ai()
	#for slime in Current.transformable_slime_array:
		#slime.warning.visible = false
	#Current.transformable_slime_array.clear()
	#await get_tree().create_timer(0.1).timeout
	## 史莱姆预生成和告警信息
	_create_slime()
	_create_power_slime()
	Current.turn = "hero_turn"
	turn_button.disabled = false
	count_round += 1
	turn_label.text = "回合: " + str(count_round)
	## 重置英雄状态
	for hero in Current.all_hero_array:
		hero.hero_state_machine.transition_to("idle")
	## 重新计算不可移动地块
	for grid in grids.get_children():
		astar.set_point_solid(grid.grid_index, false)
	for grid_index in Current.all_enemy_grid_index_array:
		astar.set_point_solid(grid_index, true)
	## 重置已移动标记
	Current.is_moved = false
	## 测试
	#var a = dice_list.get_children()[0]
	#Tools.big_flow_effect(a)

## 鼠标移出可移动区域清除格子位置
func _on_area_2d_mouse_entered() -> void:
	Current.grid_index = Vector2.ZERO


func _on_skill_system_hide_all_skill() -> void:
	skill_1_ui.hide_all_skill()
