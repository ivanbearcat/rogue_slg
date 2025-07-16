extends Node2D
@onready var game_manager: Node2D = $".."

signal hide_all_skill

func show_skill_range(hero_name, skill_num):
	call("_show_" + hero_name + "_skill_" + skill_num + "_range")

func hide_skill_range():
	for target_grid_index in game_manager.all_grid_dict:
		game_manager.all_grid_dict[target_grid_index].target.visible = false
	hide_skill_attack()

func show_skill_attack(hero_name, skill_num):
	call("_show_" + hero_name + "_skill_" + skill_num + "_attack")
	
func hide_skill_attack():
	for attack_grid_index in game_manager.all_grid_dict:
		game_manager.all_grid_dict[attack_grid_index].attack.visible = false
	_reset_dice_panel()

## 鼠标点击红框之后	
func skill_attack():
	## 正在攻击结算
	Current.doing_skill_attack = 1
	## 判断是能量技能则置空能量史莱姆变量，可以重新生成
	var reset_flag = false
	if not Current.power_slime is Slime:
		match Current.skill_num:
			"1":
				if Current.power_slime == 0:
					reset_flag = true
			"2":
				if Current.power_slime == 1:
					reset_flag = true
			"3":
				if Current.power_slime == 2:
					reset_flag = true
	## 史莱姆死亡
	var _slime_die_array: Array
	for slime in Current.all_enemy_array:
		if slime.enemy_grid_index in Current.skill_attack_range:
			slime.animated_sprite_2d.play("die")
	var dice_array = game_manager.dice_list.get_children()
	## 根据骰子数量条计算分数
	for index in range(dice_array.size() - 1, -1, -1):
		#print(index)
		if dice_array[index].get_self_modulate() == Color(1, 1, 1, 1):
			Tools.big_flow_effect(dice_array[index])
			if index == 1: continue
			var float_number_instantiate = SceneManager.create_scene("float_number")
			float_number_instantiate.float_num = Current.dice_type_point
			float_number_instantiate.velocity = Vector2(0, -10)
			dice_array[index].add_child(float_number_instantiate)
			await Tools.time_sleep(0.5)
			Current.total_score += Current.dice_type_point
	## 等待攻击动画完成
	while Current.attack_animation_finished == 0:
		await Tools.time_sleep(0.05)
	## 等动画播完执行能量史莱姆重置
	if reset_flag:
		Current.power_slime = null
		EventBus.event_emit("skill_power_reset")
	## 恢复技能UI弹起状态
	hide_all_skill.emit()
	Current.hero.hero_state_machine.transition_to("end")
	Current.doing_skill_attack = 0

	
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
		
func _show_soldier_skill_1_attack():
	Current.skill_attack_range = []
	if not Current.power_slime is Slime and Current.power_slime == 0:
		for grid_index in Current.skill_target_range:
			## 鼠标选中格子等于技能格子,显示伤害范围
			if Current.grid_index == grid_index:
				if grid_index.x == Current.clicked_hero.hero_grid_index.x:
					var offset = grid_index.y - Current.clicked_hero.hero_grid_index.y
					for attack_grid_index in \
					[grid_index + Vector2i(-1, 0),
					grid_index,
					grid_index + Vector2i(1, 0),
					grid_index + Vector2i(-1, offset),
					grid_index + Vector2i(0, offset),
					grid_index + Vector2i(1, offset)]:
						if attack_grid_index in game_manager.all_grid_dict:
							game_manager.all_grid_dict[attack_grid_index].attack.visible = true
							Current.skill_attack_range.append(attack_grid_index)
				if grid_index.y == Current.clicked_hero.hero_grid_index.y:
					var offset = grid_index.x - Current.clicked_hero.hero_grid_index.x
					for attack_grid_index in \
					[grid_index + Vector2i(0, -1),
					grid_index,
					grid_index + Vector2i(0, 1),
					grid_index + Vector2i(offset, -1),
					grid_index + Vector2i(offset, 0),
					grid_index + Vector2i(offset, 1)]:
						if attack_grid_index in game_manager.all_grid_dict:
							game_manager.all_grid_dict[attack_grid_index].attack.visible = true
							Current.skill_attack_range.append(attack_grid_index)
	else:
		for grid_index in Current.skill_target_range:
			## 鼠标选中格子等于技能格子,显示伤害范围
			if Current.grid_index == grid_index:
				if grid_index.x == Current.clicked_hero.hero_grid_index.x:
					for attack_grid_index in \
					[grid_index + Vector2i(-1, 0), grid_index, grid_index + Vector2i(1, 0)]:
						if attack_grid_index in game_manager.all_grid_dict:
							game_manager.all_grid_dict[attack_grid_index].attack.visible = true
							Current.skill_attack_range.append(attack_grid_index)
				if grid_index.y == Current.clicked_hero.hero_grid_index.y:
					for attack_grid_index in \
					[grid_index + Vector2i(0, -1), grid_index, grid_index + Vector2i(0, 1)]:
						if attack_grid_index in game_manager.all_grid_dict:
							game_manager.all_grid_dict[attack_grid_index].attack.visible = true
							Current.skill_attack_range.append(attack_grid_index)
	var attack_slime_array_info = _fetch_attack_slime_array_info(_fetch_attack_slime_array())
	#_count_dice_type([['red',1],['red',5],['blue',2]])
	var dice_type_point = _count_dice_type(attack_slime_array_info)
	Current.dice_type_point = dice_type_point[1]
	#print(dice_type_point)
	_show_dice_panel(attack_slime_array_info, dice_type_point)
		
	

func _show_soldier_skill_2_range():
	Current.skill_target_range = []
	var hero_grid_index = Current.clicked_hero.hero_grid_index
	for offset in game_manager.grid_offset:
		var target_grid_index
		target_grid_index = hero_grid_index + offset
		if target_grid_index in game_manager.all_grid_dict:
			game_manager.all_grid_dict[target_grid_index].target.visible = true
			Current.skill_target_range.append(target_grid_index)
	if Current.grid_index in Current.skill_target_range:
		_show_soldier_skill_2_attack()	
		
func _show_soldier_skill_2_attack():
	if not Current.power_slime is Slime and Current.power_slime == 1:
		Current.skill_attack_range = []
		for grid_index in Current.skill_target_range:
			## 鼠标选中格子等于技能格子,显示伤害范围
			if Current.grid_index == grid_index:
				Current.skill_attack_range = Current.skill_target_range
				## 加入英雄围四个角的坐标
				var offset_list = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
				for offset in offset_list:
					Current.skill_attack_range.append(Current.clicked_hero.hero_grid_index + offset)
				for attack_grid_index in Current.skill_attack_range:
					if attack_grid_index in game_manager.all_grid_dict:
						game_manager.all_grid_dict[attack_grid_index].attack.visible = true
	else:
		Current.skill_attack_range = []
		for grid_index in Current.skill_target_range:
			## 鼠标选中格子等于技能格子,显示伤害范围
			if Current.grid_index == grid_index:
				Current.skill_attack_range = Current.skill_target_range
				for attack_grid_index in Current.skill_attack_range:
					if attack_grid_index in game_manager.all_grid_dict:
						game_manager.all_grid_dict[attack_grid_index].attack.visible = true
	var attack_slime_array_info = _fetch_attack_slime_array_info(_fetch_attack_slime_array())
	#_count_dice_type([['red',1],['red',5],['blue',2]])
	var dice_type_point = _count_dice_type(attack_slime_array_info)
	Current.dice_type_point = dice_type_point[1]
	#print(dice_type_point)
	_show_dice_panel(attack_slime_array_info, dice_type_point)

func _show_soldier_skill_3_range():
	Current.skill_target_range = []
	var hero_grid_index = Current.clicked_hero.hero_grid_index
	for offset in game_manager.grid_offset:
		var target_grid_index
		target_grid_index = hero_grid_index + offset
		if target_grid_index in game_manager.all_grid_dict:
			game_manager.all_grid_dict[target_grid_index].target.visible = true
			Current.skill_target_range.append(target_grid_index)
	if Current.grid_index in Current.skill_target_range:
		_show_soldier_skill_3_attack()	
		
func _show_soldier_skill_3_attack():
	if not Current.power_slime is Slime and Current.power_slime == 2:
		Current.skill_attack_range = []
		var hero_grid_index = Current.clicked_hero.hero_grid_index
		for grid_index in Current.skill_target_range:
			## 鼠标选中格子等于技能格子,显示伤害范围
			if Current.grid_index == grid_index:
				var offset = Current.grid_index - hero_grid_index
				var attack_grid_index = hero_grid_index
				for i in range(6):
					attack_grid_index += offset
					if attack_grid_index in game_manager.all_grid_dict:
						Current.skill_attack_range.append(attack_grid_index)
						game_manager.all_grid_dict[attack_grid_index].attack.visible = true
						print(Current.skill_attack_range)
	else:
		Current.skill_attack_range = []
		var hero_grid_index = Current.clicked_hero.hero_grid_index
		for grid_index in Current.skill_target_range:
			## 鼠标选中格子等于技能格子,显示伤害范围
			if Current.grid_index == grid_index:
				var offset = Current.grid_index - hero_grid_index
				var attack_grid_index = hero_grid_index
				for i in range(3):
					attack_grid_index += offset
					if attack_grid_index in game_manager.all_grid_dict:
						Current.skill_attack_range.append(attack_grid_index)
						game_manager.all_grid_dict[attack_grid_index].attack.visible = true
						print(Current.skill_attack_range)
	var attack_slime_array_info = _fetch_attack_slime_array_info(_fetch_attack_slime_array())
	#_count_dice_type([['red',1],['red',5],['blue',2]])
	var dice_type_point = _count_dice_type(attack_slime_array_info)
	Current.dice_type_point = dice_type_point[1]
	#print(dice_type_point)
	_show_dice_panel(attack_slime_array_info, dice_type_point)

## 所有在红格子里的史莱姆组
func _fetch_attack_slime_array():
	var slime_array: Array
	for slime in Current.all_enemy_array:
		if slime.enemy_grid_index in Current.skill_attack_range:
			slime_array.append(slime)
	return slime_array

## 统计史莱姆骰子的颜色、点数、数量, return: [[<color>, <dice_num>], ...]
## example: [["red"， 3]， ["blue", 3]]
func _fetch_attack_slime_array_info(slime_array):
	var slime_color_dict := {
		"slime_small": "green",
		"slime_small_red": "red",
		"slime_small_yellow": "yellow",
		"slime_small_blue": "blue"
	}
	var attack_slime_array_info: Array
	for slime in slime_array:
		var slime_color = slime_color_dict[Tools.fetch_slime_scene(slime)]
		if slime_color:
			attack_slime_array_info.append([slime_color, slime.dice_point])
		else:
			assert(false, "slime have not color")
	return attack_slime_array_info

## 骰型板展示史莱姆对应的点数和骰型
func _show_dice_panel(attack_slime_array_info, dice_type_point):
	var dice_array = game_manager.dice_list.get_children()
	for num in range(dice_type_point[2].size()):
		dice_array[num].set_self_modulate(Color(1, 1, 1, 1))
	var frame_dict = {
		1: game_manager.one_score_frame.get("theme_override_styles/panel"),
		2: game_manager.two_score_frame.get("theme_override_styles/panel"),
		3: game_manager.three_score_frame.get("theme_override_styles/panel"),
		4: game_manager.four_score_frame.get("theme_override_styles/panel"),
		5: game_manager.five_score_frame.get("theme_override_styles/panel"),
		6: game_manager.six_score_frame.get("theme_override_styles/panel"),
		'none': game_manager.none_percent_frame.get("theme_override_styles/panel"),
		'duizi': game_manager.duizi_percent_frame.get("theme_override_styles/panel"),
		'shunzi': game_manager.shunzi_percent_frame.get("theme_override_styles/panel"),
		'tongse': game_manager.tongse_percent_frame.get("theme_override_styles/panel"),
		'tongdui': game_manager.tongdui_percent_frame.get("theme_override_styles/panel"),
		'tongshun': game_manager.tongshun_percent_frame.get("theme_override_styles/panel")
	}
	var percent_dict = {
		'none': Current.none_percent,
		'duizi': Current.duizi_percent,
		'shunzi': Current.shunzi_percent,
		'tongse': Current.tongse_percent,
		'tongdui': Current.tongdui_percent,
		'tongshun': Current.tongshun_percent
	}
	var score_dict := {
		1: Current.one_score,
		2: Current.two_score,
		3: Current.three_score,
		4: Current.four_score,
		5: Current.five_score,
		6: Current.six_score
	}
	#sb.border_color = Color.html(color["red"])
	if dice_type_point[2]:
		## 骰面框线
		for point in dice_type_point[2]:
			frame_dict[point].border_color = Color.html(game_manager.color["red"])
		## 骰型框线
		frame_dict[dice_type_point[0]].border_color = Color.html(game_manager.color["red"])
	var total_score := 0
	for point in dice_type_point[2]:
		total_score += score_dict[point]
	Current.base_score = total_score
	Current.percent_score = percent_dict[dice_type_point[0]]
	
## 清空板展示史莱姆对应的点数和骰型
func _reset_dice_panel():
	var dice_array = game_manager.dice_list.get_children()
	for dice in dice_array:
		dice.set_self_modulate(Color(1, 1, 1, 0.3))
	var frame_dict = {
		1: game_manager.one_score_frame.get("theme_override_styles/panel"),
		2: game_manager.two_score_frame.get("theme_override_styles/panel"),
		3: game_manager.three_score_frame.get("theme_override_styles/panel"),
		4: game_manager.four_score_frame.get("theme_override_styles/panel"),
		5: game_manager.five_score_frame.get("theme_override_styles/panel"),
		6: game_manager.six_score_frame.get("theme_override_styles/panel"),
		'none': game_manager.none_percent_frame.get("theme_override_styles/panel"),
		'duizi': game_manager.duizi_percent_frame.get("theme_override_styles/panel"),
		'shunzi': game_manager.shunzi_percent_frame.get("theme_override_styles/panel"),
		'tongse': game_manager.tongse_percent_frame.get("theme_override_styles/panel"),
		'tongdui': game_manager.tongdui_percent_frame.get("theme_override_styles/panel"),
		'tongshun': game_manager.tongshun_percent_frame.get("theme_override_styles/panel")
	}
	for i in frame_dict.values():
		i.border_color = Color.html(game_manager.color["alpha0"])
	Current.base_score = 0
	Current.percent_score = 0

## 计算选中的最高最终骰型
## return ['none', round(none_score_dice[0]), none_score_dice[1]]
## [<类型>, <分数>, <参与计算的骰子数组>]
func _count_dice_type(attack_slime_array_info):
	var duizi_score_dice = _count_duizi(attack_slime_array_info)
	var shunzi_score_dice = _count_shunzi(attack_slime_array_info)
	var tongse_score_dice = _count_tongse(attack_slime_array_info)
	var tongdui_score_dice = _count_tongdui(attack_slime_array_info)
	var tongshun_score_dice = _count_tongshun(attack_slime_array_info)
	var all_score_dict := {
		'duizi': duizi_score_dice,
		'shunzi': shunzi_score_dice,
		'tongse': tongse_score_dice,
		'tongdui': tongdui_score_dice,
		'tongshun': tongshun_score_dice
	}
	var biggest_score := []
	for score in all_score_dict:
		#print(score, all_score_dict[score])
		if all_score_dict[score][0] > 0:
			if biggest_score:
				if all_score_dict[score][0] > biggest_score[1]:
					biggest_score = [score, all_score_dict[score][0], all_score_dict[score][1]]
			else:
				biggest_score = [score, all_score_dict[score][0], all_score_dict[score][1]]
	if biggest_score:
		biggest_score[1] = round(biggest_score[1])
		#print(biggest_score)
		return biggest_score
	else:
		#print(['none', round(_count_none(attack_slime_array_info))])
		var none_score_dice = _count_none(attack_slime_array_info)
		return ['none', round(none_score_dice[0]), none_score_dice[1]]

## 计算本次攻击的分数
func _count_score(attack_slime_array_info):
	pass
	
## 对子算法
func _count_duizi(attack_slime_array_info):
	var score_dict := {
		1: Current.one_score,
		2: Current.two_score,
		3: Current.three_score,
		4: Current.four_score,
		5: Current.five_score,
		6: Current.six_score
	}
	var resut_dict := {1: [], 2: [], 3: [], 4: [], 5: [], 6: []}
	for point in attack_slime_array_info:
		resut_dict[point[1]].append(point[1])
	var score := 0.0
	var tmp_score := 0.0
	var tmp_item := []
	for v in resut_dict.values():
		if tmp_item:
			if v.size() >= tmp_item.size():
				tmp_item = v
		else:
			if v.size() >= 2:
				tmp_item = v
	if tmp_item:
		for point in tmp_item:
			tmp_score += score_dict[point]
		score = tmp_score * (Current.duizi_percent / 100.0)
	return [score, tmp_item]

## 顺子算法
func _count_shunzi(attack_slime_array_info):
	var score_dict := {
		1: Current.one_score,
		2: Current.two_score,
		3: Current.three_score,
		4: Current.four_score,
		5: Current.five_score,
		6: Current.six_score
	}
	var score := 0.0
	var tmp_score := 0.0
	var tmp_item := []
	var flag := 0
	var tmp_array_1 := []
	var tmp_array_2 := []
	var unique_porint_array := []
	for point in attack_slime_array_info:
		if not unique_porint_array.has(point[1]):
			unique_porint_array.append(point[1])
	unique_porint_array.sort()
	for point in unique_porint_array:
		if flag == 0:
			if tmp_array_1:
				if point - 1 == tmp_array_1[tmp_array_1.size() - 1]:
					tmp_array_1.append(point)
				else:
					if tmp_array_1.size() > 2:
						tmp_item = tmp_array_1
						break
					else:
						flag += 1
						tmp_array_2.append(point)
						continue
			else:
				tmp_array_1.append(point)
		else:
			if point - 1 == tmp_array_2[tmp_array_2.size() - 1]:
				tmp_array_2.append(point)
			else:
				tmp_item = tmp_array_2
				break
	if tmp_array_2.size() >= 2:
		tmp_item = tmp_array_2
	else:
		if tmp_array_1.size() >= 2:
			tmp_item = tmp_array_1
		else:
			tmp_item = []
	if tmp_item:
		for point in tmp_item:
			tmp_score += score_dict[point]
		score = tmp_score * (Current.shunzi_percent / 100.0)
	return [score, tmp_item]

## 同色算法
func _count_tongse(attack_slime_array_info):
	var score_dict := {
		1: Current.one_score,
		2: Current.two_score,
		3: Current.three_score,
		4: Current.four_score,
		5: Current.five_score,
		6: Current.six_score
	}
	var resut_dict := {"red": [], "yellow": [], "green": [], "blue": []}
	for point in attack_slime_array_info:
		resut_dict[point[0]].append(point[1])
	var score := 0.0
	var tmp_score := 0.0
	var tmp_item := []
	for v in resut_dict.values():
		if tmp_item:
			if v.size() == tmp_item.size():
				var count_1 = 0
				for i in v:
					count_1 += i
				var count_2 = 0
				for i in tmp_item:
					count_2 += i
				if count_1 > count_2:
					tmp_item = v
			if v.size() > tmp_item.size():
				tmp_item = v
		else:
			if v.size() >= 2:
				tmp_item = v
	if tmp_item:
		for point in tmp_item:
			tmp_score += score_dict[point]
		score = tmp_score * (Current.tongse_percent / 100.0)
	return [score, tmp_item]

## 同色对子算法
func _count_tongdui(attack_slime_array_info):
	var score_dict := {
		1: Current.one_score,
		2: Current.two_score,
		3: Current.three_score,
		4: Current.four_score,
		5: Current.five_score,
		6: Current.six_score
	}
	var resut_dict := {1: [], 2: [], 3: [], 4: [], 5: [], 6: []}
	for point in attack_slime_array_info:
		resut_dict[point[1]].append(point)
	var tmp_item := []
	for v in resut_dict.values():
		if tmp_item:
			if v.size() >= tmp_item.size():
				tmp_item = v
		else:
			if v.size() >= 2:
				tmp_item = v
	resut_dict = {"red": [], "yellow": [], "green": [], "blue": []}
	for point in tmp_item:
		resut_dict[point[0]].append(point[1])
	var score := 0.0
	var tmp_score := 0.0
	tmp_item = []
	for v in resut_dict.values():
		if tmp_item:
			if v.size() == tmp_item.size():
				var count_1 = 0
				for i in v:
					count_1 += i
				var count_2 = 0
				for i in tmp_item:
					count_2 += i
				if count_1 > count_2:
					tmp_item = v
			if v.size() > tmp_item.size():
				tmp_item = v
		else:
			if v.size() >= 2:
				tmp_item = v
	if tmp_item:
		for point in tmp_item:
			tmp_score += score_dict[point]
		score = tmp_score * (Current.tongdui_percent / 100.0)
	return [score, tmp_item]

## 同色顺子算法
func _count_tongshun(attack_slime_array_info):
	var score_dict := {
		1: Current.one_score,
		2: Current.two_score,
		3: Current.three_score,
		4: Current.four_score,
		5: Current.five_score,
		6: Current.six_score
	}
	var score := 0.0
	var tmp_score := 0.0
	var tmp_item := []
	## 计算同色组
	var resut_dict := {"red": [], "yellow": [], "green": [], "blue": []}
	for point in attack_slime_array_info:
		resut_dict[point[0]].append(point[1])
	for v in resut_dict.values():
		if tmp_item:
			if v.size() == tmp_item.size():
				var count_1 = 0
				for i in v:
					count_1 += i
				var count_2 = 0
				for i in tmp_item:
					count_2 += i
				if count_1 > count_2:
					tmp_item = v
			if v.size() > tmp_item.size():
				tmp_item = v
		else:
			if v.size() >= 2:
				tmp_item = v
	## 计算顺子
	var flag := 0
	var tmp_array_1 := []
	var tmp_array_2 := []
	var unique_porint_array := []
	for point in tmp_item:
		if not unique_porint_array.has(point):
			unique_porint_array.append(point)
	unique_porint_array.sort()
	for point in unique_porint_array:
		if flag == 0:
			if tmp_array_1:
				if point - 1 == tmp_array_1[tmp_array_1.size() - 1]:
					tmp_array_1.append(point)
				else:
					if tmp_array_1.size() > 2:
						tmp_item = tmp_array_1
						break
					else:
						flag += 1
						tmp_array_2.append(point)
						continue
			else:
				tmp_array_1.append(point)
		else:
			if point - 1 == tmp_array_2[tmp_array_2.size() - 1]:
				tmp_array_2.append(point)
			else:
				tmp_item = tmp_array_2
				break
	if tmp_array_2.size() >= 2:
		tmp_item = tmp_array_2
	else:
		if tmp_array_1.size() >= 2:
			tmp_item = tmp_array_1
		else:
			tmp_item = []
	if tmp_item:
		for point in tmp_item:
			tmp_score += score_dict[point]
		score = tmp_score * (Current.tongshun_percent / 100.0)
	return [score, tmp_item]

## 无骰型法
func _count_none(attack_slime_array_info):
	var score_dict := {
		1: Current.one_score,
		2: Current.two_score,
		3: Current.three_score,
		4: Current.four_score,
		5: Current.five_score,
		6: Current.six_score
	}
	var score := 0.0
	var tmp_score := 0.0
	var tmp_item := []
	for point in attack_slime_array_info:
		tmp_item.append(point[1])
		tmp_score += score_dict[point[1]]
	if tmp_score:
		score = tmp_score * (Current.none_percent / 100.0)
	return [score, tmp_item]
