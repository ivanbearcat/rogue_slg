extends Node2D

const hero_property = {
	"soldier": {"name": "soldier", "movement": 3, "init_vec": Vector2i(3, 3), "class_icon": "res://images/soldier_icon.png"},
	"archer": {"name": "archer", "movement": 2, "init_vec": Vector2i(3, 2)},
	"mage": {"name": "mage", "movement": 2, "init_vec": Vector2i(2, 2)}
	}

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var grids: Node2D = $grids
@onready var heros: Node2D = $heros
@onready var buildings: Node2D = $buildings
@onready var enemys: Node2D = $enemys
@onready var turn_button: TextureButton = %turn_button
#@onready var reroll_label: Label = %reroll_label
@onready var stage_label: Label = %stage_label
@onready var turn_label: Label = %turn_label
#@onready var left_side_ui: MarginContainer = $UI/left_side_ui
@onready var hero_skill: Control = $hero_skill
@onready var skill_system: Node2D = $skill_system
@onready var skill_1_ui: MarginContainer
@onready var target_score: Label = %target_score
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
## 金币总数
@onready var total_coins_label: Label = %total_coins_label
## 经验条
@onready var exp_label: Label = %exp_label
## 升级后卡牌择界面
@onready var level_up_ui: CanvasLayer = %level_up_ui
## 升级后卡牌UI
@onready var card_1: TextureRect = %card1
@onready var card_1_name: Label = %card1_name
@onready var card_1_description: RichTextLabel = %card1_description
@onready var card_2: TextureRect = %card2
@onready var card_2_name: Label = %card2_name
@onready var card_2_description: RichTextLabel = %card2_description
@onready var card_3: TextureRect = %card3
@onready var card_3_name: Label = %card3_name
@onready var card_3_description: RichTextLabel = %card3_description
## 过关界面
@onready var clear_stage_ui: CanvasLayer = $clear_stage_ui
@onready var clear_stage_label: Label = %clear_stage_label
@onready var coin_array_1: HBoxContainer = %coin_array1
@onready var coin_array_2: HBoxContainer = %coin_array2
## 帮助按钮
@onready var help_button: TextureButton = %help_button
## 职业图标
@onready var class_icon: TextureRect = %class_icon
## UI
@onready var power_label: Label = %power_label
@onready var level_label: Label = %level_label
@onready var ship: TextureRect = %ship
@onready var turn_button_label: Control = %turn_button_label
@onready var reroll_button_label: Control = %reroll_button_label
@onready var turn_coin_label: Label = %turn_coin_label
@onready var reroll_button: TextureButton = %reroll_button
@onready var coin_skill_1: TextureButton = %coin_skill_1
@onready var coin_skill_2: TextureButton = %coin_skill_2
@onready var coin_skill_3: TextureButton = %coin_skill_3
@onready var coin_skill_1_icon: TextureRect = %coin_skill_1_icon
@onready var coin_skill_2_icon: TextureRect = %coin_skill_2_icon
@onready var coin_skill_3_icon: TextureRect = %coin_skill_3_icon
@onready var coin_skill_1_label: RichTextLabel = %coin_skill_1_label
@onready var coin_skill_2_label: RichTextLabel = %coin_skill_2_label
@onready var coin_skill_3_label: RichTextLabel = %coin_skill_3_label
@onready var q_texture: TextureRect = %Q_texture
@onready var w_texture: TextureRect = %W_texture
@onready var e_texture: TextureRect = %E_texture


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
## 史莱姆创建数组
var _slime_create_array: Array
## 带有骰子点数的动画图片索引
var dice_point: Array = [0, 2, 4, 6, 8, 10]
## 史莱姆场景数组
var slime_scene_array := ['slime_small', 'slime_small_red', 'slime_small_yellow', 'slime_small_blue']
## 边缘格子数组
var _margin_grid: Array[Vector2i]
## 颜色
var color := {
	"alpha0": "cc080800",
	"red": "cc0808"
}
## 升级时的卡牌数据
var card_level_up_json_data :Array
## 关卡数据
var stage_info_json_data
## 金币能数据
var coin_skill_json_data
## 随机选择出的3张升级时卡牌
var level_up_three_card_array :Array




func _ready() -> void:
	## 测试
	ship.position += Vector2(7, 0) * 5
	## 加载json数据
	card_level_up_json_data = Tools.load_json_file('res://config/card_level_up.json')
	stage_info_json_data = Tools.load_json_file('res://config/stage_info.json')
	coin_skill_json_data = Tools.load_json_file('res://config/coin_skill.json')
	## 临时
	Current.coin_skill_array_dict = coin_skill_json_data.duplicate()
	coin_skill_1_label.text = "[img=12]res://images/coin.png[/img] -" + str(int(Current.coin_skill_array_dict[0]["coin_skill_cost"]))
	coin_skill_2_label.text = "[img=12]res://images/coin.png[/img] -" + str(int(Current.coin_skill_array_dict[1]["coin_skill_cost"]))
	coin_skill_3_label.text = "[img=12]res://images/coin.png[/img] -" + str(int(Current.coin_skill_array_dict[2]["coin_skill_cost"]))
	## 设置基础倍率
	Current.none_percent = 100
	Current.duizi_percent = 150
	Current.shunzi_percent = 160
	Current.tongse_percent = 140
	Current.tongdui_percent = 300
	Current.tongshun_percent = 320
	## 设置目标分数
	for row in stage_info_json_data:
		if row["stage_num"] == Current.count_stage:
			Current.target_score = row["target_score"]
	## 初始化金币
		Current.total_coins = 3
	## 生成网格
	for x in range(_removable_map_vec.x):
		for y in range(_removable_map_vec.y):
			var grid = SceneManager.create_scene("grid")
			grid.grid_index = Vector2i(x, y)
			grid.position = Vector2i(x * grid_size.x + start_pos.x, y * grid_size.y + start_pos.y)
			all_grid_dict[Vector2i(x, y)] = grid
			grids.add_child(grid)
			grid.grid_cmd.connect(_on_grid_cmd)
	Current.all_grids_array = grids.get_children()
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

func grid_index_to_position(grid_index: Vector2i) -> Vector2i:
	return Vector2i(grid_index.x * grid_size.x + start_pos.x, grid_index.y * grid_size.y + start_pos.y)

func position_to_grid_index(_position: Vector2i) -> Vector2i:
	return Vector2i((_position.x - start_pos.x) / grid_size.x, (_position.y - start_pos.y) / grid_size.y)

## 生成史莱姆
func _create_slime():
	var available_grid_array: Array[Vector2i]
	var create_slime_grid_index_array: Array[Vector2i]
	var slime_num: int
	## 计算可以生成史莱姆的空地块
	for grid_index in all_grid_dict.keys():
		if ! grid_index in Current.all_enemy_grid_index_array and grid_index != Current.hero.hero_grid_index:
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
			enemy_instantiate.position = grid_index_to_position(grid_index)
			enemy_instantiate.enemy_grid_index = grid_index
			_slime_create_array.append(enemy_instantiate)
			var grids_array = grids.get_children()
			for grid in grids_array:
				if grid.grid_index == grid_index:
					grid.warning.visible = true

## 边缘生成史莱姆
func _create_slime_on_margin_grid():
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
			enemy_instantiate.position = grid_index_to_position(grid_index)
			enemy_instantiate.enemy_grid_index = grid_index
			_slime_create_array.append(enemy_instantiate)
			var grids_array = grids.get_children()
			for grid in grids_array:
				if grid.grid_index == grid_index:
					grid.warning.visible = true

## 添加能量史莱姆
func _create_power_slime():
	if Current.power_slime == null and Current.all_enemy_array:
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
			next_grid_index.x < 0 or \
			next_grid_index.x > _removable_map_vec.x - 1 or \
			next_grid_index.y < 0 or \
			next_grid_index.y > _removable_map_vec.y - 1:
				continue
			movable_grid_array.append(next_grid_index)
		## 从可移动数组中随机一个移动
		if movable_grid_array.size() > 0:
			var target_grid = movable_grid_array.pick_random()
			var target_position: Vector2 = grid_index_to_position(target_grid)
			enemy.target_position = target_position
			enemy.enemy_grid_index = target_grid


## 史莱姆重掷
func slime_reroll(slime: Node2D, only_roll_dice=0, only_roll_color=0):
	var slime_grid_index = slime.enemy_grid_index
	## 获取史莱姆颜色
	#var regex = RegEx.new()
	#regex.compile(".*(?<name>slime.*)\\.tscn")
	#var result = regex.search(slime.scene_file_path)
	#var slime_color = Tools.fetch_slime_scene(slime)
	#if slime_color:
		#var copy_slime_scene_array = slime_scene_array.duplicate()
		#copy_slime_scene_array.pop_at(copy_slime_scene_array.find(slime_color))
	if only_roll_dice:
		_roll_dice(slime, 1, 0)
	elif only_roll_color:
		## 获取原始点数
		var old_frame = slime.dice.frame
		slime.queue_free()
		var slime_sence = slime_scene_array.pick_random()
		var slime_instantiate = SceneManager.create_scene(slime_sence)
		slime_instantiate.position = grid_index_to_position(slime_grid_index)
		slime_instantiate.enemy_grid_index = slime_grid_index
		enemys.add_child(slime_instantiate)
		## 设置点数
		slime_instantiate.dice.set_frame_and_progress(old_frame, 0)
		_roll_dice(slime_instantiate, 0, 1)
	else:
		slime.queue_free()
		var slime_sence = slime_scene_array.pick_random()
		var slime_instantiate = SceneManager.create_scene(slime_sence)
		slime_instantiate.position = grid_index_to_position(slime_grid_index)
		slime_instantiate.enemy_grid_index = slime_grid_index
		enemys.add_child(slime_instantiate)
		_roll_dice(slime_instantiate)


##设置验条刻度
func _set_exp_bar_scale(num_now: int, num_max: int) -> void:
	exp_label.text = str(num_now) + '/' + str(num_max)


## 增加经验
func add_exp(new_exp: int) -> void:
	Current.hero_exp += new_exp
	exp_bar.value = Current.hero_exp
	_set_exp_bar_scale(Current.hero_exp, Current.require_exp)
	## 等待1秒让一次攻击下的史莱姆经验全加上再升级
	await Tools.time_sleep(1)
	_check_and_level_up()


## 检查并升级
func _check_and_level_up() -> void:
	if Current.hero_exp >= Current.require_exp:
		Current.level += 1
		## 最多增加到7个史莱姆可以升级
		if Current.require_exp < 7:
			Current.require_exp += 1
		Current.hero_exp = 0
		exp_bar.value = 0
		## 设置经验条数值
		exp_bar.max_value = Current.require_exp
		## 设置经验label
		_set_exp_bar_scale(Current.hero_exp, Current.require_exp)
		## 生成3个随机卡牌
		var total_weight := 0
		## 计算总权重
		for row in card_level_up_json_data:
			if row['weight'] > 0:
				total_weight += row['weight']
		## 累加权重匹配随机项，获取3条不重复的随机项到组
		var tmp_weight := 0
		level_up_three_card_array = []
		while level_up_three_card_array.size() < 3:
			## 随机总权重
			var random_weight_num = randi_range(1, total_weight)
			for row in card_level_up_json_data:
				if row['weight'] > 0:
					tmp_weight += row['weight']
					if tmp_weight > random_weight_num:
						if row not in level_up_three_card_array:
							level_up_three_card_array.append(row)
							break
		## 根据随机结果将数据填入卡牌
		var card_1_texture = load(level_up_three_card_array[0]['card_textrue'])
		card_1.texture = card_1_texture
		card_1_name.text = level_up_three_card_array[0]['card_name']
		card_1_description.text = level_up_three_card_array[0]['card_description']
		var card_2_texture = load(level_up_three_card_array[1]['card_textrue'])
		card_2.texture = card_2_texture
		card_2_name.text = level_up_three_card_array[1]['card_name']
		card_2_description.text = level_up_three_card_array[1]['card_description']
		var card_3_texture = load(level_up_three_card_array[2]['card_textrue'])
		card_3.texture = card_3_texture
		card_3_name.text = level_up_three_card_array[2]['card_name']
		card_3_description.text = level_up_three_card_array[2]['card_description']
		## 弹出升级卡牌选择
		while get_tree().paused:
			await Tools.time_sleep(0.1)
		level_up_ui.show()
		## 增加权重
		for row in card_level_up_json_data:
			row["weight"] += 10
		## 暂停
		get_tree().paused = true


## 设置英雄信息
func _set_hero_properties(hero: Hero, properties: Dictionary):
	hero.hero_name = properties.name
	Current.hero = hero
	hero.hero_movement = properties.movement
	hero.position = grid_index_to_position(properties.init_vec)
	## 职业图标
	class_icon.texture = load(properties.class_icon)
	#Current.all_hero_dict[hero.hero_name] = hero
	hero.hero_cmd.connect(_on_hero_cmd)
	var hero_skills_ui = SceneManager.create_scene(hero.hero_name + "_skills")
	hero_skill.add_child(hero_skills_ui)
	## onready后无法获取到代码新增的节点skill_1_ui，在此处添加了场景树之后可以获取，但无法使用唯一标识获取
	var hero_skill_child = hero_skill.get_child(1)
	skill_1_ui = hero_skill_child.get_node("%skill_1")
	
	#skill_1_ui = hero_skill.get_node("MarginContainer/HBoxContainer/skill_1")
	

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
func _roll_dice(slime_instantiate, roll_dice=1, roll_color=1):
	turn_button.disabled = true
	if roll_dice:
		slime_instantiate.dice.play("roll")
	if roll_color:
		slime_instantiate.animated_sprite_2d.play("roll")
	await get_tree().create_timer(1.0).timeout
	if roll_dice:
		slime_instantiate.dice.stop()
		slime_instantiate.dice.set_frame_and_progress(dice_point.pick_random(), 0)
	if roll_color:
		slime_instantiate.animated_sprite_2d.play("idle")
	turn_button.disabled = false

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
				Current.all_enemy_grid_index_array.has(next_grid_index):
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

## 跳过回合按钮按下
func _on_turn_button_pressed() -> void:
	if Current.power < Current.max_power:
		Current.power += 1
	_enemy_turn()
## 让label跟着按钮下降
func _on_turn_button_button_down() -> void:
	turn_button_label.position += Vector2(0, 1)
## 让label跟着按钮回弹
func _on_turn_button_button_up() -> void:
	turn_button_label.position += Vector2(0, -1)
	
## 敌人回合
func _enemy_turn():
	Current.turn = "enemy_turn"
	turn_button.disabled = true
	## 生成史莱姆
	var grids_array = grids.get_children()
	for grid in grids_array:
		grid.warning.visible = false
	for enemy in _slime_create_array:
		if enemy.enemy_grid_index != Current.hero.hero_grid_index and \
		enemy.enemy_grid_index not in Current.all_enemy_grid_index_array:
			enemys.add_child(enemy)
			_roll_dice(enemy)
		else:
			enemy.queue_free()
	#_slime_move_ai()
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
	## 恢复鼠标
	CursorManager.reset_cursor()
	EventBus.event_emit("hide_all_skills")
	## 判断是否过关
	if Current.total_score >= Current.target_score and Current.count_round <= 10:
		## 显示剩余回合奖励的金币
		## 过关时剩余合金币数组
		var coin_array_1_children = coin_array_1.get_children()
		for coin_icon in coin_array_1_children:
			coin_icon.hide()
		var range_times = 10 - Current.count_round
		if range_times > 3: range_times = 3
		for i in range(range_times):
			coin_array_1_children[i].show()
		Current.count_add_coins += range_times
		## 显示最高骰子数奖励的金币
		## 过关时最高子数金币数组
		var coin_array_2_children = coin_array_2.get_children()
		for coin_icon in coin_array_2_children:
			coin_icon.hide()
		range_times = Current.highest_dice_num - 3
		if  range_times > 3:
			range_times = 3
		elif range_times < 0:
			range_times = 0
		for i in range(range_times):
			coin_array_2_children[i].show()
		Current.count_add_coins += range_times + 1
		get_tree().paused = true
		clear_stage_ui.show()
	##判断失败
	Current.count_round += 1
	if Current.count_round > 10:
		print("游戏失败")
		get_tree().paused = true
	## 下回合开始
	Current.turn = "hero_turn"
	turn_button.disabled = false
	
	## 测试
	#var a = dice_list.get_children()[0]
	#Tools.big_flow_effect(a)

## 修改数值
func _modifiy_value(original_value: int, operate: String, value: float) -> int:
	var modified_value: float
	match operate:
		'add':
			modified_value = original_value + value
		'sub':
			modified_value = original_value - value
		'mul':
			modified_value = original_value * value
		'div':
			modified_value = original_value / value
	return round(modified_value)
	
## 鼠标移出可移动区域清除格子位置
func _on_area_2d_mouse_entered() -> void:
	Current.within_grid_area = false

func _on_skill_system_hide_all_skill() -> void:
	skill_1_ui.hide_all_skill()

func _on_card_1_button_pressed() -> void:
	match level_up_three_card_array[0]['card_id']:
		'card_one':
			Current.one_score = _modifiy_value(
				Current.one_score,
				level_up_three_card_array[0]['card_operate'],
				level_up_three_card_array[0]['card_value']
				)
		'card_two':
			Current.two_score = _modifiy_value(
				Current.two_score,
				level_up_three_card_array[0]['card_operate'],
				level_up_three_card_array[0]['card_value']
				)
		'card_three':
			Current.three_score = _modifiy_value(
				Current.three_score,
				level_up_three_card_array[0]['card_operate'],
				level_up_three_card_array[0]['card_value']
				)
		'card_four':
			Current.four_score = _modifiy_value(
				Current.four_score,
				level_up_three_card_array[0]['card_operate'],
				level_up_three_card_array[0]['card_value']
				)
		'card_five':
			Current.five_score = _modifiy_value(
				Current.five_score,
				level_up_three_card_array[0]['card_operate'],
				level_up_three_card_array[0]['card_value']
				)
		'card_six':
			Current.six_score = _modifiy_value(
				Current.six_score,
				level_up_three_card_array[0]['card_operate'],
				level_up_three_card_array[0]['card_value']
				)
		'card_none':
			Current.none_percent = _modifiy_value(
				Current.none_percent,
				level_up_three_card_array[0]['card_operate'],
				level_up_three_card_array[0]['card_value']
				)
		'card_duizi':
			Current.duizi_percent = _modifiy_value(
				Current.duizi_percent,
				level_up_three_card_array[0]['card_operate'],
				level_up_three_card_array[0]['card_value']
				)
		'card_shunzi':
			Current.shunzi_percent = _modifiy_value(
				Current.shunzi_percent,
				level_up_three_card_array[0]['card_operate'],
				level_up_three_card_array[0]['card_value']
				)
		'card_tongse':
			Current.tongse_percent = _modifiy_value(
				Current.tongse_percent,
				level_up_three_card_array[0]['card_operate'],
				level_up_three_card_array[0]['card_value']
				)
		'card_tongdui':
			Current.tongdui_percent = _modifiy_value(
				Current.tongdui_percent,
				level_up_three_card_array[0]['card_operate'],
				level_up_three_card_array[0]['card_value']
				)
		'card_tongshun':
			Current.tongshun_percent = _modifiy_value(
				Current.tongshun_percent,
				level_up_three_card_array[0]['card_operate'],
				level_up_three_card_array[0]['card_value']
				)
	get_tree().paused = false
	level_up_ui.hide()

func _on_card_2_button_pressed() -> void:
	match level_up_three_card_array[1]['card_id']:
		'card_one':
			Current.one_score = _modifiy_value(
				Current.one_score,
				level_up_three_card_array[1]['card_operate'],
				level_up_three_card_array[1]['card_value']
				)
		'card_two':
			Current.two_score = _modifiy_value(
				Current.two_score,
				level_up_three_card_array[1]['card_operate'],
				level_up_three_card_array[1]['card_value']
				)
		'card_three':
			Current.three_score = _modifiy_value(
				Current.three_score,
				level_up_three_card_array[1]['card_operate'],
				level_up_three_card_array[1]['card_value']
				)
		'card_four':
			Current.four_score = _modifiy_value(
				Current.four_score,
				level_up_three_card_array[1]['card_operate'],
				level_up_three_card_array[1]['card_value']
				)
		'card_five':
			Current.five_score = _modifiy_value(
				Current.five_score,
				level_up_three_card_array[1]['card_operate'],
				level_up_three_card_array[1]['card_value']
				)
		'card_six':
			Current.six_score = _modifiy_value(
				Current.six_score,
				level_up_three_card_array[1]['card_operate'],
				level_up_three_card_array[1]['card_value']
				)
		'card_none':
			Current.none_percent = _modifiy_value(
				Current.none_percent,
				level_up_three_card_array[1]['card_operate'],
				level_up_three_card_array[1]['card_value']
				)
		'card_duizi':
			Current.duizi_percent = _modifiy_value(
				Current.duizi_percent,
				level_up_three_card_array[1]['card_operate'],
				level_up_three_card_array[1]['card_value']
				)
		'card_shunzi':
			Current.shunzi_percent = _modifiy_value(
				Current.shunzi_percent,
				level_up_three_card_array[1]['card_operate'],
				level_up_three_card_array[1]['card_value']
				)
		'card_tongse':
			Current.tongse_percent = _modifiy_value(
				Current.tongse_percent,
				level_up_three_card_array[1]['card_operate'],
				level_up_three_card_array[1]['card_value']
				)
		'card_tongdui':
			Current.tongdui_percent = _modifiy_value(
				Current.tongdui_percent,
				level_up_three_card_array[1]['card_operate'],
				level_up_three_card_array[1]['card_value']
				)
		'card_tongshun':
			Current.tongshun_percent = _modifiy_value(
				Current.tongshun_percent,
				level_up_three_card_array[1]['card_operate'],
				level_up_three_card_array[1]['card_value']
				)
	get_tree().paused = false
	level_up_ui.hide()

func _on_card_3_button_pressed() -> void:
	match level_up_three_card_array[2]['card_id']:
		'card_one':
			Current.one_score = _modifiy_value(
				Current.one_score,
				level_up_three_card_array[2]['card_operate'],
				level_up_three_card_array[2]['card_value']
				)
		'card_two':
			Current.two_score = _modifiy_value(
				Current.two_score,
				level_up_three_card_array[2]['card_operate'],
				level_up_three_card_array[2]['card_value']
				)
		'card_three':
			Current.three_score = _modifiy_value(
				Current.three_score,
				level_up_three_card_array[2]['card_operate'],
				level_up_three_card_array[2]['card_value']
				)
		'card_four':
			Current.four_score = _modifiy_value(
				Current.four_score,
				level_up_three_card_array[2]['card_operate'],
				level_up_three_card_array[2]['card_value']
				)
		'card_five':
			Current.five_score = _modifiy_value(
				Current.five_score,
				level_up_three_card_array[2]['card_operate'],
				level_up_three_card_array[2]['card_value']
				)
		'card_six':
			Current.six_score = _modifiy_value(
				Current.six_score,
				level_up_three_card_array[2]['card_operate'],
				level_up_three_card_array[2]['card_value']
				)
		'card_none':
			Current.none_percent = _modifiy_value(
				Current.none_percent,
				level_up_three_card_array[2]['card_operate'],
				level_up_three_card_array[2]['card_value']
				)
		'card_duizi':
			Current.duizi_percent = _modifiy_value(
				Current.duizi_percent,
				level_up_three_card_array[2]['card_operate'],
				level_up_three_card_array[2]['card_value']
				)
		'card_shunzi':
			Current.shunzi_percent = _modifiy_value(
				Current.shunzi_percent,
				level_up_three_card_array[2]['card_operate'],
				level_up_three_card_array[2]['card_value']
				)
		'card_tongse':
			Current.tongse_percent = _modifiy_value(
				Current.tongse_percent,
				level_up_three_card_array[2]['card_operate'],
				level_up_three_card_array[2]['card_value']
				)
		'card_tongdui':
			Current.tongdui_percent = _modifiy_value(
				Current.tongdui_percent,
				level_up_three_card_array[2]['card_operate'],
				level_up_three_card_array[2]['card_value']
				)
		'card_tongshun':
			Current.tongshun_percent = _modifiy_value(
				Current.tongshun_percent,
				level_up_three_card_array[2]['card_operate'],
				level_up_three_card_array[2]['card_value']
				)
	get_tree().paused = false
	level_up_ui.hide()


func _on_stage_clear_button_pressed() -> void:
	## 增加金币
	Current.total_coins += Current.count_add_coins
	## 更新回合、关卡、当前分数、目标分数
	Current.count_round = 1
	Current.total_score = 0
	if Current.count_stage < 12:
		Current.count_stage += 1
	else:
		## 游戏胜利
		print("胜利")
	for row in stage_info_json_data:
		if row["stage_num"] == Current.count_stage:
			Current.target_score = row["target_score"]
	clear_stage_ui.hide()
	## 清空一关金币奖励数和最高骰子奖励数
	Current.count_add_coins = 0
	Current.highest_dice_num = 0
	get_tree().paused = false

## 重掷按钮按下
func _on_reroll_button_pressed() -> void:
	if reroll_button.button_pressed == false:
		reroll_button.button_pressed = true
	else:
		EventBus.event_emit("hide_skill_range")
		EventBus.event_emit("reset_all_hero_skills")
		CursorManager.change_cursor("reroll")
		EventBus.event_emit("reroll")
		

func _on_coin_skill_1_pressed() -> void:
	if coin_skill_1.button_pressed == false:
		coin_skill_1.button_pressed = true
	else:
		EventBus.event_emit("hide_skill_range")
		EventBus.event_emit("reset_all_hero_skills")
		CursorManager.change_cursor(Current.coin_skill_array_dict[0]["coin_skill_id"])
		EventBus.event_emit(Current.coin_skill_array_dict[0]["coin_skill_id"])

func _on_coin_skill_2_pressed() -> void:
	if coin_skill_2.button_pressed == false:
		coin_skill_2.button_pressed = true
	else:
		EventBus.event_emit("hide_skill_range")
		EventBus.event_emit("reset_all_hero_skills")
		CursorManager.change_cursor(Current.coin_skill_array_dict[1]["coin_skill_id"])
		EventBus.event_emit(Current.coin_skill_array_dict[1]["coin_skill_id"])

func _on_coin_skill_3_pressed() -> void:
	if coin_skill_3.button_pressed == false:
		coin_skill_3.button_pressed = true
	else:
		EventBus.event_emit("hide_skill_range")
		EventBus.event_emit("reset_all_hero_skills")
		CursorManager.change_cursor(Current.coin_skill_array_dict[2]["coin_skill_id"])
		EventBus.event_emit(Current.coin_skill_array_dict[2]["coin_skill_id"])
