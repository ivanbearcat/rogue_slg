extends Node
## game_manager节点
@onready var game_manager: Node2D = get_node("/root/game_manager")
## 鼠标指向的英雄
var hero: Hero
## 鼠标指向的史莱姆
var slime: Slime
## 鼠标点击英雄
var clicked_hero: Hero
## 选中的图块索引
var grid_index: Vector2i
## 包含所有英雄字典
var all_hero_dict: Dictionary
## 包含所有英雄的数组:
var all_hero_array: Array:
	get:
		return $"/root/game_manager/heros".get_children()
## 包含所有英雄位置的数组
@onready var all_hero_grid_index_array: Array:
	get:
		var grid_index_array: Array
		for _hero in all_hero_array:
			grid_index_array.append(_hero.hero_grid_index)
		return grid_index_array
## 包含所有史莱姆的字典
var all_enemy_array: Array:
	get:
		return $"/root/game_manager/enemys".get_children()
## 包含所有敌人格子的数组
@onready var all_enemy_grid_index_array: Array:
	get:
		var grid_index_array: Array
		for enemy in all_enemy_array:
			grid_index_array.append(enemy.enemy_grid_index)
		return grid_index_array
## 包含所有敌人位置的数组
@onready var all_enemy_position_array: Array:
	get:
		var position_array: Array
		for enemy in all_enemy_array:
			position_array.append(enemy.position)
		return position_array
## 当前可移动的数组
var movable_grid_index_array: Array
## 当前是移动状态英雄
var move_state_hero: Hero:
	get:
		for _hero in all_hero_array:
			if _hero.hero_state_machine.state.name == "move":
				return hero
		return null
## Astar计算的移动路径
var id_path: Array
## 敌我回合
var turn: String = "hero_turn"
## 正在移动的史莱姆
var has_move_slime: bool:
	get:
		for _slime in all_enemy_array:
			if _slime.target_position != Vector2.ZERO:
				return true
		return false
## 是否移动过
var is_moved: bool
## 选中的技能编号
var skill_num: String
## 技能选择范围
var skill_target_range: Array
## 技能伤害范围
var skill_attack_range: Array
## 将要变化的史莱姆列表
var transformable_slime_array: Array
## 目标分数
var target_score: int:
	set(v):
		game_manager.target_score.text = str(v)
	get:
		return int(game_manager.target_score.text)
## 当前总分
var total_score: int:
	set(v):
		game_manager.total_score.text = str(v)
	get:
		return int(game_manager.total_score.text)
## 当前关卡
var count_stage := 1:
	set(v):
		count_stage = v
		game_manager.stage_label.text = "关卡" + Tools.num_to_cnnum[v]
		game_manager.clear_stage_label.text = "关卡" + Tools.num_to_cnnum[v]
	get:
		return count_stage
## 关卡奖励金币数
var count_add_coins := 0
## 金币总数
var total_coins: int:
	set(v):
		total_coins = v
		game_manager.total_coins_label.text = str(v)
		if v == 0:
			game_manager.reroll_button.disabled = true
			game_manager.coin_skill_1.disabled = true
			game_manager.coin_skill_2.disabled = true
			game_manager.coin_skill_3.disabled = true
			game_manager.reroll_button_label.modulate = Color(1, 1, 1, 0.3)
			game_manager.coin_skill_1_icon.self_modulate = Color(1, 1, 1, 0.3)
			game_manager.coin_skill_2_icon.self_modulate = Color(1, 1, 1, 0.3)
			game_manager.coin_skill_3_icon.self_modulate = Color(1, 1, 1, 0.3)
			game_manager.coin_skill_1_label.self_modulate = Color(1, 1, 1, 0.3)
			game_manager.coin_skill_2_label.self_modulate = Color(1, 1, 1, 0.3)
			game_manager.coin_skill_3_label.self_modulate = Color(1, 1, 1, 0.3)
		else:
			game_manager.reroll_button.disabled = false
			game_manager.coin_skill_1.disabled = false
			game_manager.coin_skill_2.disabled = false
			game_manager.coin_skill_3.disabled = false
			game_manager.reroll_button_label.modulate = Color(1, 1, 1, 1)
			game_manager.coin_skill_1_icon.self_modulate = Color(1, 1, 1, 1)
			game_manager.coin_skill_2_icon.self_modulate = Color(1, 1, 1, 1)
			game_manager.coin_skill_3_icon.self_modulate = Color(1, 1, 1, 1)
			game_manager.coin_skill_1_label.self_modulate = Color(1, 1, 1, 1)
			game_manager.coin_skill_2_label.self_modulate = Color(1, 1, 1, 1)
			game_manager.coin_skill_3_label.self_modulate = Color(1, 1, 1, 1)
## 回合计数
var count_round := 0:
	set(v):
		count_round = v
		if v == 0 or v == 1:
			game_manager.ship.position = Vector2(4, 2)
		if v > 1 and v < 11:
			game_manager.ship.position = Vector2(4, 2) + ((v - 1) * Vector2(7, 0))
		if v < 11:
			game_manager.turn_label.text = "回合: " + str(v)
			game_manager.turn_coin_label.text = str(10 - v)
	get:
		#return int(game_manager.turn_label.text)
		return count_round
## 最高骰子数
var highest_dice_num := 0
## 骰型板基础分数
var one_score: int:
	set(v):
		game_manager.one_score.text = str(v)
	get:
		return int(game_manager.one_score.text)
var two_score: int:
	set(v):
		game_manager.two_score.text = str(v)
	get:
		return int(game_manager.two_score.text)
var three_score: int:
	set(v):
		game_manager.three_score.text = str(v)
	get:
		return int(game_manager.three_score.text)
var four_score: int:
	set(v):
		game_manager.four_score.text = str(v)
	get:
		return int(game_manager.four_score.text)
var five_score: int:
	set(v):
		game_manager.five_score.text = str(v)
	get:
		return int(game_manager.five_score.text)
var six_score: int:
	set(v):
		game_manager.six_score.text = str(v)
	get:
		return int(game_manager.six_score.text)
## 骰型板倍率
var none_percent: int:
	set(v):
		game_manager.none_percent.text = str(v) + "%"
	get:
		return float(game_manager.none_percent.text)
var duizi_percent: int:
	set(v):
		game_manager.duizi_percent.text = str(v) + "%"
	get:
		return float(game_manager.duizi_percent.text)
var shunzi_percent: int:
	set(v):
		game_manager.shunzi_percent.text = str(v) + "%"
	get:
		return float(game_manager.shunzi_percent.text)
var tongse_percent: int:
	set(v):
		game_manager.tongse_percent.text = str(v) + "%"
	get:
		return float(game_manager.tongse_percent.text)
var tongdui_percent: int:
	set(v):
		game_manager.tongdui_percent.text = str(v) + "%"
	get:
		return float(game_manager.tongdui_percent.text)
var tongshun_percent: int:
	set(v):
		game_manager.tongshun_percent.text = str(v) + "%"
	get:
		return float(game_manager.tongshun_percent.text)
## 实时基础和倍率
var base_score: int:
	set(v):
		if v != 0:
			game_manager.base_score.text = str(v)	
		else:
			game_manager.base_score.text = ''
	get:
		return int(game_manager.base_score.text)
var percent_score: float:
	set(v):
		if v != 0:
			game_manager.percent_score.text = str(int(v)) + "%"
		else:
			game_manager.percent_score.text = ''
	get:
		return int(game_manager.percent_score.text)
## 单次骰型的分数
var dice_type_point: int
## 攻击动画是否完成
var attack_animation_finished = 1
## 能量史莱姆或强化技能编号
var power_slime
## 鼠标状态
var mouse_status := 'default'
## 重掷次数
#var reroll_times: int:
	#set(v):
		#game_manager.reroll_label.text = "重掷: " + str(v)
	#get:
		#return int(game_manager.reroll_label.text)
## 当前等级
var level: int:
	set(v):
		level = v
		game_manager.level_label.text = "Lv." + str(v)	
## 当前经验
var hero_exp := 0
## 升级需要的经验
var require_exp := 3
## 持续动作锁
var action_lock := false
## 最大能量
var max_power := 2
## 当前能量
var power: int:
	set(v):
		power = v
		game_manager.power_label.text = str(v) + "/" + str(Current.max_power)	
## 能量技能
var power_skill := 0
## 存在红框
var has_attack_grid := false
