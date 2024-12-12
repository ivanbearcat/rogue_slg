extends Node2D
@onready var game_manager: Node2D = $".."

func show_skill_range(hero_name, skill_num):
	call("show_" + hero_name + "_skill_" + skill_num + "_range")
	
func show_soldier_skill_1_range():
	var hero_grid_index = Current.clicked_hero.hero_grid_index
	for offset in game_manager.grid_offset:
		var target_grid_index
		target_grid_index = hero_grid_index + offset
		if target_grid_index in game_manager.all_grid_dict:
			game_manager.all_grid_dict[target_grid_index].target.visible = true
