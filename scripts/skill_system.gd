extends Node2D
@onready var game_manager: Node2D = $".."

var _skill_1_range: Array[Vector2i]
var _skill_2_range: Array[Vector2i]
var _skill_3_range: Array[Vector2i]

func show_skill_range(hero_name, skill_num):
	call("_show_" + hero_name + "_skill_" + skill_num + "_range")

func hide_skill_range(hero_name, skill_num):
	call("_hide_" + hero_name + "_skill_" + skill_num + "_range")

func show_skill_attack(hero_name, skill_num):
	call("_show_" + hero_name + "_skill_" + skill_num + "_attack")
	
func hide_skill_attack(hero_name, skill_num):
	call("_hide_" + hero_name + "_skill_" + skill_num + "_attack")
	
func _show_soldier_skill_1_range():
	var hero_grid_index = Current.clicked_hero.hero_grid_index
	for offset in game_manager.grid_offset:
		var target_grid_index
		target_grid_index = hero_grid_index + offset
		if target_grid_index in game_manager.all_grid_dict:
			_skill_1_range.append(target_grid_index)
			game_manager.all_grid_dict[target_grid_index].target.visible = true
			
func _hide_soldier_skill_1_range():
	for target_grid_index in game_manager.all_grid_dict:
		game_manager.all_grid_dict[target_grid_index].target.visible = false
		
func _show_soldier_skill_1_attack():
	for grid_index in _skill_1_range:
		## 鼠标选中格子等于技能格子,显示伤害范围
		if Current.grid_index == grid_index:
			print(Current.grid_index, grid_index)
			if grid_index.x == Current.clicked_hero.hero_grid_index.x:
				for attack_grid_index in \
				[grid_index + Vector2i(-1, 0), grid_index, grid_index + Vector2i(1, 0)]:
					game_manager.all_grid_dict[attack_grid_index].attack.visible = true
			if grid_index.y == Current.clicked_hero.hero_grid_index.y:
				for attack_grid_index in \
				[grid_index + Vector2i(0, -1), grid_index, grid_index + Vector2i(0, 1)]:
					game_manager.all_grid_dict[attack_grid_index].attack.visible = true
					
func _hide_soldier_skill_1_attack():
	for attack_grid_index in game_manager.all_grid_dict:
		game_manager.all_grid_dict[attack_grid_index].attack.visible = false
	
	
