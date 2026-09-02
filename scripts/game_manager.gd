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
@onready var hero_skill_ui: MarginContainer
@onready var target_score: Label = %target_score
@onready var total_score: Label = %total_score
## 骰型板
@onready var one_score: Label = %one_score
@onready var two_score: Label = %two_score
@onready var three_score: Label = %three_score
@onready var four_score: Label = %four_score
@onready var five_score: Label = %five_score
@onready var six_score: Label = %six_score

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

@onready var duizi_percent_frame: PanelContainer = %duizi_percent_frame
@onready var shunzi_percent_frame: PanelContainer = %shunzi_percent_frame
@onready var tongse_percent_frame: PanelContainer = %tongse_percent_frame
@onready var tongdui_percent_frame: PanelContainer = %tongdui_percent_frame
@onready var tongshun_percent_frame: PanelContainer = %tongshun_percent_frame
@onready var drop_slot_panel_frame: PanelContainer = %drop_slot_panel_frame
@onready var drop_slot_panel_point: Label = %drop_slot_panel_point
## 分值
@onready var score_bar_label: Label = %score_bar_label
## 燃烧ShaderMaterial（1000+分区段使用）
@onready var score_burn_material: ShaderMaterial = preload("res://shaders/fire_outline.tres")
#@onready var dice_list: HBoxContainer = %dice_list
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
## 商店UI
@onready var shop_ui: CanvasLayer = %shop_ui
@onready var buff_shop_icon_1: TextureRect = %buff_shop_icon_1
@onready var buff_shop_icon_2: TextureRect = %buff_shop_icon_2
@onready var buff_shop_icon_3: TextureRect = %buff_shop_icon_3
@onready var buff_shop_rlabel_1: RichTextLabel = %buff_shop_rlabel_1
@onready var buff_shop_rlabel_2: RichTextLabel = %buff_shop_rlabel_2
@onready var buff_shop_rlabel_3: RichTextLabel = %buff_shop_rlabel_3
@onready var buff_shop_button_1: TextureButton = %buff_shop_button_1
@onready var buff_shop_button_2: TextureButton = %buff_shop_button_2
@onready var buff_shop_button_3: TextureButton = %buff_shop_button_3
@onready var buff_lock_button_1: TextureButton = %buff_lock_button_1
@onready var buff_lock_button_2: TextureButton = %buff_lock_button_2
@onready var buff_lock_button_3: TextureButton = %buff_lock_button_3
@onready var buff_refresh_button: TextureButton = %buff_refresh_button
@onready var buff_refresh_rlabel: RichTextLabel = %buff_refresh_rlabel
@onready var shop_next_level_button: Button = %shop_next_level_button
@onready var shop_label: Label = %shop_label
@onready var shop_texture_ui: TextureRect = %shop_texture_ui
## 商店金币技能相关节点
@onready var shop_coin_skill_icon: TextureRect = %shop_coin_skill_icon
@onready var shop_coin_skill_rlabel: RichTextLabel = %shop_coin_skill_rlabel
@onready var shop_coin_skill_button: TextureButton = %shop_coin_skill_button
## 技能替换UI相关节点
@onready var replace_skill_ui: CanvasLayer = %replace_skill_ui
@onready var replace_skill_1: TextureButton = %replace_skill_1
@onready var replace_skill_2: TextureButton = %replace_skill_2
@onready var replace_skill_3: TextureButton = %replace_skill_3
@onready var replace_skill_1_icon: TextureRect = %replace_skill_1_icon
@onready var replace_skill_2_icon: TextureRect = %replace_skill_2_icon
@onready var replace_skill_3_icon: TextureRect = %replace_skill_3_icon
@onready var cancel_replace_button: Button = %cancel_replace_button
var shop_buff_1: Dictionary
var shop_buff_2: Dictionary
var shop_buff_3: Dictionary
## 商店buff已购买标记（3个槽位）
var shop_buff_bought := [false, false, false]
var buff_refresh_cost := 1:
	set(v):
		buff_refresh_cost = v
		if Current.zero_coin_refresh_times > 0:
			buff_refresh_rlabel.text = "换一批[img=14 ]res://images/coin.png[/img]0"
		else:
			buff_refresh_rlabel.text = "换一批[img=14 ]res://images/coin.png[/img]" + \
			str(buff_refresh_cost)
## UI
@onready var power_label: Label = %power_label
@onready var level_label: Label = %level_label
@onready var ship: TextureRect = %ship
@onready var scale_wrapper3: Control = %scale_wrapper3
@onready var potion_button_label: Control = %potion_button_label
@onready var turn_coin_label: Label = %turn_coin_label
@onready var potion_button: TextureButton = %potion_button
@onready var blood_bottle_label: Label = %blood_bottle_label
@onready var blood_bottle_progress: TextureProgressBar = %blood_bottle_progress
@onready var blood_bottle_progress_label: Label = %blood_bottle_progress_label
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
@onready var dice_adjust_ui: CanvasLayer = %dice_adjust_ui
@onready var coin_skill_system: Node2D = $coin_skill_system
@onready var dice_add_button: Button = %dice_add_button
@onready var dice_sub_button: Button = %dice_sub_button
@onready var cancel_dice_adjust_button: Button = %cancel_dice_adjust_button
@onready var difficulty_icon: TextureRect = %difficulty_icon
## 关卡切换效果
@onready var stage_effect_ui: Control = $stage_effect_ui
@onready var stage_effect_label: RichTextLabel = %stage_effect_label
## BOSS效果切换效果
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
## buff数据
@onready var buff_json_data: Array = Tools.load_json_file('res://config/buff.json')
## 骰型倍率
@onready var dice_multiplier_json_data: Array = Tools.load_json_file("res://config/dice_multiplier.json")
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
## 在随机可用空位生成史莱姆（供buff调用的公开方法）
func spawn_slime_at_random_grid(count: int) -> void:
	## 查找可用空位：未被英雄、已有史莱姆或预生成史莱姆占用的格子
	var available_grid_array: Array[Vector2]
	var slime_create_grid_index_array: Array[Vector2]
	for grid_index in all_grid_dict.keys():
		if grid_index not in Current.all_enemy_grid_index_array and \
		grid_index != Current.hero.hero_grid_index and \
		grid_index not in _margin_grid:
			available_grid_array.append(grid_index)
	if available_grid_array.is_empty():
		return
	## clamp到可用空位数量
	var actual_count = mini(count, available_grid_array.size())
	var spawned_enemies: Array = []
	while slime_create_grid_index_array.size() < actual_count:
		var grid_index = available_grid_array.pick_random()
		if ! grid_index in slime_create_grid_index_array:
			slime_create_grid_index_array.append(grid_index)
	for grid_index in slime_create_grid_index_array:
		var slime_sence = slime_scene_array.pick_random()
		var enemy_instantiate = SceneManager.create_scene(slime_sence)
		enemy_instantiate.position = grid_index_to_position(grid_index)
		enemy_instantiate.enemy_grid_index = grid_index
		enemys.add_child(enemy_instantiate)
		spawned_enemies.append(enemy_instantiate)
	## await process_frame确保注册到Current.all_enemy_array
	await get_tree().process_frame
	## 触发骰子动画
	for enemy in spawned_enemies:
		if not is_instance_valid(enemy):
			continue
		enemy.dice.play("roll")
		enemy.animated_sprite_2d.play("roll")
	## 等待动画
	await Tools.time_sleep(1)
	## 停止动画并设置随机帧
	for enemy in spawned_enemies:
		if not is_instance_valid(enemy):
			continue
		enemy.dice.stop()
		enemy.dice.set_frame_and_progress(dice_point.pick_random(), 0)
		enemy.animated_sprite_2d.play("idle")
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
## 商店当前展示的金币技能数据行
var shop_coin_skill_row: Dictionary = {}
## 商店金币技能是否已购买（防止重复购买，用于按钮状态刷新）
var shop_coin_skill_bought := false
## 待处理的商店技能（购买后等待添加或替换）
var pending_shop_skill: Dictionary = {}
## 已在商店出现过的金币技能ID列表（防止重复出现）
var appeared_coin_skill_ids: Array = []
## 本run已随机抽中的debuff_id列表（跨关卡不重复，run开始时清空）
var _used_debuff_ids: Array = []
## 升级待增加的HP值（延迟到扣血之后应用，确保先扣血再加升级血）


## 骰型分数Label映射
var _dice_score_labels: Dictionary
## 骰型倍率Label映射
var _dice_multiplier_labels: Dictionary

func _ready() -> void:
	## 自注册：场景切换后 Current.game_manager 引用随新战局自动刷新
	Current.game_manager = self
	## 测试

	#_set_shop_buff()
	## 临时测试金币技能
	#for row in coin_skill_json_data:
		#if row["coin_skill_id"] in ["reroll_all","double_score","cloud"]:
			#Current.coin_skill_array_dict.append(row)
	#coin_skill_1_icon.texture = load(Current.coin_skill_array_dict[0]["coin_skill_icon"])
	#coin_skill_2_icon.texture = load(Current.coin_skill_array_dict[1]["coin_skill_icon"])
	#coin_skill_3_icon.texture = load(Current.coin_skill_array_dict[2]["coin_skill_icon"])

	## 设置基础点数分值（随机分配）
	_randomize_base_scores()
	## 设置倍率
	for row in dice_multiplier_json_data:
		Current.dice_multiplier_dict[int(row["dice_sum"])] = row
	Current.duizi_percent = Current.dice_multiplier_dict[2]["duizi"]
	Current.shunzi_percent = Current.dice_multiplier_dict[2]["shunzi"]
	Current.tongse_percent = Current.dice_multiplier_dict[2]["tongse"]
	Current.tongdui_percent = Current.dice_multiplier_dict[2]["tongdui"]
	Current.tongshun_percent = Current.dice_multiplier_dict[2]["tongshun"]
	## 测试倍率
	#var result = ScoringAlgorithm.count_total_score([["red", 3], ["blue", 3], ["blue", 3], ["blue", 2], ["blue", 1], ["blue", 6]])
	#print(result)
	## 初始化金币
	Current.total_coins = 15
	## 设置目标分数
	for row in stage_info_json_data:
		if row["stage_num"] == Current.count_stage:
			Current.target_score = row["target_score"]
	## 初始化得分累计回血
	Current.score_heal_threshold = Current.score_heal_base_threshold
	## 清空本run已用debuff列表（跨关卡不重复机制的重置）
	_used_debuff_ids = []
	## 生成网格
	for x in range(_removable_map_vec.x):
		for y in range(_removable_map_vec.y):
			var grid = SceneManager.create_scene("grid")
			grid.grid_index = Vector2(x, y)
			grid.position = Vector2(x * grid_size.x + start_pos.x, y * grid_size.y + start_pos.y)
			all_grid_dict[Vector2(x, y)] = grid
			grids.add_child(grid)
	Current.all_grids_array = grids.get_children()
	## 生成英雄（按英雄选择画面选中的类型，默认 soldier）
	var hero_instantiate = SceneManager.create_scene("hero")
	_set_hero_properties(hero_instantiate, hero_property[Current.selected_hero])
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
	## 敌人回合结束，启用回合结束按钮
	_set_turn_button_disabled(false)
	## 悬停追踪器：渲染帧数学换算鼠标所在格子，替代 Area2D 物理拾取（子节点随战局销毁）
	add_child(preload("res://scripts/hover_tracker.gd").new())

	## 临时测试debuff
	#_set_stage_debuff(1)
	#await EffectManager.debuff_change_effect()

	#for row in debuff_json_data:
		#if row["debuff_id"] == "power_backlash":
			#var buff = load(row["debuff_res"]).new(row, self)
			#BuffSystem.callv("set_" + row["debuff_type"], [buff, BuffSystem.buff_type.STAGE])
	## 临时测试buff
	#for row in buff_json_data:
		#if row["buff_id"] in ["six_point_probability_increase"]:
			#var buff = load(row["buff_res"]).new(row, self)
			#BuffSystem.callv("set_" + row["buff_type"], [buff, BuffSystem.buff_type.ALWAYS])

	## 临时测试BOSS debuff
	#for row in debuff_json_data:
		#if row["debuff_id"] == "attack_weaken":
			#var buff = load(row["debuff_res"]).new(row, self)
			#BuffSystem.callv("set_" + row["debuff_type"], [buff, BuffSystem.buff_type.STAGE])


## 随机分配基础分值
## 将总共60点基础分随机分配到1-6点数的骰子上，最低5最高15
func _randomize_base_scores():
	var scores = [5, 5, 5, 5, 5, 5]
	var remaining := 60 - 30  # 剩余30点
	while remaining > 0:
		var idx = randi_range(0, 5)
		if scores[idx] < 15:
			scores[idx] += 1
			remaining -= 1
	Current.one_score = scores[0]
	Current.two_score = scores[1]
	Current.three_score = scores[2]
	Current.four_score = scores[3]
	Current.five_score = scores[4]
	Current.six_score = scores[5]

func grid_index_to_position(grid_index: Vector2) -> Vector2:
	return Vector2(grid_index.x * grid_size.x + start_pos.x, grid_index.y * grid_size.y + start_pos.y)

func position_to_grid_index(_position: Vector2) -> Vector2:
	return Vector2((_position.x - start_pos.x) / grid_size.x, (_position.y - start_pos.y) / grid_size.y)

## 清空所有史莱姆（关卡切换时调用）
func _clear_all_slimes() -> void:
	## 清空所有史莱姆节点
	var _slime_count = enemys.get_child_count()
	for enemy in enemys.get_children():
		enemy.queue_free()
	## 清空预生成列表（防止引用已释放的节点）
	_slime_create_array.clear()
	## 重置史莱姆相关追踪状态
	Current.slime_die_sum = 0
	Current.pattern_kill_sum = 0
	Current.last_slime_create_array = []
	Current.killed_power_slime = false
	## 重置鼠标指向的史莱姆（可能指向已释放的节点）
	Current.slime = null
	## 清除所有网格的 warning 标记
	for grid in grids.get_children():
		grid.warning.visible = false
	## 等待 queue_free 在帧末完成
	await get_tree().process_frame
	print("[slime-reset] 清空了 %d 个史莱姆, enemys 子节点数: %d" % [_slime_count, enemys.get_child_count()])

## 预生成史莱姆
func _pre_create_slime():
	var available_grid_array: Array[Vector2]
	var create_slime_grid_index_array: Array[Vector2]
	var slime_create_num: int
	## 计算可以生成史莱姆的空地块
	for grid_index in all_grid_dict.keys():
		## 判断和已有史莱姆距离小于等于3范围的格子
		if Current.all_enemy_grid_index_array != []:
			for slime_grid_index in Current.all_enemy_grid_index_array:
				if grid_index.distance_to(slime_grid_index) <= 3:
					if grid_index not in Current.all_enemy_grid_index_array and grid_index != Current.hero.hero_grid_index:
						available_grid_array.append(grid_index)
						break
		else:
			if grid_index not in Current.all_enemy_grid_index_array and \
			grid_index != Current.hero.hero_grid_index and \
			grid_index not in _margin_grid:
				available_grid_array.append(grid_index)
	if available_grid_array.size() > 0:
		slime_create_num = clamp(available_grid_array.size(), 1, Current.slime_create_num)
		## 计算距离小于等于3的格子数组

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


## 从severity=="normal"的debuff池中排除已用条目后随机选1个
## 选中条目的debuff_id追加到_used_debuff_ids，返回选中的配置行
## 若池为空返回空Dictionary
func _pick_random_debuff() -> Dictionary:
	var available: Array = []
	for debuff_row in debuff_json_data:
		if debuff_row.get("severity", "normal") == "normal" and \
		debuff_row["debuff_id"] not in _used_debuff_ids:
			available.append(debuff_row)
	if available.is_empty():
		return {}
	var picked: Dictionary = available.pick_random()
	_used_debuff_ids.append(picked["debuff_id"])
	return picked

## 生成精英史莱姆（在原精英关3/6/9开局生成）
func _spawn_elite_slime():
	## 在随机空格生成1个精英史莱姆
	var empty_grids = []
	for grid_index in all_grid_dict:
		if grid_index not in Current.all_enemy_grid_index_array and grid_index != Current.hero.hero_grid_index:
			empty_grids.append(grid_index)
	if empty_grids.is_empty():
		print("[elite-slime] 没有空格可生成精英史莱姆，跳过")
		return
	var spawn_grid = empty_grids.pick_random()
	var slime_sence = slime_scene_array.pick_random()
	var slime_instantiate = SceneManager.create_scene(slime_sence)
	slime_instantiate.position = grid_index_to_position(spawn_grid)
	slime_instantiate.enemy_grid_index = spawn_grid
	enemys.add_child(slime_instantiate)
	## 设置精英属性
	slime_instantiate.is_elite = true
	var gate_type = Current.ELITE_GATE_TYPES.pick_random()
	slime_instantiate.gate_type = gate_type
	slime_instantiate.gate_count = Current.ELITE_GATE_COUNTS[gate_type]
	## 设置红色轮廓
	slime_instantiate.animated_sprite_2d.material.set_shader_parameter("outline_color", Color(18.892, 0, 0))
	slime_instantiate.animated_sprite_2d.material.set_shader_parameter("is_high_light", true)
	## 施加1个随机普通debuff（跨关卡不重复）
	var debuff_row = _pick_random_debuff()
	if not debuff_row.is_empty():
		var buff = load(debuff_row["debuff_res"]).new(debuff_row, self)
		BuffSystem.callv("set_" + debuff_row["debuff_type"], [buff, BuffSystem.buff_type.ELITE])
		debuff_effect_label.text = "精英出现！ [img=15 ]" + debuff_row["debuff_icon"] + "[/img]"
		await EffectManager.debuff_change_effect()
	print("[elite-slime] 生成了精英史莱姆: gate=%s count=%d" % [gate_type, Current.ELITE_GATE_COUNTS[gate_type]])

## 生成BOSS史莱姆（根据关卡配置生成）
func _spawn_boss_slime(stage_config: Dictionary = {}):
	var empty_grids = []
	for grid_index in all_grid_dict:
		if grid_index not in Current.all_enemy_grid_index_array and grid_index != Current.hero.hero_grid_index:
			empty_grids.append(grid_index)
	if empty_grids.is_empty():
		print("[boss-slime] 没有空格可生成BOSS史莱姆，跳过")
		return
	var spawn_grid = empty_grids.pick_random()
	var slime_sence = slime_scene_array.pick_random()
	var slime_instantiate = SceneManager.create_scene(slime_sence)
	slime_instantiate.position = grid_index_to_position(spawn_grid)
	slime_instantiate.enemy_grid_index = spawn_grid
	enemys.add_child(slime_instantiate)
	## 设置BOSS属性（从stage_config读取，缺失时使用fallback默认值）
	slime_instantiate.is_boss = true
	var gate_type = stage_config.get("boss_gate_type", Current.BOSS_GATE_TYPES.pick_random())
	slime_instantiate.gate_type = gate_type
	slime_instantiate.gate_count = stage_config.get("boss_gate_count", Current.BOSS_GATE_COUNT)
	## 设置深紫色轮廓
	slime_instantiate.animated_sprite_2d.material.set_shader_parameter("outline_color", Color(18.892, 0, 18.892))
	slime_instantiate.animated_sprite_2d.material.set_shader_parameter("is_high_light", true)
	## 施加BOSS效果：先固定后随机，从stage_config读取配置
	var fixed_curses: Array = stage_config.get("boss_fixed_curses", [])
	var curse_count: int = stage_config.get("boss_curse_count", 1)
	var applied_debuff_ids: Array = []
	var applied_debuff_icons: String = ""
	## 1. 先施加固定BOSS效果（从全量debuff_json_data按debuff_id查找，不限于severity=normal）
	for fixed_id in fixed_curses:
		var fixed_row = null
		for debuff_row in debuff_json_data:
			if debuff_row["debuff_id"] == fixed_id:
				fixed_row = debuff_row
				break
		if fixed_row != null:
			var buff = load(fixed_row["debuff_res"]).new(fixed_row, self)
			BuffSystem.callv("set_" + fixed_row["debuff_type"], [buff, BuffSystem.buff_type.ELITE])
			applied_debuff_ids.append(fixed_id)
			applied_debuff_icons += " [img=15 ]" + fixed_row["debuff_icon"] + "[/img]"
	## 2. 再从随机池中抽取boss_curse_count个不重复BOSS效果（由_used_debuff_ids统一去重）
	for i in range(curse_count):
		var debuff_row = _pick_random_debuff()
		if debuff_row.is_empty():
			break
		var buff = load(debuff_row["debuff_res"]).new(debuff_row, self)
		BuffSystem.callv("set_" + debuff_row["debuff_type"], [buff, BuffSystem.buff_type.ELITE])
		applied_debuff_ids.append(debuff_row["debuff_id"])
		applied_debuff_icons += " [img=15 ]" + debuff_row["debuff_icon"] + "[/img]"
	debuff_effect_label.text = "BOSS出现！" + applied_debuff_icons
	await EffectManager.debuff_change_effect()
	## 根据boss_extra_elites值生成额外精英史莱姆
	var extra_elites: int = stage_config.get("boss_extra_elites", 0)
	for i in range(extra_elites):
		await _spawn_elite_slime()
	print("[boss-slime] 生成了BOSS史莱姆: gate=%s count=%d curse_count=%d extra_elites=%d" % [gate_type, slime_instantiate.gate_count, applied_debuff_ids.size(), extra_elites])

## 移动精英/BOSS史莱姆（同时移动模式）
func _move_elite_boss_slimes():
	var directions = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]
	var target_grid_index_array: Array
	## 阶段1：批量计算目标位置并设置（不等待移动完成）
	for _slime in Current.elite_slime_array + Current.boss_slime_array:
		if not is_instance_valid(_slime):
			continue
		var movable_grid_array: Array
		## 找出所有可移动的相邻格子
		for direction in directions:
			var next_grid = _slime.enemy_grid_index + direction
			if next_grid.x >= 0 and next_grid.x < 7 and next_grid.y >= 0 and next_grid.y < 7:
				if next_grid not in Current.all_enemy_grid_index_array and next_grid != Current.hero.hero_grid_index and next_grid not in target_grid_index_array:
					movable_grid_array.append(next_grid)
		## 从可移动数组中随机选一个移动
		if movable_grid_array.size() > 0:
			var target_grid = movable_grid_array.pick_random()
			_slime.target_position = grid_index_to_position(target_grid)
			target_grid_index_array.append(target_grid)
	## 阶段2：统一等待所有史莱姆移动完成
	while Current.has_move_slime:
		await Tools.time_sleep(0.01)

func _create_slime():
	## 生成史莱姆（同时生成模式）
	_set_turn_button_disabled(true)
	## 清空上一回合的史莱姆生成记录，确保点数锁定只修改当前回合的史莱姆
	Current.last_slime_create_array = []
	var grids_array = grids.get_children()
	for grid in grids_array:
		grid.warning.visible = false
	print("[slime-reset] _create_slime: _slime_create_array.size=%d, enemys.get_child_count=%d" % [_slime_create_array.size(), enemys.get_child_count()])
	## 阶段1：批量加入场景树
	var spawned_enemies: Array = []
	for enemy in _slime_create_array:
		if not is_instance_valid(enemy):
			print("[slime-reset] 跳过无效节点")
			continue
		if enemy.enemy_grid_index != Current.hero.hero_grid_index and \
		enemy.enemy_grid_index not in Current.all_enemy_grid_index_array:
			enemys.add_child(enemy)
			Current.last_slime_create_array.append(enemy)
			spawned_enemies.append(enemy)
		else:
			print("[slime-reset] 跳过重叠位置节点: grid=%s hero=%s" % [str(enemy.enemy_grid_index), str(Current.hero.hero_grid_index)])
			enemy.queue_free()
	_slime_create_array.clear()
	## 阶段2：等待所有节点注册到 Current.all_enemy_array
	await get_tree().process_frame
	## 阶段3：并行触发所有骰子动画
	for enemy in spawned_enemies:
		if not is_instance_valid(enemy):
			continue
		enemy.dice.play("roll")
		enemy.animated_sprite_2d.play("roll")
	## 阶段4：统一等待动画时长
	await Tools.time_sleep(1)
	## 阶段5：批量停止动画并设置随机帧
	for enemy in spawned_enemies:
		if not is_instance_valid(enemy):
			continue
		enemy.dice.stop()
		enemy.dice.set_frame_and_progress(dice_point.pick_random(), 0)
		enemy.animated_sprite_2d.play("idle")


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
	var _normal_slimes = Current.normal_slime_array
	if Current.power_slime_array.size() < Current.power_slime_num and _normal_slimes.size() > 0:
		for i in range(Current.power_slime_num - Current.power_slime_array.size()):
			if _normal_slimes.is_empty():
				break
			var power_slime = _normal_slimes.pick_random()
			if power_slime not in Current.power_slime_array:
				power_slime.animated_sprite_2d.material.set_shader_parameter("outline_color", Color(0.0, 18.892, 18.892))
				power_slime.animated_sprite_2d.material.set_shader_parameter("is_high_light", true)

## 史莱姆移动（同时移动模式）
func slime_move_ai():
	var target_grid_index_array: Array
	var slime_create_grid_index_array: Array
	## 获取所有即将出生的史莱姆位置
	for slime in _slime_create_array:
		slime_create_grid_index_array.append(slime.enemy_grid_index)
	## 阶段1：批量计算目标位置并设置（不等待移动完成）
	for enemy in Current.all_enemy_array:
		var movable_grid_array: Array
		for offset in grid_offset:
			var next_grid_index = enemy.enemy_grid_index + offset
			## 判断是否有英雄、史莱姆、出生点、超出边界
			if Current.hero.hero_grid_index == next_grid_index or \
			Current.all_enemy_grid_index_array.has(next_grid_index) or \
			target_grid_index_array.has(next_grid_index) or \
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
			target_grid_index_array.append(target_grid_index)
	## 阶段2：统一等待所有史莱姆移动完成
	while Current.has_move_slime:
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
	var curse_debuffs = []
	for debuff_row in debuff_json_data:
		if debuff_row.get("severity", "normal") == "normal":
			curse_debuffs.append(debuff_row)
	if curse_debuffs.is_empty():
		return
	var debuff_row = curse_debuffs.pick_random()
	var buff = load(debuff_row["debuff_res"]).new(debuff_row, self)
	BuffSystem.callv("set_" + debuff_row["debuff_type"], [buff, BuffSystem.buff_type.STAGE])
	debuff_effect_label.text = "获得BOSS效果  [img=15 ]" + debuff_row["debuff_icon"] + "[/img]"

func _set_buff(buff_row):
	if not ResourceLoader.exists(buff_row["buff_res"]):
		print("[WARNING] buff 脚本不存在，跳过: buff_id=%s buff_res=%s" % [buff_row.get("buff_id", "?"), buff_row["buff_res"]])
		return
	var buff = load(buff_row["buff_res"]).new(buff_row, self)
	## buff_type 支持字符串或数组（一个buff注册到多个时序pipeline）
	var buff_types = buff_row["buff_type"]
	if typeof(buff_types) == TYPE_ARRAY:
		for bt in buff_types:
			BuffSystem.callv("set_" + bt, [buff, BuffSystem.buff_type.ALWAYS])
	else:
		BuffSystem.callv("set_" + buff_types, [buff, BuffSystem.buff_type.ALWAYS])
	# 在buff.set_buff()创建buff_texture后，统一设置元数据
	if buff.buff_texture:
		buff.buff_texture.set_meta("buff_meta", buff.buff_meta)
		buff.buff_texture.set_meta("buff_instance", buff)
	if buff.debuff_texture:
		buff.debuff_texture.set_meta("buff_meta", buff.buff_meta)
		buff.debuff_texture.set_meta("buff_instance", buff)
	## 同族霸主自动注册：购买buff后检查同族数量≥4，自动注册对应霸主buff
	var buff_family = buff.family
	if buff_family != "" and BuffSystem.get_family_count(buff_family) >= 4:
		for overlord_row in buff_json_data:
			if overlord_row.get("family", "") == buff_family and overlord_row.get("auto_activate", false):
				var overlord_id = overlord_row.get("buff_id", "")
				if not BuffSystem.is_buff_registered(overlord_id):
					var overlord = load(overlord_row["buff_res"]).new(overlord_row, self)
					BuffSystem.callv("set_" + overlord_row["buff_type"], [overlord, BuffSystem.buff_type.ALWAYS])

##设置验条刻度
func _set_exp_bar_scale(num_now: int, num_max: int) -> void:
	exp_label.text = str(num_now) + '/' + str(num_max)

## 增加经验
func add_exp(new_exp: int) -> void:
	Current.hero_exp += new_exp
	exp_bar.value = Current.hero_exp
	_set_exp_bar_scale(Current.hero_exp, Current.require_exp)
	## 等待一会让一次攻击下的史莱姆经验全加上再升级
	await Tools.time_sleep(0.2)
	await wait_for_buff_finish()
	await _check_and_level_up()

## 根据卡牌效果生成动态描述（BBCode格式）
func _generate_card_description(effects: Array) -> String:
	var score_names = {"one_score": "一点", "two_score": "二点", "three_score": "三点", "four_score": "四点", "five_score": "五点", "six_score": "六点"}
	var percent_names = {"duizi_percent": "对子倍率", "shunzi_percent": "顺子倍率", "tongse_percent": "同色倍率", "tongdui_percent": "同对倍率", "tongshun_percent": "同顺倍率"}
	var parts := []
	for effect in effects:
		var target = effect["target"]
		var operate = effect["operate"]
		var value = effect["value"]
		var target_name = ""
		match target:
			"all_score":
				target_name = "所有点数"
			"all_percent":
				target_name = "所有倍率"
			"random_score":
				target_name = "随机一个点数"
			"min_score":
				target_name = "最低点数"
			"max_score":
				target_name = "最高点数"
			_:
				if target in score_names:
					target_name = score_names[target]
				elif target in percent_names:
					target_name = percent_names[target]
				else:
					target_name = target
		var desc = ""
		match operate:
			"add":
				desc = target_name + "[color=green]+" + str(int(value)) + "[/color]"
			"sub":
				desc = target_name + "[color=red]-" + str(int(value)) + "[/color]"
			"mul":
				if value >= 1.0:
					var pct = roundi((value - 1.0) * 100)
					desc = target_name + "[color=green]+" + str(pct) + "%[/color]"
				else:
					var pct = roundi((1.0 - value) * 100)
					desc = target_name + "[color=red]-" + str(pct) + "%[/color]"
			"set":
				if int(value) == 0:
					desc = target_name + "[color=red]归零[/color]"
				else:
					desc = target_name + "[color=green]=" + str(int(value)) + "[/color]"
			"swap":
				var from_name = ""
				if str(value) in score_names:
					from_name = score_names[str(value)]
				elif str(value) in percent_names:
					from_name = percent_names[str(value)]
				else:
					from_name = str(value)
				desc = target_name + "和" + from_name + "[color=green]互换[/color]"
			"copy_from":
				var from_name = ""
				if str(value) in score_names:
					from_name = score_names[str(value)]
				elif str(value) in percent_names:
					from_name = percent_names[str(value)]
				else:
					from_name = str(value)
				desc = target_name + "[color=green]=" + from_name + "的值[/color]"
			"set_to_max":
				desc = target_name + "[color=green]=最高点数[/color]"
			"set_to_avg":
				desc = target_name + "[color=green]=平均值[/color]"
		parts.append(desc)
	return "，".join(parts)

## 对卡牌效果进行随机波动（±20%，最少1点）
func _fluctuate_card_effects(effects: Array) -> Array:
	var fluctuated := []
	for effect in effects:
		var new_effect = effect.duplicate()
		var operate = effect["operate"]
		var value = effect["value"]
		if operate == "add" or operate == "sub":
			var fluctuated_val = roundi(value * randf_range(0.8, 1.2))
			new_effect["value"] = maxi(fluctuated_val, 1)
		elif operate == "mul":
			var delta = value - 1.0
			var fluctuated_delta = delta * randf_range(0.8, 1.2)
			new_effect["value"] = snappedf(1.0 + fluctuated_delta, 0.01)
		# set, swap, copy_from, set_to_max, set_to_avg: no fluctuation
		fluctuated.append(new_effect)
	return fluctuated

func _set_level_up_card():
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
	## 对每张卡牌效果进行随机波动
	for i in range(level_up_three_card_array.size()):
		var row = level_up_three_card_array[i].duplicate()
		row["card_effects"] = _fluctuate_card_effects(row["card_effects"])
		row["card_description"] = _generate_card_description(row["card_effects"])
		level_up_three_card_array[i] = row
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

## 检查并升级
func _check_and_level_up() -> void:
	if Current.hero_exp >= Current.require_exp:
		Current.level += 1
		## 每5级max_hp+1（仅上限成长，不回血）
		if Current.level % 5 == 0:
			Current.max_hp += 1
		var overflow_exp = Current.hero_exp - Current.require_exp
		## 最多增加到10个史莱姆可以升级
		if Current.require_exp < 10:
			Current.require_exp += 1
		Current.hero_exp = overflow_exp
		## 设置经验条数值
		exp_bar.value = overflow_exp
		exp_bar.max_value = Current.require_exp
		## 设置经验label
		_set_exp_bar_scale(Current.hero_exp, Current.require_exp)
		## 设置升级时卡牌UI
		_set_level_up_card()
		## 有其他全局界面操作时等待
		while get_tree().paused:
			await Tools.time_sleep(0.1)
		## 等待他升级界面完成
		while "level_up_ui" in Current.public_lock_array:
			await Tools.time_sleep(0.1)
		Current.public_lock_array.append("level_up_ui")
		## 升级效果
		await EffectManager.level_up_effect(Current.hero.animated_sprite_2d)
		## 弹出升级卡牌选择
		level_up_ui.show()
		## 增加权重
		for row in card_level_up_json_data:
			row["weight"] += 40
		## 防止切换面paused切换导致暂停没有成功
		await Tools.time_sleep(0.1)
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
	hero_skills_ui.name = "skills_root"
	hero_skill_ui = hero_skill.get_node("skills_root/%skill_1")


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
func _on_hero_cmd(cmd_name: String, event: InputEvent = null):
	if event != null:
		call(cmd_name, event)
	else:
		call(cmd_name)

## 投骰子动画
func _roll_dice(slime_instantiate, roll_dice=1, roll_color=1):
	if not is_instance_valid(slime_instantiate):
		return
	_set_turn_button_disabled(true)
	if roll_dice:
		slime_instantiate.dice.play("roll")
	if roll_color:
		slime_instantiate.animated_sprite_2d.play("roll")
	await Tools.time_sleep(1)
	if not is_instance_valid(slime_instantiate):
		return
	if roll_dice:
		slime_instantiate.dice.stop()
		slime_instantiate.dice.set_frame_and_progress(dice_point.pick_random(), 0)
	if roll_color:
		slime_instantiate.animated_sprite_2d.play("idle")
	_set_turn_button_disabled(false)

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
func hero_move(event: InputEvent = null):
	if Current.id_path.size() > 0:
		return
	var hero = Current.clicked_hero
	## 用鼠标点击位置计算目标格子索引，而非依赖 Current.grid_index
	var target_grid_index: Vector2
	if event != null:
		## event.global_position 是视口坐标，需转换为世界坐标后再 to_local
		var world_pos = get_viewport().canvas_transform.affine_inverse() * event.global_position
		var local_pos = to_local(world_pos)
		target_grid_index = position_to_grid_index(local_pos).floor()
	else:
		target_grid_index = Current.grid_index
	## 判断目标位置不在移动围内或有其他棋子，则不能移动
	if not Current.movable_grid_index_array.has(target_grid_index) \
	or Current.all_hero_grid_index_array.has(target_grid_index) \
	or Current.all_enemy_grid_index_array.has(target_grid_index):
		return
	## 保存移动前的位置、格子索引和总分（用于撤回移动）
	Current.pre_move_position = hero.position
	Current.pre_move_grid_index = hero.hero_grid_index
	Current.pre_move_total_score = Current.total_score
	Current.id_path = astar.get_id_path(hero.hero_grid_index, target_grid_index)
	Current.grids_moved_this_turn = Current.id_path.size() - 1
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
var _turn_processing := false
func _turn_process():
	if _turn_processing:
		return
	_turn_processing = true
	## 敌人回合期间禁用回合结束按钮
	_set_turn_button_disabled(true)
	## 敌人回合
	_turn_clean()
	## 后期回合（8-10回合）史莱姆生成翻倍
	Current.slime_create_num = 3  ## 重置为基础值
	if Current.count_round >= 8 and Current.count_round <= 10:
		Current.slime_create_num = 6
	## 读取并消耗slime_tide_pending和swarm_call_pending标记
	if Current.slime_tide_pending > 0:
		Current.slime_create_num += Current.slime_tide_pending
		Current.slime_tide_pending = 0
	if Current.swarm_call_pending > 0:
		Current.slime_create_num += Current.swarm_call_pending
		Current.swarm_call_pending = 0

	## 第8回合显示危险提示
	if Current.count_round == 8:
		stage_effect_label.text = "危险⚠️"
		await EffectManager.stage_change_effect()
	## 等待回合船动画
	while "turn_ship_animation" in Current.public_lock_array:
		await Tools.time_sleep(0.05)
	## 生成史莱姆加入节点
	await _create_slime()
	## 史莱姆预生成和告警信息
	_pre_create_slime()
	## 保证骰子动画完成
	while "slime_chaos_buff" in Current.public_lock_array:
		await Tools.time_sleep(0.05)
	## 移动精英/BOSS史莱姆（等待移动完成再继续，防止玩家在移动期间操作）
	await _move_elite_boss_slimes()
	## 生成能量史莱姆
	_create_power_slime()
	## 玩家回合前
	_pre_hero_turn_begin()
	_turn_processing = false

## 技能结算
func skill_attack():
	## 攻击的时候禁用合结束按钮
	_set_turn_button_disabled(true)
	await skill_system.skill_attack()
	Current.public_lock_array.erase("skill_attack")
	Current.is_attacked = true
	## 执行敌人回合前buff
	EventBus.event_emit("do_pre_enemy_turn_buff")
	## 等待buff处理完成
	await wait_for_buff_finish()
	## 等待一会让升级先弹出
	await Tools.time_sleep(0.4)
	## 有其他全局界面操作时等待（主要是升级）
	while "level_up_effect" in Current.public_lock_array:
		await Tools.time_sleep(0.1)
	while get_tree().paused:
		await Tools.time_sleep(0.1)
	## 攻击结算后，得分累计回血（在检查过关之前，确保血瓶即时获得）
	_apply_score_heal()
	## 更新连续得分回合数（连击风暴/连击狂热用）
	if Current.once_total_score > 0:
		Current.consecutive_score_turns += 1
	else:
		Current.consecutive_score_turns = 0
	## 清空单次总分（移至此处，确保 _apply_score_heal 能正确读取 once_total_score）
	Current.once_total_score = 0
	## 检查过关
	var stage_cleared = await _check_stage_clear()
	## 等待过关结算
	while clear_stage_ui.visible == true:
		await Tools.time_sleep(0.2)
	## 等待关卡切换完成
	while "stage_transition" in Current.public_lock_array:
		await Tools.time_sleep(0.1)
	## 过关后不再扣血，但需要执行敌人回合（生成新关卡史莱姆、设置玩家回合）
	if stage_cleared:
		await _turn_process()
		EventBus.event_emit("do_pre_hero_turn_buff")
		_set_turn_button_disabled(false)
		return
	## 攻击结算后，基于当前场上残留史莱姆扣血
	_apply_hp_damage()
	## 敌人回合
	await _turn_process()
	## 执行玩家回合前buff
	EventBus.event_emit("do_pre_hero_turn_buff")
	_set_turn_button_disabled(false)

##等待buff执行完成
func wait_for_buff_finish():
		while Current.buff_lock_array.size() > 0:
			for lock_name in Current.buff_lock_array:
				await Tools.time_sleep(0.05)

## 跳过回合按钮按下
func _on_turn_button_pressed() -> void:
	_set_turn_button_disabled(true)
	## 等待英雄移动完
	while Current.id_path.size() > 0:
		await Tools.time_sleep(0.01)
	## 跳过回合：断连击（连击风暴用）
	Current.last_turn_attacked = false
	Current.consecutive_score_turns = 0
	## 跳过回合：生成随机骰子放入掉落格子，不再+1能量
	var color_options := ["red", "green", "blue", "yellow"]
	var random_color: String = color_options[randi_range(0, 3)]
	var random_point: int = randi_range(1, 6)
	var random_dice: Array = [random_color, random_point]
	## 如果掉落格子已有骰子，弹出选择
	if Current.drop_slot_dice != null:
		Current.public_lock_array.append("drop_selection")
		var drop_selection_ui = get_node("drop_selection_ui")
		drop_selection_ui.setup([Current.drop_slot_dice.duplicate(), random_dice])
		## 等待玩家选择完成
		while "drop_selection" in Current.public_lock_array:
			await Tools.time_sleep(0.05)
		if Current.has_meta("drop_selection_result"):
			Current.drop_slot_dice = Current.get_meta("drop_selection_result")
			Current.remove_meta("drop_selection_result")
	else:
		Current.drop_slot_dice = random_dice
	## 跳过回合也会掉落骰子，触发掉落奖励buff
	Current.dropped_dice_count = 1  ## 跳过回合只掉落1个新骰子
	await _trigger_drop_bonus()
	## 执行敌人回合前buff
	EventBus.event_emit("do_pre_enemy_turn_buff")
	## 等待buff处理完成
	await wait_for_buff_finish()
	## 检查过关
	var stage_cleared = await _check_stage_clear()
	## 等待过关结算
	while clear_stage_ui.visible == true:
		await Tools.time_sleep(0.2)
	## 过关后不再扣血，但需要执行敌人回合（生成新关卡史莱姆、设置玩家回合）
	if stage_cleared:
		await _turn_process()
		EventBus.event_emit("do_pre_hero_turn_buff")
		_set_turn_button_disabled(false)
		return
	## 跳过回合不攻击，不触发得分回血（once_total_score为0）
	## 跳过回合后，基于当前场上残留史莱姆扣血
	_apply_hp_damage()
	## 回合处理
	await _turn_process()
	## 执行玩家回合前buff
	EventBus.event_emit("do_pre_hero_turn_buff")
	_set_turn_button_disabled(false)
	## 测试

## 回合按钮视觉按下态(由 button_down/up 信号驱动,用于同步内容偏移)
var _turn_button_visual_pressed := false

## 同步回合按钮内容(scale_wrapper3)偏移:按下或禁用时下移1px,否则回原位
func _sync_turn_button_content_offset() -> void:
	scale_wrapper3.position.y = 1.0 if (turn_button.disabled or _turn_button_visual_pressed) else 0.0

## 设置回合按钮禁用状态并同步内容偏移
func _set_turn_button_disabled(state: bool) -> void:
	turn_button.disabled = state
	_sync_turn_button_content_offset()

## 让label跟着按钮下降(含禁用态,偏移由 _sync 统一计算)
func _on_turn_button_button_down() -> void:
	_turn_button_visual_pressed = true
	_sync_turn_button_content_offset()
## 让label跟着按钮回弹
func _on_turn_button_button_up() -> void:
	_turn_button_visual_pressed = false
	_sync_turn_button_content_offset()

## 撤回移动按钮按下动画
func _on_undo_move_button_button_down() -> void:
	if has_node("coin_skill_trun_button/HBoxContainer/undo_move_button/undo_move_button_label"):
		var label = get_node("coin_skill_trun_button/HBoxContainer/undo_move_button/undo_move_button_label")
		label.position += Vector2(0, 1)

## 撤回移动按钮回弹动画
func _on_undo_move_button_button_up() -> void:
	if has_node("coin_skill_trun_button/HBoxContainer/undo_move_button/undo_move_button_label"):
		var label = get_node("coin_skill_trun_button/HBoxContainer/undo_move_button/undo_move_button_label")
		label.position += Vector2(0, -1)

## 撤回移动按钮按下
func _on_undo_move_button_pressed() -> void:
	## 撤回条件检查：必须已移动且未攻击且在英雄回合
	if not Current.is_moved or Current.is_attacked or Current.turn != "hero_turn":
		return
	var hero = Current.clicked_hero
	if not hero:
		return
	## 恢复英雄位置
	hero.position = Current.pre_move_position
	hero.hero_grid_index = Current.pre_move_grid_index
	## 回滚buff分数差值
	Current.total_score = Current.pre_move_total_score
	## 清空移动路径
	Current.id_path = []
	## 英雄状态机回到idle
	hero.hero_state_machine.transition_to("idle")
	## 重置已移动标记（会触发setter自动禁用撤回按钮）
	Current.is_moved = false
	## 重置本回合移动格数
	Current.grids_moved_this_turn = 0
	## 重置A*路径点
	reset_astar_solid()
	## 清空保存的移动前数据
	Current.pre_move_position = Vector2.ZERO
	Current.pre_move_grid_index = Vector2.ZERO

## 回合的清理工作
func _turn_clean():
	## 重置英雄能
	EventBus.event_emit("reset_all_hero_skills")
	## 重置金币技能
	EventBus.event_emit("reset_cursor")
	## 重置击杀过能量史莱姆标记
	Current.killed_power_slime = false
	## 重置掉落格子骰子消耗标记（每回合开始时重置）
	Current.drop_slot_consumed_this_turn = false
	## 增加回合数
	Current.count_round += 1
	## 进入敌人回合
	Current.turn = "enemy_turn"

## HP扣血逻辑：根据场上史莱姆数量阶梯扣血
func _apply_hp_damage():
	## 计算场上史莱姆数量
	var slime_count = 0
	for _slime in Current.all_enemy_array:
		if is_instance_valid(_slime):
			slime_count += 1
	## 防御公式扣血: damage = max(0, ceil((slime_count - defense) / 3))
	var hp_before = Current.player_hp
	var effective: int = slime_count - Current.player_defense
	var damage: int = ceili(effective / 3.0) if effective > 0 else 0
	## 铁胃减伤：最终伤害-1（最少0）
	if damage > 0 and Current.iron_stomach_reduction > 0:
		damage = maxi(0, damage - Current.iron_stomach_reduction)
	if damage > 0:
		Current.player_hp -= damage
		## HP扣减视觉反馈
		if has_node("round_process_bar/hp_bar"):
			var hp_bar = get_node("round_process_bar/hp_bar")
			if hp_bar.has_method("play_damage_effect"):
				hp_bar.play_damage_effect()


## 得分累计回血结算（在扣血之前调用）
func _apply_score_heal() -> void:
	if Current.once_total_score <= 0:
		return
	## 累加本回合得分
	Current.score_heal_accumulated += Current.once_total_score
	## 有效阈值（不再受嗜血战意或逆境翻盘降低）
	var effective_threshold := Current.score_heal_threshold
	## 循环检查阈值获得血瓶
	while Current.score_heal_accumulated >= effective_threshold and Current.potion_count < Current.potion_max:
		## 有嗜血战意时溢出保留，无时清零
		if BuffSystem.is_buff_registered("blood_fury"):
			Current.score_heal_accumulated -= effective_threshold
		else:
			Current.score_heal_accumulated = 0
		## 获得血瓶
		Current.potion_count += 1
		## 基础阈值上涨（不受修正影响）
		Current.score_heal_threshold += Current.score_heal_threshold_increase
		## 重新计算有效阈值（阈值已上涨）
		effective_threshold = Current.score_heal_threshold
	## 嗜血战意溢出封顶：血瓶已满时accumulated不超过effective_threshold
	if BuffSystem.is_buff_registered("blood_fury") and Current.potion_count >= Current.potion_max:
		if Current.score_heal_accumulated > effective_threshold:
			Current.score_heal_accumulated = effective_threshold

## 触发掉落奖励buff（跳过回合时也需要触发）
func _trigger_drop_bonus():
	if Current.dropped_dice_count <= 0:
		return
	var trigger_buffs = BuffSystem.get_buffs_by_tag("drop_bonus_trigger")
	for buff in trigger_buffs:
		await buff.process_buff()

func _pre_hero_turn_begin():
	## 绝境霸主免死检查：若拥有免死且未消耗，则HP=1不死亡
	if Current.player_hp <= 0 and Current.has_death_immunity and not Current.death_immunity_used:
		Current.death_immunity_used = true
		Current.player_hp = 1
		print("绝境霸主免死触发！HP恢复至1")
	## 判断失败：HP<=0时游戏结束
	if Current.player_hp <= 0:
		print("游戏失败")
		get_tree().paused = true
	## 兜底恢复回合按钮
	_set_turn_button_disabled(false)
	## 重置英雄状态
	for hero in Current.all_hero_array:
		hero.hero_state_machine.transition_to("idle")
	## 重新计算不可移动地块
	reset_astar_solid()
	## 重置已移动标记
	Current.is_moved = false
	## 重掷已攻击标记
	Current.is_attacked = false
	## 重置本回合移动格数
	Current.grids_moved_this_turn = 0
	## 撤回按钮重置为disabled（新回合开始时）
	if has_node("coin_skill_trun_button/HBoxContainer/undo_move_button"):
		var undo_button = get_node("coin_skill_trun_button/HBoxContainer/undo_move_button")
		undo_button.disabled = true
		if undo_button.has_node("undo_move_button_label"):
			undo_button.get_node("undo_move_button_label").modulate = Color(1.0, 1.0, 1.0, 0.302)
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
func _check_stage_clear() -> bool:
	if Current.total_score >= Current.target_score:
		## 回合固定金币
		var stage_add_coin = 1
		Current.count_add_coins += stage_add_coin
		## 显示剩余HP奖励的金币（1点HP = 1金币）
		var hp_add_coin = Current.player_hp
		Current.count_add_coins += hp_add_coin
		#var add_coin := 0
		#for i in range(10 - Current.count_round):
			#add_coin += 1
			#stage_coin_label_2.text = str(add_coin)
			#await Tools.time_sleep(0.1)
		## 过关时最高子数金币数组
		var highest_dice_add_coin = Current.highest_dice_num - 1
		Current.count_add_coins += highest_dice_add_coin
		await _do_stage_clear_effect(stage_add_coin, hp_add_coin, highest_dice_add_coin)
		## 以战养战：过关时floor(残余史莱姆/3)HP（阶梯式）
		if BuffSystem.is_buff_registered("sustain"):
			var sustain_slime_count = 0
			for _slime in Current.all_enemy_array:
				if is_instance_valid(_slime):
					sustain_slime_count += 1
			if sustain_slime_count > 0:
				var sustain_heal = floori(sustain_slime_count / 3.0)
				if sustain_heal > 0:
					Current.player_hp = mini(Current.player_hp + sustain_heal, Current.max_hp)
					if has_node("round_process_bar/hp_bar"):
						var hp_bar = get_node("round_process_bar/hp_bar")
						if hp_bar.has_method("play_heal_effect"):
							hp_bar.play_heal_effect()
		## 生机霸主：vitality系≥4时激活，过关时hp+1；若满血则max_hp+1
		if BuffSystem.get_family_count("vitality") >= 4:
			if Current.player_hp < Current.max_hp:
				Current.player_hp += 1
			else:
				Current.max_hp += 1
				Current.player_hp = Current.max_hp
			# 同族图标联动闪烁
			var family_buffs = BuffSystem.get_family_buffs("vitality")
			for fb in family_buffs:
				if fb.buff_texture:
					EffectManager.buff_pop_effect(fb.buff_texture)
		## 清理关卡buff
		EventBus.event_emit("clear_stage_buff")
		return true
	return false

func _do_stage_clear_effect(stage_add_coin, hp_add_coin, highest_dice_add_coin):
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
	await EffectManager.label_num_rolling_effect(stage_coin_label_2, hp_add_coin)
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
		stage_add_coin + hp_add_coin + highest_dice_add_coin
		)
	stage_clear_button.disabled = false
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
	return maxi(roundi(modified_value), 0)

## 应用卡牌效果（支持多效果链）
func _apply_card_effect(effect: Dictionary):
	var target = effect["target"]
	var operate = effect["operate"]
	var value = effect["value"]
	## 所有点数基础分名称数组
	var score_names = ["one_score", "two_score", "three_score", "four_score", "five_score", "six_score"]
	## 所有倍率名称数组
	var percent_names = ["duizi_percent", "shunzi_percent", "tongse_percent", "tongdui_percent", "tongshun_percent"]
	## 处理特殊target
	match target:
		"all_score":
			## 对所有点数基础分执行操作
			for score_name in score_names:
				var current_val = Current.get(score_name)
				Current.set(score_name, _modifiy_value(current_val, operate, value))
			return
		"all_percent":
			## 对所有倍率执行操作
			for percent_name in percent_names:
				var current_val = Current.get(percent_name)
				var new_val = _modifiy_value(current_val, operate, value)
				Current.set(percent_name, new_val)
				_update_multiplier_dict(percent_name, operate, value)
			return
		"random_score":
			## 随机选择一个点数
			var random_name = score_names[randi_range(0, 5)]
			if operate == "set":
				Current.set(random_name, maxi(int(value), 0))
			elif operate == "set_to_avg":
				var avg = _get_score_average()
				Current.set(random_name, maxi(avg, 0))
			else:
				var current_val = Current.get(random_name)
				Current.set(random_name, _modifiy_value(current_val, operate, value))
			return
		"min_score":
			## 最低点数
			var min_name = _get_min_score_name()
			if operate == "set_to_max":
				var max_val = _get_max_score_value()
				Current.set(min_name, maxi(max_val, 0))
			else:
				var current_val = Current.get(min_name)
				Current.set(min_name, _modifiy_value(current_val, operate, value))
			return
		"max_score":
			## 最高点数
			var max_name = _get_max_score_name()
			if operate == "swap":
				## 交换最高和最低点数
				var min_name = _get_min_score_name()
				var max_val = Current.get(max_name)
				var min_val = Current.get(min_name)
				Current.set(max_name, maxi(min_val, 0))
				Current.set(min_name, maxi(max_val, 0))
			else:
				var current_val = Current.get(max_name)
				Current.set(max_name, _modifiy_value(current_val, operate, value))
			return
	## 处理普通target
	if operate == "swap":
		## 交换两个属性的值
		var from_name = value
		var target_val = Current.get(target)
		var from_val = Current.get(from_name)
		Current.set(target, maxi(from_val, 0))
		Current.set(from_name, target_val)
	elif operate == "copy_from":
		## 将来源属性的值复制到目标
		var from_name = value
		var from_val = Current.get(from_name)
		Current.set(target, maxi(from_val, 0))
	elif operate == "set_to_max":
		## 将目标设为所有点数中的最大值
		var max_val = _get_max_score_value()
		Current.set(target, maxi(max_val, 0))
	elif operate == "set_to_avg":
		## 将目标设为所有点数的平均值
		var avg = _get_score_average()
		Current.set(target, avg)
	elif operate == "set":
		## 将目标设为指定值
		Current.set(target, maxi(int(value), 0))
	else:
		## add/sub/mul/div 操作
		var current_val = Current.get(target)
		var new_val = _modifiy_value(current_val, operate, value)
		Current.set(target, new_val)
		## 如果是倍率属性，同步更新 dice_multiplier_dict
		if target.ends_with("_percent"):
			_update_multiplier_dict(target, operate, value)

## 同步更新 dice_multiplier_dict 中所有骰子数量的倍率值
func _update_multiplier_dict(percent_name: String, operate: String, value: float):
	var dict_key = percent_name.replace("_percent", "")
	for dice_sum in Current.dice_multiplier_dict.keys():
		var old_val = int(Current.dice_multiplier_dict[dice_sum][dict_key])
		var new_val = _modifiy_value(old_val, operate, value)
		Current.dice_multiplier_dict[dice_sum][dict_key] = new_val

## 获取所有点数基础分的平均值（四舍五入）
func _get_score_average() -> int:
	var total = Current.one_score + Current.two_score + Current.three_score + Current.four_score + Current.five_score + Current.six_score
	return roundi(total / 6.0)

## 获取值最大的点数名称
func _get_max_score_name() -> String:
	var scores = {"one_score": Current.one_score, "two_score": Current.two_score, "three_score": Current.three_score, "four_score": Current.four_score, "five_score": Current.five_score, "six_score": Current.six_score}
	var max_name = "one_score"
	var max_val = Current.one_score
	for name in scores:
		if scores[name] > max_val:
			max_val = scores[name]
			max_name = name
	return max_name

## 获取值最大的点数值
func _get_max_score_value() -> int:
	return max(Current.one_score, Current.two_score, Current.three_score, Current.four_score, Current.five_score, Current.six_score)

## 获取值最小的点数名称
func _get_min_score_name() -> String:
	var scores = {"one_score": Current.one_score, "two_score": Current.two_score, "three_score": Current.three_score, "four_score": Current.four_score, "five_score": Current.five_score, "six_score": Current.six_score}
	var min_name = "one_score"
	var min_val = Current.one_score
	for name in scores:
		if scores[name] < min_val:
			min_val = scores[name]
			min_name = name
	return min_name

func _on_skill_system_hide_all_skill() -> void:
	hero_skill_ui.hide_all_skills()

func _on_card_1_button_pressed() -> void:
	## 遍历卡牌效果列表，逐一应用
	for effect in level_up_three_card_array[0]["card_effects"]:
		_apply_card_effect(effect)
	get_tree().paused = false
	level_up_ui.hide()
	Current.public_lock_array.erase("level_up_ui")

func _on_card_2_button_pressed() -> void:
	## 遍历卡牌效果列表，逐一应用
	for effect in level_up_three_card_array[1]["card_effects"]:
		_apply_card_effect(effect)
	get_tree().paused = false
	level_up_ui.hide()
	Current.public_lock_array.erase("level_up_ui")

func _on_card_3_button_pressed() -> void:
	## 遍历卡牌效果列表，逐一应用
	for effect in level_up_three_card_array[2]["card_effects"]:
		_apply_card_effect(effect)
	get_tree().paused = false
	level_up_ui.hide()
	Current.public_lock_array.erase("level_up_ui")

func _hide_all_clear_stage_ui():
	clear_stage_label.hide()
	stage_clear_label_1.hide()
	stage_coin_rlabel_1.hide()
	stage_coin_label_1.hide()
	stage_coin_label_1.text = ""
	stage_clear_label_2.hide()
	stage_coin_rlabel_2.hide()
	stage_coin_label_2.hide()
	stage_coin_label_2.text = ""
	stage_clear_label_3.hide()
	stage_coin_rlabel_3.hide()
	stage_coin_label_3.hide()
	stage_coin_label_3.text = ""
	stage_coin_rlabel_4.hide()
	stage_coin_label_4.hide()
	stage_coin_label_4.text = ""
	stage_clear_button.hide()
	clear_stage_ui.hide()

func _set_shop_buff():
	## 显示商品
	buff_shop_icon_1.modulate.a = 1
	buff_shop_icon_2.modulate.a = 1
	buff_shop_icon_3.modulate.a = 1
	var _shop_pool = buff_json_data.filter(func(row): return not row.get("auto_activate", false))
	## 锁定buff从池中排除，避免重复出现（已购槽位除外，已购buff已被从buff_json_data移除）
	if buff_lock_button_1.button_pressed == true and shop_buff_bought[0] == false:
		_shop_pool.erase(shop_buff_1)
	if buff_lock_button_2.button_pressed == true and shop_buff_bought[1] == false:
		_shop_pool.erase(shop_buff_2)
	if buff_lock_button_3.button_pressed == true and shop_buff_bought[2] == false:
		_shop_pool.erase(shop_buff_3)
	## 抽取buff：已购槽位无视锁定直接换新，未锁定正常抽取，锁定保留
	if shop_buff_bought[0] == true:
		shop_buff_bought[0] = false
		buff_shop_button_1.disabled = false
		buff_lock_button_1.disabled = false
		shop_buff_1 = _shop_pool.pick_random()
		_shop_pool.erase(shop_buff_1)
	elif buff_lock_button_1.button_pressed == false:
		shop_buff_1 = _shop_pool.pick_random()
		_shop_pool.erase(shop_buff_1)
	if shop_buff_bought[1] == true:
		shop_buff_bought[1] = false
		buff_shop_button_2.disabled = false
		buff_lock_button_2.disabled = false
		shop_buff_2 = _shop_pool.pick_random()
		_shop_pool.erase(shop_buff_2)
	elif buff_lock_button_2.button_pressed == false:
		shop_buff_2 = _shop_pool.pick_random()
		_shop_pool.erase(shop_buff_2)
	if shop_buff_bought[2] == true:
		shop_buff_bought[2] = false
		buff_shop_button_3.disabled = false
		buff_lock_button_3.disabled = false
		shop_buff_3 = _shop_pool.pick_random()
		_shop_pool.erase(shop_buff_3)
	elif buff_lock_button_3.button_pressed == false:
		shop_buff_3 = _shop_pool.pick_random()
	## 没有锁buff的加回数组
	if buff_lock_button_1.button_pressed == false:
		_shop_pool.append(shop_buff_1)
	if buff_lock_button_2.button_pressed == false:
		_shop_pool.append(shop_buff_2)
	buff_shop_icon_1.texture = load(shop_buff_1["buff_icon"])
	buff_shop_icon_2.texture = load(shop_buff_2["buff_icon"])
	buff_shop_icon_3.texture = load(shop_buff_3["buff_icon"])
	TooltipManager.set_tooltip(buff_shop_icon_1, TooltipFormatter.format_buff(shop_buff_1))
	TooltipManager.set_tooltip(buff_shop_icon_2, TooltipFormatter.format_buff(shop_buff_2))
	TooltipManager.set_tooltip(buff_shop_icon_3, TooltipFormatter.format_buff(shop_buff_3))
	buff_shop_rlabel_1.text = "[img=13 ]res://images/coin.png[/img] " + \
		str(maxi(0, int(shop_buff_1["buff_price"]) - Current.buff_price_discount))
	buff_shop_rlabel_2.text = "[img=13 ]res://images/coin.png[/img] " + \
		str(maxi(0, int(shop_buff_2["buff_price"]) - Current.buff_price_discount))
	buff_shop_rlabel_3.text = "[img=13 ]res://images/coin.png[/img] " + \
		str(maxi(0, int(shop_buff_3["buff_price"]) - Current.buff_price_discount))
	## 刷新按钮状态
	Current.total_coins = Current.total_coins

## 设置商店金币技能（每关随机1个技能展示在商店）
func _set_shop_coin_skill():
	## 从尚未出现过的金币技能中随机抽取1个（所有技能概率相同，不重复）
	var available_skills: Array = []
	for row in coin_skill_json_data:
		if row["coin_skill_id"] not in appeared_coin_skill_ids:
			available_skills.append(row)
	## 如果所有技能都已出现过，重置出现记录
	if available_skills.is_empty():
		appeared_coin_skill_ids.clear()
		available_skills = coin_skill_json_data.duplicate()
	shop_coin_skill_row = available_skills.pick_random()
	appeared_coin_skill_ids.append(shop_coin_skill_row["coin_skill_id"])
	## 设置商店技能图标
	shop_coin_skill_icon.texture = load(shop_coin_skill_row["coin_skill_icon"])
	TooltipManager.set_tooltip(shop_coin_skill_icon, TooltipFormatter.format_coin_skill(shop_coin_skill_row))
	## 设置商店技能价格标签
	shop_coin_skill_rlabel.text = "[img=13 ]res://images/coin.png[/img] " + str(int(shop_coin_skill_row["coin_skill_shop_cost"]))
	## 重置购买标记
	shop_coin_skill_bought = false
	## 根据金币是否足够设置按钮状态
	if Current.total_coins < int(shop_coin_skill_row["coin_skill_shop_cost"]):
		shop_coin_skill_button.disabled = true
		shop_coin_skill_button.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		shop_coin_skill_button.disabled = false
		shop_coin_skill_button.modulate = Color(1, 1, 1, 1)
	shop_coin_skill_icon.modulate.a = 1

## 商店金币技能购买按钮按下
func _on_shop_coin_skill_button_pressed() -> void:
	## 判断金币是否足够
	if Current.total_coins < int(shop_coin_skill_row["coin_skill_shop_cost"]):
		return
	## 扣除金币
	Current.total_coins -= int(shop_coin_skill_row["coin_skill_shop_cost"])
	## 标记已购买
	shop_coin_skill_bought = true
	## 禁用商店技能购买按钮，防止重复购买
	shop_coin_skill_button.disabled = true
	shop_coin_skill_icon.modulate.a = 0.3
	## 判断技能栏是否已满（3个技能）
	if Current.coin_skill_array_dict.size() >= 3:
		## 技能栏已满，保存待处理技能，显示替换选择UI
		pending_shop_skill = shop_coin_skill_row
		_show_replace_skill_ui()
	else:
		## 技能栏未满，直接添加技能
		_set_coin_skill(shop_coin_skill_row)

## 显示技能替换选择UI
func _show_replace_skill_ui():
	## 设置3个已有技能的图标和tooltip
	replace_skill_1_icon.texture = load(Current.coin_skill_array_dict[0]["coin_skill_icon"])
	TooltipManager.set_tooltip(replace_skill_1, TooltipFormatter.format_coin_skill(Current.coin_skill_array_dict[0]))
	replace_skill_2_icon.texture = load(Current.coin_skill_array_dict[1]["coin_skill_icon"])
	TooltipManager.set_tooltip(replace_skill_2, TooltipFormatter.format_coin_skill(Current.coin_skill_array_dict[1]))
	replace_skill_3_icon.texture = load(Current.coin_skill_array_dict[2]["coin_skill_icon"])
	TooltipManager.set_tooltip(replace_skill_3, TooltipFormatter.format_coin_skill(Current.coin_skill_array_dict[2]))
	## 显示替换UI
	replace_skill_ui.show()

## 替换技能1按钮按下
func _on_replace_skill_1_pressed() -> void:
	## 替换第1个技能槽位
	_replace_coin_skill(0, pending_shop_skill)
	## 关闭替换UI
	replace_skill_ui.hide()
	## 禁用已购买的商店技能按钮
	shop_coin_skill_button.disabled = true
	shop_coin_skill_icon.modulate.a = 0.3

## 替换技能2按钮按下
func _on_replace_skill_2_pressed() -> void:
	## 替换第2个技能槽位
	_replace_coin_skill(1, pending_shop_skill)
	## 关闭替换UI
	replace_skill_ui.hide()
	## 禁用已购买的商店技能按钮
	shop_coin_skill_button.disabled = true
	shop_coin_skill_icon.modulate.a = 0.3

## 替换技能3按钮按下
func _on_replace_skill_3_pressed() -> void:
	## 替换第3个技能槽位
	_replace_coin_skill(2, pending_shop_skill)
	## 关闭替换UI
	replace_skill_ui.hide()
	## 禁用已购买的商店技能按钮
	shop_coin_skill_button.disabled = true
	shop_coin_skill_icon.modulate.a = 0.3

## 取消替换按钮按下
func _on_cancel_replace_button_pressed() -> void:
	## 关闭替换UI，不替换，不退费
	replace_skill_ui.hide()

## 替换指定索引的金币技能
func _replace_coin_skill(index: int, new_skill_row: Dictionary):
	## 更新技能栏数据
	Current.coin_skill_array_dict[index] = new_skill_row
	## 重置该技能的本关使用状态为未使用
	Current.coin_skill_used[index] = false
	## 更新技能栏UI
	match index:
		0:
			coin_skill_1_icon.texture = load(new_skill_row["coin_skill_icon"])
			coin_skill_1_label.text = new_skill_row["coin_skill_name"]
			TooltipManager.set_tooltip(coin_skill_1, TooltipFormatter.format_coin_skill(new_skill_row))
			coin_skill_1.disabled = false
			coin_skill_1_icon.self_modulate = Color(1, 1, 1, 1)
		1:
			coin_skill_2_icon.texture = load(new_skill_row["coin_skill_icon"])
			coin_skill_2_label.text = new_skill_row["coin_skill_name"]
			TooltipManager.set_tooltip(coin_skill_2, TooltipFormatter.format_coin_skill(new_skill_row))
			coin_skill_2.disabled = false
			coin_skill_2_icon.self_modulate = Color(1, 1, 1, 1)
		2:
			coin_skill_3_icon.texture = load(new_skill_row["coin_skill_icon"])
			coin_skill_3_label.text = new_skill_row["coin_skill_name"]
			TooltipManager.set_tooltip(coin_skill_3, TooltipFormatter.format_coin_skill(new_skill_row))
			coin_skill_3.disabled = false
			coin_skill_3_icon.self_modulate = Color(1, 1, 1, 1)
	## 清空待处理技能
	pending_shop_skill = {}

func _on_stage_clear_button_pressed() -> void:
	stage_clear_button.hide()
	stage_clear_button.disabled = true
	## 加锁：防止 _turn_process 在关卡切换完成前执行
	Current.public_lock_array.append("stage_transition")
	## 增加金币
	Current.total_coins += Current.count_add_coins
	## 黄金之手：委托调用 buff 实例的 process_stage_clear()
	if BuffSystem.is_buff_registered("golden_touch"):
		var inst = BuffSystem.get_buff_instance("golden_touch")
		if inst:
			await inst.process_stage_clear()
	## 更新回合、关卡、当前分数、目标分数
	Current.count_round = 0
	Current.total_score = 0
	Current.drop_slot_dice = null
	if Current.count_stage < 12:
		Current.count_stage += 1
		## 重置所有金币技能本关使用状态为未使用
		Current.coin_skill_used = []
		for i in range(Current.coin_skill_array_dict.size()):
			Current.coin_skill_used.append(false)
		## 重置后刷新技能按钮状态
		Current.refresh_coin_skill_buttons()
	else:
		## 游戏胜利
		print("胜利")
	## 隐藏结算显示内容
	_hide_all_clear_stage_ui()
	## 设置商店buff和价格UI
	_set_shop_buff()
	## 设置商店金币技能
	_set_shop_coin_skill()
	## 商店
	get_tree().paused = true
	Current.public_lock_array.append("shop_ui")
	shop_ui.show()
	## 商店UI效果
	await EffectManager.top_to_bottom_effect(shop_texture_ui, 0.5)

	## 等待商店关闭
	while "shop_ui" in Current.public_lock_array:
		await Tools.time_sleep(0.1)
	## 从配置中查找当前关卡数据（共享查找结果，避免重复遍历）
	var current_stage_info: Dictionary = {}
	for row in stage_info_json_data:
		if row["stage_num"] == Current.count_stage:
			current_stage_info = row
			break
	Current.target_score = current_stage_info.get("target_score", 300)
	difficulty_icon.texture = load(current_stage_info.get("stage_type_icon", "res://images/enemy_icon/normal.png"))
	TooltipManager.set_tooltip(difficulty_icon, "[b]" + current_stage_info.get("stage_type", "普通") + "[/b]")
	## 清空一关金币奖励数和最高骰子奖励数
	Current.count_add_coins = 0
	Current.highest_dice_num = 1
	get_tree().paused = false
	## 等待升级选卡
	while "level_up_ui" in Current.public_lock_array:
		await Tools.time_sleep(0.1)
	## 清空上一关残留的史莱姆和预生成告警
	await _clear_all_slimes()
	## 重置史莱姆生成数量为基础值（防止上一关8-10回合的翻倍值残留）
	Current.slime_create_num = 3
	Current.slime_tide_pending = 0
	Current.swarm_call_pending = 0
	## 为新关卡第一回合预生成史莱姆（设置warning告警）
	_pre_create_slime()
	## 关卡切换效果
	await EffectManager.stage_change_effect()
	## 根据关卡配置的stage_type判断生成精英或BOSS（缺失时默认为"普通"）
	var stage_type: String = current_stage_info.get("stage_type", "普通")
	if stage_type == "精英":
		await _spawn_elite_slime()
	elif stage_type == "BOSS":
		await _spawn_boss_slime(current_stage_info)
	## 解锁：关卡切换完成，允许 _turn_process 执行
	Current.public_lock_array.erase("stage_transition")

## 血瓶按钮按下：使用1个血瓶恢复1HP（霸主+2HP）
func _on_potion_button_pressed() -> void:
	if Current.potion_count <= 0 or Current.player_hp >= Current.max_hp:
		return
	var heal_amount := 1
	## 逆境翻盘：HP=1时血瓶恢复量+1
	if BuffSystem.is_buff_registered("comeback_king") and Current.player_hp == 1:
		heal_amount = 2
	Current.potion_count -= 1
	Current.player_hp += heal_amount
	## 回血视觉反馈
	if has_node("round_process_bar/hp_bar"):
		var hp_bar = get_node("round_process_bar/hp_bar")
		if hp_bar.has_method("play_heal_effect"):
			hp_bar.play_heal_effect()
	## 使用血瓶后立即检查储备触发（血瓶满时accumulated保留在阈值以上，用掉后应立即获得新血瓶）
	_apply_score_heal()

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

func _on_cancel_dice_adjust_button_pressed() -> void:
	EventBus.event_emit("reset_cursor")
	coin_skill_system._dice_adjust_target = null
	dice_adjust_ui.hide()
	get_tree().paused = false

func _on_dice_add_button_pressed() -> void:
	## ▲+1：点数+1（6→1循环），技能消耗，面板关闭
	dice_adjust_ui.hide()
	get_tree().paused = false
	var _target_slime = coin_skill_system._dice_adjust_target
	if _target_slime and is_instance_valid(_target_slime):
		var _old_dice_point = _target_slime.dice_point
		var _new_dice_point = 1 if _old_dice_point == 6 else _old_dice_point + 1
		_target_slime.dice.set_frame_and_progress(_target_slime.dice_to_frame_dice[_new_dice_point], 0)
		EventBus.event_emit("dice_adjust_apply", ["dice_adjust", _target_slime])

func _on_dice_sub_button_pressed() -> void:
	## ▼-1：点数-1（1→6循环），技能消耗，面板关闭
	dice_adjust_ui.hide()
	get_tree().paused = false
	var _target_slime = coin_skill_system._dice_adjust_target
	if _target_slime and is_instance_valid(_target_slime):
		var _old_dice_point = _target_slime.dice_point
		var _new_dice_point = 6 if _old_dice_point == 1 else _old_dice_point - 1
		_target_slime.dice.set_frame_and_progress(_target_slime.dice_to_frame_dice[_new_dice_point], 0)
		EventBus.event_emit("dice_adjust_apply", ["dice_adjust", _target_slime])

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

## 设置技能到技能栏
func _set_coin_skill(coin_skill_row):
	match Current.coin_skill_array_dict.size():
		0:
			Current.coin_skill_array_dict.append(coin_skill_row)
			Current.coin_skill_used.append(false)
			coin_skill_1_icon.texture = load(coin_skill_row["coin_skill_icon"])
			coin_skill_1_label.text = coin_skill_row["coin_skill_name"]
			TooltipManager.set_tooltip(coin_skill_1, TooltipFormatter.format_coin_skill(coin_skill_row))
		1:
			Current.coin_skill_array_dict.append(coin_skill_row)
			Current.coin_skill_used.append(false)
			coin_skill_2_icon.texture = load(coin_skill_row["coin_skill_icon"])
			coin_skill_2_label.text = coin_skill_row["coin_skill_name"]
			TooltipManager.set_tooltip(coin_skill_2, TooltipFormatter.format_coin_skill(coin_skill_row))
		2:
			Current.coin_skill_array_dict.append(coin_skill_row)
			Current.coin_skill_used.append(false)
			coin_skill_3_icon.texture = load(coin_skill_row["coin_skill_icon"])
			coin_skill_3_label.text = coin_skill_row["coin_skill_name"]
			TooltipManager.set_tooltip(coin_skill_3, TooltipFormatter.format_coin_skill(coin_skill_row))
	## 添加技能后刷新按钮状态
	Current.refresh_coin_skill_buttons()

func _on_buff_refresh_button_pressed() -> void:
	if Current.zero_coin_refresh_times > 0:
		Current.zero_coin_refresh_times -= 1
		buff_refresh_cost = buff_refresh_cost
		_set_shop_buff()
		Current.total_coins = Current.total_coins
	else:
		## 扣除刷新费用
		Current.total_coins -= buff_refresh_cost
		## 刷新费用增长
		buff_refresh_cost += 1
		## 复制触发修改按钮状态
		Current.total_coins = Current.total_coins
		_set_shop_buff()

## 战场补给：购买buff后获得1血瓶（不超过上限）
func _apply_war_supply_heal() -> void:
	if not BuffSystem.is_buff_registered("war_supply"):
		return
	if Current.potion_count < Current.potion_max:
		Current.potion_count += 1

func _on_buff_shop_button_1_pressed() -> void:
	var _actual_price = maxi(0, shop_buff_1["buff_price"] - Current.buff_price_discount)
	if Current.total_coins < _actual_price:
		return
	shop_buff_bought[0] = true
	Current.total_coins -= _actual_price
	Current.buff_price_discount = 0
	_set_buff(shop_buff_1)
	_apply_war_supply_heal()
	buff_shop_icon_1.modulate.a = 0
	buff_lock_button_1.button_pressed = false
	buff_shop_button_1.disabled = true
	buff_lock_button_1.disabled = true
	buff_json_data.erase(shop_buff_1)

func _on_buff_shop_button_2_pressed() -> void:
	var _actual_price = maxi(0, shop_buff_2["buff_price"] - Current.buff_price_discount)
	if Current.total_coins < _actual_price:
		return
	shop_buff_bought[1] = true
	Current.total_coins -= _actual_price
	Current.buff_price_discount = 0
	_set_buff(shop_buff_2)
	_apply_war_supply_heal()
	buff_shop_icon_2.modulate.a = 0
	buff_lock_button_2.button_pressed = false
	buff_shop_button_2.disabled = true
	buff_lock_button_2.disabled = true
	buff_json_data.erase(shop_buff_2)

func _on_buff_shop_button_3_pressed() -> void:
	var _actual_price = maxi(0, shop_buff_3["buff_price"] - Current.buff_price_discount)
	if Current.total_coins < _actual_price:
		return
	shop_buff_bought[2] = true
	Current.total_coins -= _actual_price
	Current.buff_price_discount = 0
	_set_buff(shop_buff_3)
	_apply_war_supply_heal()
	buff_shop_icon_3.modulate.a = 0
	buff_lock_button_3.button_pressed = false
	buff_shop_button_3.disabled = true
	buff_lock_button_3.disabled = true
	buff_json_data.erase(shop_buff_3)

func _on_shop_next_level_button_pressed() -> void:
	## 先恢复免费刷新次数（必须在重置cost之前，否则setter触发时times仍为0导致UI显示错误）
	Current.zero_coin_refresh_times = Current.zero_coin_refresh_max_times
	## 重置刷新buff的金币费用
	buff_refresh_cost = 1
	get_tree().paused = false
	shop_ui.hide()
	Current.public_lock_array.erase("shop_ui")
