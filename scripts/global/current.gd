extends Node
# 鼠标指向的英雄
var hero: Hero
# 鼠标点击英雄
var clicked_hero: Hero
# 选中的图块索引
var grid_index: Vector2i
# 包含所有英雄字典
var all_hero_dict: Dictionary
# 包含所有英雄位置的数组
@onready var all_hero_grid_index_array: Array:
	get:
		var grid_index_array: Array
		for hero_name in all_hero_dict:
			grid_index_array.append(all_hero_dict[hero_name].hero_grid_index)
		return grid_index_array
# 包含所有史莱姆的字典
var all_enemy_array: Array
# 包含所有敌人位置的数组
@onready var enemy_grid_index_array: Array:
	get:
		var grid_index_array: Array
		for enemy in all_enemy_array:
			grid_index_array.append(enemy.enemy_grid_index)
		return grid_index_array
# 前可移动的数组
var movable_grid_index_array: Array
# 当前是移动态英雄
var move_state_hero: Hero:
	get:
		for hero_name in all_hero_dict:
			if all_hero_dict[hero_name].hero_state_machine.state == all_hero_dict[hero_name].hero_state_machine.get_node("move"):
				return all_hero_dict[hero_name]
		return null
# Astar计算路径
var id_path: Array
# 史莱姆巢穴的数组
var enemy_home_array: Array
# 敌我回合
var turn: String
# 可生成史莱姆的巢穴
var available_enemy_home: Array:
	get:
		var available_array: Array
		for grid_index in enemy_home_array:
			if not enemy_grid_index_array.has(grid_index):
				available_array.append(grid_index)
		return available_array

	
