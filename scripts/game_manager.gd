extends Node2D

signal slime_reroll_finished

const hero_property = {
	"soldier": {"name": "soldier", "movement": 3, "init_vec": Vector2(3, 3), "class_icon": "res://images/soldier_icon.png"},
	"archer": {"name": "archer", "movement": 2, "init_vec": Vector2(3, 2)},
	"mage": {"name": "mage", "movement": 2, "init_vec": Vector2(2, 2)}
	}

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var grids: Node2D = $grids
@onready var heros: Node2D = $heros
@onready var buildings: Node2D = $buildings
@onready var enemys: Node2D = $enemys
@onready var turn_button: TextureButton = %turn_button
@onready var stage_label: Label = %stage_label
@onready var turn_label: Label = %turn_label
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
@onready var hide_level_up_ui_button: Button = %hide_level_up_ui_button
## 过关界面
@onready var clear_stage_ui: CanvasLayer = $clear_stage_ui
@onready var clear_stage_label: Label = %clear_stage_label
@onready var stage_clear_label_1: Label = %stage_clear_label_1
@onready var stage_clear_label_2: Label = %stage_clear_label_2
@onready var stage_clear_label_3: Label = %stage_clear_label_3
@onready var stage_coin_label_1: Label = %stage_coin_label_1
@onready var stage_coin_label_2: Label = %stage_coin_label_2
@onready var stage_coin_label_3: Label = %stage_coin_label_3
@onready var stage_coin_label_4: Label = %stage_coin_label_4
@onready var stage_coin_rlabel_1: RichTextLabel = %stage_coin_rlabel_1
@onready var stage_coin_rlabel_2: RichTextLabel = %stage_coin_rlabel_2
@onready var stage_coin_rlabel_3: RichTextLabel = %stage_coin_rlabel_3
@onready var stage_coin_rlabel_4: RichTextLabel = %stage_coin_rlabel_4
@onready var paper_texture: TextureRect = %paper_texture
@onready var stage_clear_button: Button = %stage_clear_button
## 帮助按钮
@onready var help_button: TextureButton = %help_button
## 职业图标
@onready var class_icon: TextureRect = %class_icon
## debuff UI
@onready var debuff_container: HFlowContainer = %debuff_container
## buff UI
@onready var buff_container: HFlowContainer = %buff_container
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
@onready var direction_ui: CanvasLayer = %direction_ui
@onready var cancel_direction_button: Button = %cancel_direction_button
@onready var up_button: TextureButton = %up_button
@onready var left_button: TextureButton = %left_button
@onready var right_button: TextureButton = %right_button
@onready var down_button: TextureButton = %down_button
@onready var difficulty_icon: TextureRect = %difficulty_icon
@onready var get_coin_skill_ui: CanvasLayer = %get_coin_skill_ui
@onready var get_coin_skill_1: TextureRect = %get_coin_skill_1
@onready var get_coin_skill_2: TextureRect = %get_coin_skill_2
@onready var get_coin_skill_tooltip_1: PanelContainer = %get_coin_skill_tooltip_1
@onready var get_coin_skill_tooltip_2: PanelContainer = %get_coin_skill_tooltip_2
@onready var hide_get_coin_skill_ui_button: Button = %hide_get_coin_skill_ui_button
## 关卡切换效果
@onready var stage_effect_ui: Control = $stage_effect_ui
@onready var stage_effect_label: RichTextLabel = %stage_effect_label
## 诅咒切换效果
@onready var debuff_effect_ui: Control = $debuff_effect_ui
@onready var debuff_effect_label: RichTextLabel = %debuff_effect_label
## 升级时的卡牌数据
@onready var card_level_up_json_data :Array = Tools.load_json_file('res://config/card_level_up.json')
## 关卡数据
@onready var stage_info_json_data: Array = Tools.load_json_file('res://config/stage_info.json')
## 金币能数据
@onready var coin_skill_json_data: Array = Tools.load_json_file('res://config/coin_skill.json')
## debuff数据
@onready var debuff_json_data: Array = Tools.load_json_file('res://config/debuff.json')
## boss debuff数据
@onready var boss_debuff_json_data: Array = Tools.load_json_file('res://config/boss_debuff.json')
## buff数据
@onready var buff_json_data: Array = Tools.load_json_file('res://config/buff.json')


## 格子像素大小
var grid_size = Vector2(16, 16)
## 起始格子位置
var start_pos = Vector2(16, 16)
## 格子位置上下左右偏移
const grid_offset = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]
## 所有格子字典
var all_grid_dict: Dictionary
## astar寻路
var astar: AStarGrid2D
## 最大可移动的地图块
var _removable_map_vec =  Vector2(7, 7)
## 史莱姆创建数组
var _slime_create_array: Array
## 带有骰子点数的动画图片索引
var dice_point: Array = [0, 2, 4, 6, 8, 10]
## 史莱姆场景数组
var slime_scene_array := ['slime_small', 'slime_small_red', 'slime_small_yellow', 'slime_small_blue']
## 边缘格子数组
var _margin_grid: Array[Vector2]
## 颜色
var color := {
	"alpha0": "cc080800",
	"red": "cc0808",
	"green": "0fff5b"
}
## 随机选择出的3张升级时卡牌
var level_up_three_card_array :Array
## BOSS诅咒信息
var boss_debuff_row: Dictionary
## 金币技能选项1
var coin_skill_row_1: Dictionary
## 金币技能选项2
var coin_skill_row_2: Dictionary


func _ready() -> void:
	## 测试
	print("buff" in "skill_attack")
	#_get_coin_skill()
	#_do_stage_clear_effect(7, 8 ,9)
	#await Tools.time_sleep(0.5)
	#EffectManager.stage_change_effect()
	## 临时测试金币技能
	#for row in coin_skill_json_data:
		#if row["coin_skill_id"] in ["reroll_all","double_score","cloud"]:
			#Current.coin_skill_array_dict.append(row)
	#coin_skill_1_icon.texture = load(Current.coin_skill_array_dict[0]["coin_skill_icon"])
	#coin_skill_2_icon.texture = load(Current.coin_skill_array_dict[1]["coin_skill_icon"])
	#coin_skill_3_icon.texture = load(Current.coin_skill_array_dict[2]["coin_skill_icon"])
	#coin_skill_1_label.text = "[img=12]res://images/coin.png[/img] -" + str(int(Current.coin_skill_array_dict[0]["coin_skill_cost"]))
	#coin_skill_2_label.text = "[img=12]res://images/coin.png[/img] -" + str(int(Current.coin_skill_array_dict[1]["coin_skill_cost"]))
	#coin_skill_3_label.text = "[img=12]res://images/coin.png[/img] -" + str(int(Current.coin_skill_array_dict[2]["coin_skill_cost"]))
	
	## 设置基础倍率
	Current.none_percent = 100
	Current.duizi_percent = 150
	Current.shunzi_percent = 160
	Current.tongse_percent = 140
	Current.tongdui_percent = 300
	Current.tongshun_percent = 320
	## 初始化金币
	Current.total_coins = 5
	## 随机择BOSS
	boss_debuff_row = boss_debuff_json_data.pick_random()
	## 设置目标分数
	for row in stage_info_json_data:
		if row["stage_num"] == Current.count_stage:
			Current.target_score = row["target_score"]
	## 生成网格
	for x in range(_removable_map_vec.x):
		for y in range(_removable_map_vec.y):
			var grid = SceneManager.create_scene("grid")
			grid.grid_index = Vector2(x, y)
			grid.position = Vector2(x * grid_size.x + start_pos.x, y * grid_size.y + start_pos.y)
			all_grid_dict[Vector2(x, y)] = grid
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
				_margin_grid.append(Vector2(x, y))
	## 关卡切换效果
	await EffectManager.stage_change_effect()
	## 预生成史莱姆
	_pre_create_slime()
	## 回合处理
	await _turn_process()
	
	## 临时测试debuff
	#_set_stage_debuff(1)
	#await EffectManager.debuff_change_effect()
	
	#for row in debuff_json_data:
		#if row["debuff_id"] == "power_current_score_down":
			#var buff = load(row["debuff_res"]).new(row, self)
			#BuffSystem.callv("set_" + row["debuff_type"], [buff, BuffSystem.buff_type.STAGE])
	## 临时测试buff
	for row in buff_json_data:
		if row["buff_id"] in ["slime_base_score_increase"]:
			var buff = load(row["buff_res"]).new(row, self)
			BuffSystem.callv("set_" + row["buff_type"], [buff, BuffSystem.buff_type.ALWAYS])
	
	## 临时测试BOSS debuff
	#for row in boss_debuff_json_data:
		#if row["debuff_id"] == "attack_score_down":
			#var buff = load(row["debuff_res"]).new(row, self)
			#BuffSystem.callv("set_" + row["debuff_type"], [buff, BuffSystem.buff_type.STAGE])


func grid_index_to_position(grid_index: Vector2) -> Vector2:
	return Vector2(grid_index.x * grid_size.x + start_pos.x, grid_index.y * grid_size.y + start_pos.y)

func position_to_grid_index(_position: Vector2) -> Vector2:
	return Vector2((_position.x - start_pos.x) / grid_size.x, (_position.y - start_pos.y) / grid_size.y)

## 预生成史莱姆
func _pre_create_slime():
	var available_grid_array: Array[Vector2]
	var create_slime_grid_index_array: Array[Vector2]
	var slime_create_num: int
	## 计算可以生成史莱姆的空地块
	for grid_index in all_grid_dict.keys():
		if grid_index not in Current.all_enemy_grid_index_array and grid_index != Current.hero.hero_grid_index:
			available_grid_array.append(grid_index)
	if available_grid_array.size() > 0:
		slime_create_num = clamp(available_grid_array.size(), 1, Current.slime_create_num)
		while create_slime_grid_index_array.size() < slime_create_num:
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

func _create_slime():
	## 生成史莱姆
	var grids_array = grids.get_children()
	for grid in grids_array:
		grid.warning.visible = false
	for enemy in _slime_create_array:
		if enemy.enemy_grid_index != Current.hero.hero_grid_index and \
		enemy.enemy_grid_index not in Current.all_enemy_grid_index_array:
			enemys.add_child(enemy)
			while enemy not in Current.all_enemy_array:
				await Tools.time_sleep(0.01)
			_roll_dice(enemy)
		else:
			enemy.queue_free()
	Current.last_slime_create_array = _slime_create_array.duplicate()
	_slime_create_array.clear()

## 边缘生成史莱姆
func _create_slime_on_margin_grid():
	## 边缘地块随机生成3个史莱姆
	var available_grid_array: Array[Vector2]
	var create_slime_grid_index_array: Array[Vector2]
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
	if Current.power_slime_array.size() < Current.power_slime_num and Current.all_enemy_array.size() > 0:
		for i in range(Current.power_slime_num - Current.power_slime_array.size()):
			var power_slime = Current.normal_slime_array.pick_random()
			if power_slime not in Current.power_slime_array:
				power_slime.animated_sprite_2d.material.set_shader_parameter("outline_color", Color(0.0, 18.892, 18.892))
				power_slime.animated_sprite_2d.material.set_shader_parameter("is_high_light", true)

## 添加金币史莱姆
func _create_coin_slime():
	if Current.coin_slime_array.size() < Current.coin_slime_num and Current.all_enemy_array.size() > 0:
		for i in range(Current.coin_slime_num - Current.coin_slime_array.size()):
			var coin_slime = Current.normal_slime_array.pick_random()
			if coin_slime not in Current.coin_slime_array:
				coin_slime.animated_sprite_2d.material.set_shader_parameter("outline_color", Color(18.892, 18.892, 0.0))
				coin_slime.animated_sprite_2d.material.set_shader_parameter("is_high_light", true)
		
## 史莱姆移动
func slime_move_ai():
	var target_position_array: Array
	var slime_create_grid_index_array: Array
	for enemy in Current.all_enemy_array:
		var movable_grid_array: Array
		for offset in grid_offset:
			var next_grid_index = enemy.enemy_grid_index + offset
			## 获取所有即将出生的史莱姆位置
			for slime in _slime_create_array:
				slime_create_grid_index_array.append(slime.enemy_grid_index)
			## 判断是否有英雄、史莱姆、出生点、超出边界
			if Current.hero.hero_grid_index == next_grid_index or \
			Current.all_enemy_grid_index_array.has(next_grid_index) or \
			target_position_array.has(Tools.grid_index_to_position(next_grid_index)) or \
			slime_create_grid_index_array.has(next_grid_index) or \
			next_grid_index.x < 0 or \
			next_grid_index.x > _removable_map_vec.x - 1 or \
			next_grid_index.y < 0 or \
			next_grid_index.y > _removable_map_vec.y - 1:
				continue
			movable_grid_array.append(next_grid_index)
		## 从可移动数组中随机一个移动
		if movable_grid_array.size() > 0:
			var target_grid_index = movable_grid_array.pick_random()
			var target_position: Vector2 = grid_index_to_position(target_grid_index)
			enemy.target_position = target_position
			target_position_array.append(target_position)
			while target_position not in target_position_array:
				await Tools.time_sleep(0.01)

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
		await _roll_dice(slime, 1, 0)
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
		await _roll_dice(slime_instantiate, 0, 1)
	else:
		slime.queue_free()
		var slime_sence = slime_scene_array.pick_random()
		var slime_instantiate = SceneManager.create_scene(slime_sence)
		slime_instantiate.position = grid_index_to_position(slime_grid_index)
		slime_instantiate.enemy_grid_index = slime_grid_index
		enemys.add_child(slime_instantiate)
		await _roll_dice(slime_instantiate)
	slime_reroll_finished.emit()

func _set_stage_debuff(boss=0):
	if boss == 0:
		var debuff_row = debuff_json_data.pick_random()
		var buff = load(debuff_row["debuff_res"]).new(debuff_row, self)
		BuffSystem.callv("set_" + debuff_row["debuff_type"], [buff, BuffSystem.buff_type.STAGE])
		debuff_effect_label.text = "获得诅咒  [img=15 ]" + debuff_row["debuff_icon"] + "[/img]"
	else:
		var buff = load(boss_debuff_row["debuff_res"]).new(boss_debuff_row, self)
		BuffSystem.callv("set_" + boss_debuff_row["debuff_type"], [buff, BuffSystem.buff_type.STAGE])
		debuff_effect_label.text = "获得诅咒  [img=15 ]" + boss_debuff_row["debuff_icon"] + "[/img]"

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
	await wait_for_buff_finish()
	await _check_and_level_up()


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
	await Tools.time_sleep(1)
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
	EventBus.event_emit("do_post_hero_move_buff")

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

## 回合操作
func _turn_process():
	## 敌人回合
	_turn_clean()
	## 等待回合船动画
	while "turn_ship_animation" in Current.public_lock_array:
		await Tools.time_sleep(0.05)
	## 生成史莱姆加入节点
	await _create_slime()
	## 史莱姆预生成和告警信息
	_pre_create_slime()
	## 保证骰子动画完成
	while "reroll_slime_buff" in Current.public_lock_array:
		await Tools.time_sleep(0.05)
	## 生成能量史莱姆
	_create_power_slime()
	## 生成金币史莱姆
	_create_coin_slime()
	## 玩家回合前
	_pre_hero_turn_begin()

## 技能结算
func skill_attack():
	## 攻击的时候禁用合结束按钮
	turn_button.disabled = true
	await skill_system.skill_attack()
	Current.public_lock_array.erase("skill_attack")
	Current.is_attacked = true
	## 执行敌人回合前buff
	EventBus.event_emit("do_pre_enemy_turn_buff")
	## 等待buff处理完成
	await wait_for_buff_finish()
	## 检查过关
	await _check_stage_clear()
	## 等待过关结算
	while clear_stage_ui.visible == true:
		await Tools.time_sleep(0.2)
	## 敌人回合
	await _turn_process()
	## 执行玩家回合前buff
	EventBus.event_emit("do_pre_hero_turn_buff")
	#turn_button.disabled = false

##等待buff执行完成
func wait_for_buff_finish():
		while Current.buff_lock_array.size() > 0:
			for lock_name in Current.buff_lock_array:
				await Tools.time_sleep(0.05)

## 跳过回合按钮按下
func _on_turn_button_pressed() -> void:
	turn_button.disabled = true
	## 等待英雄移动完
	while Current.id_path.size() > 0:
		await Tools.time_sleep(0.01)
	if Current.power < Current.max_power:
		Current.power += 1
	## 执行敌人回合前buff
	EventBus.event_emit("do_pre_enemy_turn_buff")
	## 等待buff处理完成
	await wait_for_buff_finish()
	## 检查过关
	await _check_stage_clear()
	## 等待过关结算
	while clear_stage_ui.visible == true:
		await Tools.time_sleep(0.2)
	## 回合处理
	await _turn_process()
	## 执行玩家回合前buff
	EventBus.event_emit("do_pre_hero_turn_buff")
	#turn_button.disabled = false
	## 测试
	#for row in debuff_json_data:
		#if row["debuff_id"] == "disable_one":
			#var instance = load(row["debuff_res"]).new(row)
			#instance.set_buff()
	
## 让label跟着按钮下降
func _on_turn_button_button_down() -> void:
	turn_button_label.position += Vector2(0, 1)
## 让label跟着按钮回弹
func _on_turn_button_button_up() -> void:
	turn_button_label.position += Vector2(0, -1)
	
## 回合的清理工作
func _turn_clean():
	## 重置英雄能
	EventBus.event_emit("reset_all_hero_skills")
	## 重置金币技能
	EventBus.event_emit("reset_cursor")
	## 重置击杀过金币史莱姆标记
	Current.killed_coin_slime = false
	## 增加回合数
	Current.count_round += 1
	## 进入敌人回合
	Current.turn = "enemy_turn"

func _pre_hero_turn_begin():
	## 判断失败
	if Current.count_round > 10:
		print("游戏失败")
		get_tree().paused = true
	## 重置英雄状态
	for hero in Current.all_hero_array:
		hero.hero_state_machine.transition_to("idle")
	## 重新计算不可移动地块
	reset_astar_solid()
	## 重置已移动标记
	Current.is_moved = false
	## 重掷已攻击标记
	Current.is_attacked = false
	## 恢复鼠标
	CursorManager.reset_cursor()
	EventBus.event_emit("hide_all_skills")
	## 下回合开始
	Current.turn = "hero_turn"
	
func reset_astar_solid() -> void:
	## 重新计算不可移动地块
	for grid in grids.get_children():
		astar.set_point_solid(grid.grid_index, false)
	for grid_index in Current.all_enemy_grid_index_array:
		astar.set_point_solid(grid_index, true)

## 判断是否过关
func _check_stage_clear():
	if Current.total_score >= Current.target_score and Current.count_round <= 10:
		## 回合固定金币
		var stage_add_coin = 1
		Current.count_add_coins += stage_add_coin
		## 显示剩余回合奖励的金币
		var round_add_coin = 10 - Current.count_round
		stage_coin_label_2.text = str(round_add_coin)
		Current.count_add_coins += round_add_coin
		#var add_coin := 0
		#for i in range(10 - Current.count_round):
			#add_coin += 1
			#stage_coin_label_2.text = str(add_coin)
			#await Tools.time_sleep(0.1)
		## 过关时最高子数金币数组
		var highest_dice_add_coin = Current.highest_dice_num - 1
		Current.count_add_coins += highest_dice_add_coin
		await _do_stage_clear_effect(stage_add_coin, round_add_coin, highest_dice_add_coin)
		## 清理关卡buff
		EventBus.event_emit("clear_stage_buff")

func _do_stage_clear_effect(stage_add_coin, round_add_coin, highest_dice_add_coin):
	## 万一有升级让升级先出现
	await Tools.time_sleep(0.1)
	while get_tree().paused:
		await Tools.time_sleep(0.05)
	get_tree().paused = true
	## 纸
	clear_stage_ui.show()
	await EffectManager.top_to_bottom_effect(paper_texture, 0.5)
	## 标题
	clear_stage_label.show()
	## 第一行
	stage_clear_label_1.show()
	await EffectManager.typewriter_effect(stage_clear_label_1, stage_clear_label_1.text, 0.5)
	stage_coin_rlabel_1.show()
	stage_coin_label_1.show()
	await EffectManager.label_num_rolling_effect(stage_coin_label_1, stage_add_coin)
	## 第二行
	stage_clear_label_2.show()
	await EffectManager.typewriter_effect(stage_clear_label_2, stage_clear_label_2.text, 0.5)
	stage_coin_rlabel_2.show()
	stage_coin_label_2.show()
	await EffectManager.label_num_rolling_effect(stage_coin_label_2, round_add_coin)
	## 第三行
	stage_clear_label_3.show()
	await EffectManager.typewriter_effect(stage_clear_label_3, stage_clear_label_3.text, 0.5)
	stage_coin_rlabel_3.show()
	stage_coin_label_3.show()
	await EffectManager.label_num_rolling_effect(stage_coin_label_3, highest_dice_add_coin)
	## 汇总金币
	stage_coin_rlabel_4.show()
	stage_coin_label_4.show()
	await EffectManager.label_num_rolling_effect(
		stage_coin_label_4,
		stage_add_coin + round_add_coin + highest_dice_add_coin
		)
	stage_clear_button.show()
	
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
	skill_1_ui.hide_all_skills()

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

func _hide_all_clear_stage_ui():
	clear_stage_label.hide()
	stage_clear_label_1.hide()
	stage_coin_rlabel_1.hide()
	stage_coin_label_1.hide()
	stage_clear_label_2.hide()
	stage_coin_rlabel_2.hide()
	stage_coin_label_2.hide()
	stage_clear_label_3.hide()
	stage_coin_rlabel_3.hide()
	stage_coin_label_3.hide()
	stage_coin_rlabel_4.hide()
	stage_coin_label_4.hide()
	stage_clear_button.hide()
	clear_stage_ui.hide()

func _on_stage_clear_button_pressed() -> void:
	## 增加金币
	Current.total_coins += Current.count_add_coins
	## 更新回合、关卡、当前分数、目标分数
	Current.count_round = 0
	Current.total_score = 0
	if Current.count_stage < 12:
		Current.count_stage += 1
	else:
		## 游戏胜利
		print("胜利")
	for row in stage_info_json_data:
		if row["stage_num"] == Current.count_stage:
			Current.target_score = row["target_score"]
			difficulty_icon.texture = load(row["stage_type_icon"])
			difficulty_icon.tooltip_text = row["stage_type"]
	## 隐藏结算显示内容
	_hide_all_clear_stage_ui()
	## 清空一关金币奖励数和最高骰子奖励数
	Current.count_add_coins = 0
	Current.highest_dice_num = 1
	get_tree().paused = false
	## 关卡切换效果
	await EffectManager.stage_change_effect()
	## 3、6、9关设置诅咒
	if Current.count_stage in [3, 6, 9]:
		_set_stage_debuff()
		await EffectManager.debuff_change_effect()
	## 4、7、10关获得金币技能
	if Current.count_stage in [4, 7, 10]:
		_get_coin_skill()
	## 12关设置BOSS诅咒
	if Current.count_stage == 12:
		_set_stage_debuff(1)
		await EffectManager.debuff_change_effect()
	


## 重掷按钮按下
func _on_reroll_button_pressed() -> void:
	if reroll_button.button_pressed == false:
		reroll_button.button_pressed = true
	else:
		EventBus.event_emit("hide_skill_range")
		EventBus.event_emit("reset_all_hero_skills")
		CursorManager.change_cursor("reroll")
		EventBus.event_emit("reroll")
		
func _get_coin_skill():
	## 设置选择UI的图标和提示
	coin_skill_row_1 = coin_skill_json_data.pick_random()
	coin_skill_json_data.erase(coin_skill_row_1)
	get_coin_skill_1.texture = load(coin_skill_row_1["coin_skill_icon"])
	get_coin_skill_tooltip_1.tooltip_text = coin_skill_row_1["coin_skill_tooltip"]
	coin_skill_row_2 = coin_skill_json_data.pick_random()
	coin_skill_json_data.erase(coin_skill_row_2)
	get_coin_skill_2.texture = load(coin_skill_row_2["coin_skill_icon"])
	get_coin_skill_tooltip_2.tooltip_text = coin_skill_row_2["coin_skill_tooltip"]
	## 弹出选则UI
	while get_tree().paused:
		await Tools.time_sleep(0.1)
	get_coin_skill_ui.show()
	get_tree().paused = true
	

func _on_coin_skill_1_pressed() -> void:
	if coin_skill_1.button_pressed == false:
		coin_skill_1.button_pressed = true
	else:
		EventBus.event_emit("reset_all_hero_skills")
		CursorManager.change_cursor(Current.coin_skill_array_dict[0]["coin_skill_id"])
		EventBus.event_emit(Current.coin_skill_array_dict[0]["coin_skill_id"])

func _on_coin_skill_2_pressed() -> void:
	if coin_skill_2.button_pressed == false:
		coin_skill_2.button_pressed = true
	else:
		EventBus.event_emit("reset_all_hero_skills")
		CursorManager.change_cursor(Current.coin_skill_array_dict[1]["coin_skill_id"])
		EventBus.event_emit(Current.coin_skill_array_dict[1]["coin_skill_id"])

func _on_coin_skill_3_pressed() -> void:
	if coin_skill_3.button_pressed == false:
		coin_skill_3.button_pressed = true
	else:
		EventBus.event_emit("reset_all_hero_skills")
		CursorManager.change_cursor(Current.coin_skill_array_dict[2]["coin_skill_id"])
		EventBus.event_emit(Current.coin_skill_array_dict[2]["coin_skill_id"])

func _on_cancel_direction_button_pressed() -> void:
	EventBus.event_emit("reset_cursor")
	direction_ui.hide()
	get_tree().paused = false


func _on_up_button_pressed() -> void:
	direction_ui.hide()
	get_tree().paused = false
	CursorManager.change_cursor("mouse_up")


func _on_left_button_pressed() -> void:
	direction_ui.hide()
	get_tree().paused = false
	CursorManager.change_cursor("mouse_left")


func _on_right_button_pressed() -> void:
	direction_ui.hide()
	get_tree().paused = false
	CursorManager.change_cursor("mouse_right")


func _on_down_button_pressed() -> void:
	direction_ui.hide()
	get_tree().paused = false
	CursorManager.change_cursor("mouse_down")


func _on_hide_level_up_ui_button_pressed() -> void:
	if hide_level_up_ui_button.text == "隐藏":
		for object in level_up_ui.get_children():
			if object.name != "hide_level_up_ui_button":
				object.hide()
		hide_level_up_ui_button.text = "显示"
	else:
		for object in level_up_ui.get_children():
			if object.name != "hide_level_up_ui_button":
				object.show()
		hide_level_up_ui_button.text = "隐藏"


func _on_hide_get_coin_skill_ui_button_pressed() -> void:
	if hide_get_coin_skill_ui_button.text == "隐藏":
		for object in get_coin_skill_ui.get_children():
			if object.name != "hide_get_coin_skill_ui_button":
				object.hide()
		hide_get_coin_skill_ui_button.text = "显示"
	else:
		for object in get_coin_skill_ui.get_children():
			if object.name != "hide_get_coin_skill_ui_button":
				object.show()
		hide_get_coin_skill_ui_button.text = "隐藏"

## 设置技能到技能栏
func _set_coin_skill(coin_skill_row):
	match Current.coin_skill_array_dict.size():
		0:
			Current.coin_skill_array_dict.append(coin_skill_row)
			coin_skill_1_icon.texture = load(coin_skill_row["coin_skill_icon"])
			coin_skill_1_label.text = "[img=12]res://images/coin.png[/img] -" + \
			str(int(coin_skill_row["coin_skill_cost"]))
			coin_skill_1.tooltip_text = coin_skill_row["coin_skill_tooltip"]
		1:
			Current.coin_skill_array_dict.append(coin_skill_row)
			coin_skill_2_icon.texture = load(coin_skill_row["coin_skill_icon"])
			coin_skill_2_label.text = "[img=12]res://images/coin.png[/img] -" + \
			str(int(coin_skill_row["coin_skill_cost"]))
			coin_skill_2.tooltip_text = coin_skill_row["coin_skill_tooltip"]
		2:
			Current.coin_skill_array_dict.append(coin_skill_row)
			coin_skill_3_icon.texture = load(coin_skill_row["coin_skill_icon"])
			coin_skill_3_label.text = "[img=12]res://images/coin.png[/img] -" + \
			str(int(coin_skill_row["coin_skill_cost"]))
			coin_skill_3.tooltip_text = coin_skill_row["coin_skill_tooltip"]

func _on_get_coin_skill_1_button_pressed() -> void:
	_set_coin_skill(coin_skill_row_1)
	## 设置金币会刷新技能可用性
	Current.total_coins = Current.total_coins
	get_tree().paused = false
	get_coin_skill_ui.hide()

func _on_get_coin_skill_2_button_pressed() -> void:
	_set_coin_skill(coin_skill_row_2)
	## 设置金币会刷新技能可用性
	Current.total_coins = Current.total_coins
	get_tree().paused = false
	get_coin_skill_ui.hide()
	
