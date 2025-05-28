extends Node
# game_manager节点
@onready var game_manager: Node2D = get_node("/root/game_manager")
# 鼠标指向的英雄
var hero: Hero
# 鼠标点击英雄
var clicked_hero: Hero
# 选中的图块索引
var grid_index: Vector2i
# 包含所有英雄字典
var all_hero_dict: Dictionary
## 包含所有英雄的数组:
var all_hero_array: Array:
	get:
		return $"/root/game_manager/heros".get_children()
# 包含所有英雄位置的数组
#@onready var all_hero_grid_index_array: Array:
	#get:
		#var grid_index_array: Array
		#for hero_name in all_hero_dict:
			#grid_index_array.append(all_hero_dict[hero_name].hero_grid_index)
		#return grid_index_array
@onready var all_hero_grid_index_array: Array:
	get:
		var grid_index_array: Array
		for hero in all_hero_array:
			grid_index_array.append(hero.hero_grid_index)
		return grid_index_array
# 包含所有史莱姆的字典
var all_enemy_array: Array:
	get:
		return $"/root/game_manager/enemys".get_children()
# 包含所有敌人位置的数组
@onready var all_enemy_grid_index_array: Array:
	get:
		var grid_index_array: Array
		for enemy in all_enemy_array:
			grid_index_array.append(enemy.enemy_grid_index)
		return grid_index_array
# 前可移动的数组
var movable_grid_index_array: Array
# 当前是移动状态英雄
var move_state_hero: Hero:
	get:
		for hero in all_hero_array:
			if hero.hero_state_machine.state.name == "move":
				return hero
		return null
# Astar计算路径
var id_path: Array
# 史莱姆巢穴的数组
var enemy_home_array: Array
# 史莱姆巢穴图块位置的数组
var enemy_home_grid_index_array: Array:
	get:
		var grid_index_array: Array
		if enemy_home_array.size() > 0:
			for enemy_home in enemy_home_array:
				grid_index_array.append(enemy_home.enemy_home_grid_index)
		return grid_index_array
# 敌我回合
var turn: String = "hero_turn"
# 可生成史莱姆的巢穴
var available_enemy_home: Array:
	get:
		var available_array: Array
		for enemy_home in enemy_home_array:
			if not all_enemy_grid_index_array.has(enemy_home.enemy_home_grid_index):
				available_array.append(enemy_home)
		return available_array
# 正在移动的史莱姆
var has_move_slime: bool:
	get:
		for slime in all_enemy_array:
			if slime.target_position != Vector2.ZERO:
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
## 总分
var total_score: int:
	set(v):
		game_manager.total_score.text = "总分: " + str(v)
	get:
		return int(game_manager.total_score.text)
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
var none_percent: float:
	set(v):
		game_manager.none_percent.text = str(v) + "%"
	get:
		return float(game_manager.none_percent.text)
var duizi_percent: float:
	set(v):
		game_manager.duizi_percent.text = str(v) + "%"
	get:
		return float(game_manager.duizi_percent.text)
var shunzi_percent: float:
	set(v):
		game_manager.shunzi_percent.text = str(v) + "%"
	get:
		return float(game_manager.shunzi_percent.text)
var tongse_percent: float:
	set(v):
		game_manager.tongse_percent.text = str(v) + "%"
	get:
		return float(game_manager.tongse_percent.text)
var mirror_percent: float:
	set(v):
		game_manager.mirror_percent.text = str(v) + "%"
	get:
		return float(game_manager.mirror_percent.text)
var point_percent: float:
	set(v):
		game_manager.point_percent.text = str(v) + "%"
	get:
		return float(game_manager.point_percent.text)
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
			game_manager.percent_score.text = str(v) + "%"
		else:
			game_manager.percent_score.text = ''
	get:
		return int(game_manager.percent_score.text)
## 单次骰型的分数
var dice_type_point: int
## 攻击动画是否完成
var attack_animation_finished = 1
