extends Node2D
@onready var game_manager: Node2D = $".."

signal hide_all_skill

func show_skill_range(hero_name, skill_num):
	call("_show_" + hero_name + "_skill_" + skill_num + "_range")

func hide_skill_range():
	_hide_skill_range()
	_hide_skill_attack()

func show_skill_attack(hero_name, skill_num):
	call("_show_" + hero_name + "_skill_" + skill_num + "_attack")
	
func hide_skill_attack():
	_hide_skill_attack()
	
func skill_attack(hero_name, skill_num):
	call("_" + hero_name + "_skill_" + skill_num + "_attack")
	
func _show_soldier_skill_1_range():
	Current.skill_target_range = []
	var hero_grid_index = Current.clicked_hero.hero_grid_index
	for offset in game_manager.grid_offset:
		var target_grid_index
		target_grid_index = hero_grid_index + offset
		if target_grid_index in game_manager.all_grid_dict:
			game_manager.all_grid_dict[target_grid_index].target.visible = true
			Current.skill_target_range.append(target_grid_index)
	if Current.grid_index in Current.skill_target_range:
		_show_soldier_skill_1_attack()
		
			
func _hide_skill_range():
	for target_grid_index in game_manager.all_grid_dict:
		game_manager.all_grid_dict[target_grid_index].target.visible = false
		
func _show_soldier_skill_1_attack():
	Current.skill_attack_range = []
	for grid_index in Current.skill_target_range:
		## 鼠标选中格子等于技能格子,显示伤害范围
		if Current.grid_index == grid_index:
			if grid_index.x == Current.clicked_hero.hero_grid_index.x:
				for attack_grid_index in \
				[grid_index + Vector2i(-1, 0), grid_index, grid_index + Vector2i(1, 0)]:
					game_manager.all_grid_dict[attack_grid_index].attack.visible = true
					Current.skill_attack_range.append(attack_grid_index)
			if grid_index.y == Current.clicked_hero.hero_grid_index.y:
				for attack_grid_index in \
				[grid_index + Vector2i(0, -1), grid_index, grid_index + Vector2i(0, 1)]:
					game_manager.all_grid_dict[attack_grid_index].attack.visible = true
					Current.skill_attack_range.append(attack_grid_index)
					
func _hide_skill_attack():
	for attack_grid_index in game_manager.all_grid_dict:
		game_manager.all_grid_dict[attack_grid_index].attack.visible = false
	
func _soldier_skill_1_attack():
	var _slime_die_array: Array
	for slime in Current.all_enemy_array:
		if slime.enemy_grid_index in Current.skill_attack_range:
			slime.animated_sprite_2d.play("die")
			hide_all_skill.emit()
