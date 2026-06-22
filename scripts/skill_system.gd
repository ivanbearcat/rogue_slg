extends Node2D
@onready var game_manager: Node2D = $".."

@onready var dice_type_dict := {
	"shunzi": "shunzi_percent",
	"tongse": "tongse_percent",
	"duizi": "duizi_percent",
	"tongshun": "tongshun_percent",
	"tongdui": "tongdui_percent"
}

signal hide_all_skill

func _ready() -> void:
		## 订阅显示攻击范围
	EventBus.subscribe("show_skill_attack", show_skill_attack)
	EventBus.subscribe("hide_skill_range", hide_skill_range)
	EventBus.subscribe("hide_skill_attack", hide_skill_attack)
	EventBus.subscribe("skill_move", skill_move)

func show_skill_range(hero_name, skill_num):
	call("_show_" + hero_name + "_skill_" + skill_num + "_range")

## 隐藏所有格子
func hide_skill_range():
	for target_grid_index in game_manager.all_grid_dict:
		game_manager.all_grid_dict[target_grid_index].target.visible = false
	hide_skill_attack()

## 隐藏所有红色格子
func show_skill_attack(hero_name, skill_num):
	hide_skill_attack()
	call("_show_" + hero_name + "_skill_" + skill_num + "_attack")

func hide_skill_attack():
	for attack_grid_index in game_manager.all_grid_dict:
		game_manager.all_grid_dict[attack_grid_index].attack.visible = false
	_reset_dice_panel()

## 鼠标点击红框之后攻击
func skill_attack():
	## 正在攻击结算
	Current.action_lock = true
	## 攻击前buff
	EventBus.event_emit("do_pre_attack_buff")
	## 收集攻击骰子信息（含掉落格子骰子）
	var attack_slime_array = _fetch_attack_slime_array()
	var attack_slime_array_info = _fetch_attack_slime_array_info(attack_slime_array)
	## 检查精英/BOSS史莱姆的骰型门槛
	var elite_boss_slimes_in_range = []
	var gate_passed_slimes = []
	var gate_failed_slimes = []
	for slime in attack_slime_array:
		if slime.is_elite or slime.is_boss:
			elite_boss_slimes_in_range.append(slime)
			var slime_color_dict := {
				"slime_small": "green",
				"slime_small_red": "red",
				"slime_small_yellow": "yellow",
				"slime_small_blue": "blue"
			}
			var target_color = slime_color_dict[Tools.fetch_slime_scene(slime)]
			var target_dice = [target_color, slime.dice_point]
			if ScoringAlgorithm.check_gate(attack_slime_array_info, target_dice, slime.gate_type, slime.gate_count):
				gate_passed_slimes.append(slime)
			else:
				gate_failed_slimes.append(slime)
	## 计算骰型得分（所有骰子都参与计分，包括门槛未通过的精英/BOSS骰子）
	var dice_type_result = ScoringAlgorithm.count_total_score(attack_slime_array_info)
	Current.dice_type_point = dice_type_result[0]
	## 设置骰型数量（骰型大师用）
	var type_array: Array = dice_type_result[1]
	var dice_type_count := 0
	for t in type_array:
		if t != "none":
			dice_type_count += 1
	Current.dice_type_count = dice_type_count
	## 设置本次攻击触发的骰型名称（击杀倍率用）
	Current.active_dice_types = []
	for t in type_array:
		if t != "none" and t not in Current.active_dice_types:
			Current.active_dice_types.append(t)
	## 设置参与计分的骰子信息（击杀特化/颜色对应骰型用）
	Current.scored_dice_info = dice_type_result[3]
	## 史莱姆死亡
	Current.slime_die_sum = 0
	for slime in Current.all_enemy_array:
		if slime.enemy_grid_index in Current.skill_attack_range:
			## 门槛未通过的精英/BOSS史莱姆不死亡
			if slime in gate_failed_slimes:
				continue
			Current.slime_die_sum += 1
			slime.animated_sprite_2d.play("die")
	## 门槛通过的精英/BOSS史莱姆击杀后清除ELITE debuff
	if not gate_passed_slimes.is_empty():
		EventBus.event_emit("clear_elite_buff")
	## 得分特效
	var float_number_instantiate = EffectManager.float_number_effect(Current.dice_type_point)
	if float_number_instantiate != null:
		Current.hero.add_child(float_number_instantiate)
	await Tools.time_sleep(0.5)
	Current.total_score += Current.dice_type_point
	Current.once_total_score = Current.dice_type_point
	## 破釜沉舟得分加成（pre_hero_turn时已扣血设标记，此处计算加成）
	if Current.scorched_earth_bonus > 0:
		var se_add_num = int(Current.once_total_score * Current.scorched_earth_bonus)
		if se_add_num > 0:
			Current.total_score += se_add_num
	## 等待攻击动画完成和公共锁释放
	while Current.attack_animation_finished == 0:
		await Tools.time_sleep(0.05)
	Current.hero.hero_state_machine.transition_to("end")
	Current.action_lock = false
	### 攻击后buff
	EventBus.event_emit("do_post_attack_buff")
	## 等待buff处理完成
	await game_manager.wait_for_buff_finish()
	## 如果是赋能技能就消耗能量,然后重置UI
	if Current.power_skill:
		Current.power -= 1
		EventBus.event_emit("skill_power_reset")
		EventBus.event_emit("skill_button_reset")
	## 处理掉落骰子
	await _process_dropped_dice(attack_slime_array_info, dice_type_result)
	## 标记本回合攻击过（连击风暴用）
	Current.last_turn_attacked = true
	## 注意：once_total_score 不在此处清零，由 game_manager.skill_attack() 在 _apply_score_heal() 之后清零
	## 恢复技能UI弹起状态
	hide_all_skill.emit()

## 处理掉落骰子：从攻击结果中提取未参与骰型的骰子，让玩家选择保留1个
func _process_dropped_dice(attack_slime_array_info: Array, dice_type_result: Array):
	var scored_dice_info: Array = dice_type_result[3]  ## 参与计分的骰子
	## 保存掉落格子骰子引用（用于排除非新掉落的骰子）
	var old_drop_slot = Current.drop_slot_dice
	## 计算掉落骰子 = 所有输入骰子 - 参与计分的骰子
	var dropped_dice: Array = []
	var scored_copy = scored_dice_info.duplicate()
	for dice in attack_slime_array_info:
		var found := false
		for i in range(scored_copy.size()):
			if scored_copy[i][0] == dice[0] and scored_copy[i][1] == dice[1]:
				scored_copy.remove_at(i)
				found = true
				break
		if not found:
			dropped_dice.append(dice.duplicate())
	## 设置掉落格子骰子消耗标记（drop_hunter用）
	## 如果掉落格子骰子参与了计分（在scored_dice中），则标记为true
	if old_drop_slot != null:
		var _found_in_scored := false
		var scored_check = scored_dice_info.duplicate()
		for dice in scored_check:
			if dice[0] == old_drop_slot[0] and dice[1] == old_drop_slot[1]:
				_found_in_scored = true
				break
		Current.drop_slot_consumed_this_turn = _found_in_scored
	## 设置掉落骰子数量（掉落奖励/掉落惩罚用）
	## 排除掉落格子骰子（它不是新掉落的，不应计入掉落奖励数量）
	var drop_slot_in_dropped := 0
	if old_drop_slot != null:
		for dice in dropped_dice:
			if dice[0] == old_drop_slot[0] and dice[1] == old_drop_slot[1]:
				drop_slot_in_dropped += 1
				break
	Current.dropped_dice_count = dropped_dice.size() - drop_slot_in_dropped
	## 手动触发掉落奖励buff（因为掉落骰子数量在此处才确定）
	await _apply_drop_bonus()
	## 如果掉落格子骰子参与了计分，则从格子中消耗
	## （它已经在dropped_dice中不存在了，因为它是scored_dice的一部分）
	## 如果掉落格子骰子没有参与计分，它已经在dropped_dice中
	## 清空掉落格子（骰子已被消耗或已加入dropped_dice）
	Current._drop_slot_dice = null  ## 临时清空，不触发UI更新
	## 检查禁用掉落格子debuff（通过检查drop_ban_buff是否在buff列表中）
	var buff_sys = game_manager.get_node("/root/BuffSystem")
	var timing_arrays = buff_sys._get_timing_arrays("pre_hero_turn")
	var drop_ban_active := false
	for buff_list in timing_arrays:
		for buff in buff_list:
			if buff.buff_meta.get("debuff_id", "") == "drop_ban":
				drop_ban_active = true
				break
		if drop_ban_active:
			break
	if drop_ban_active:
		Current.drop_slot_dice = null
		return
	## 如果没有掉落骰子，格子变空
	if dropped_dice.size() == 0:
		Current.drop_slot_dice = null
		return
	## 弹出掉落选择界面
	await _show_drop_selection(dropped_dice)

## 手动触发掉落奖励buff（掉落骰子数量在 _process_dropped_dice 中才确定）
func _apply_drop_bonus():
	if Current.dropped_dice_count <= 0:
		return
	## 扫描 BuffSystem 中所有 post_attack_buff，找 drop_bonus
	var buff_sys = BuffSystem
	var timing_arrays = buff_sys._get_timing_arrays("post_attack")
	for i in range(timing_arrays.size()):
		var buff_list = timing_arrays[i]
		for buff in buff_list:
			if buff.buff_meta.get("buff_id", "") == "drop_bonus":
				await buff.process_buff()
				## ONCE类型用完移除
				if i == 0:  ## index 0 = ONCE
					buff_list.erase(buff)
					buff.clear_buff()
				return

## 显示掉落骰子选择界面，玩家选择1个保留在掉落格子
func _show_drop_selection(dropped_dice: Array):
	## 如果掉落格子已有骰子（不应该有，因为上面已清空，但防御性编程）
	## 玩家从所有掉落骰子中选1个保留
	if dropped_dice.size() == 0:
		return
	## 如果只有1个掉落骰子，直接放入格子
	if dropped_dice.size() == 1:
		Current.drop_slot_dice = dropped_dice[0]
		return
	## 多个掉落骰子，弹出选择界面
	Current.public_lock_array.append("drop_selection")
	var drop_selection_ui = game_manager.get_node("drop_selection_ui")
	drop_selection_ui.setup(dropped_dice)
	## 等待玩家选择完成
	while "drop_selection" in Current.public_lock_array:
		await Tools.time_sleep(0.05)
	## 选择结果存储在 Current 的 meta 中
	if Current.has_meta("drop_selection_result"):
		Current.drop_slot_dice = Current.get_meta("drop_selection_result")
		Current.remove_meta("drop_selection_result")
	else:
		## 玩家未选择（不应该发生），保留第一个
		Current.drop_slot_dice = dropped_dice[0]
func skill_move():
	Current.action_lock = true
	## 判断技能朝向
	var position_offset: Vector2
	var all_slime_array = Current.all_enemy_array.duplicate()
	## 上
	if Current.grid_index.x == Current.hero.hero_grid_index.x and \
	Current.grid_index.y < Current.hero.hero_grid_index.y:
		position_offset = Vector2(0, 16)
		all_slime_array.sort_custom(func(a, b): return a.enemy_grid_index.y > b.enemy_grid_index.y)
	## 下
	if Current.grid_index.x == Current.hero.hero_grid_index.x and \
	Current.grid_index.y > Current.hero.hero_grid_index.y:
		position_offset = Vector2(0, -16)
		all_slime_array.sort_custom(func(a, b): return a.enemy_grid_index.y < b.enemy_grid_index.y)
	## 左
	if Current.grid_index.y == Current.hero.hero_grid_index.y and \
	Current.grid_index.x < Current.hero.hero_grid_index.x:
		position_offset = Vector2(16, 0)
		all_slime_array.sort_custom(func(a, b): return a.enemy_grid_index.x > b.enemy_grid_index.x)
	## 右
	if Current.grid_index.y == Current.hero.hero_grid_index.y and \
	Current.grid_index.x > Current.hero.hero_grid_index.x:
		position_offset = Vector2(-16, 0)
		all_slime_array.sort_custom(func(a, b): return a.enemy_grid_index.x < b.enemy_grid_index.x)
	## 史莱姆移动
	for slime in all_slime_array:
		if slime.enemy_grid_index in Current.skill_attack_range:
			var target_position = slime.position + position_offset
			if target_position not in Current.all_enemy_position_array:
				slime.target_position = target_position
				var old_position = slime.position
				while slime.position == old_position:
					await Tools.time_sleep(0.01)
	## 如果是赋能技能就消耗能量,然后重置UI
	if Current.power_skill:
		Current.power -= 1
		EventBus.event_emit("skill_power_reset")
		EventBus.event_emit("skill_button_reset")
	hide_all_skill.emit()
	## 等待攻击动画完成
	while Current.attack_animation_finished == 0:
		await Tools.time_sleep(0.05)
	## 切换状态
	if Current.is_moved == false:
		Current.hero.animated_sprite_2d.play(Current.hero.hero_name + "_idle")
		Current.hero.hero_state_machine.transition_to("idle")
	else:
		Current.hero.animated_sprite_2d.play(Current.hero.hero_name + "_end")
		Current.hero.hero_state_machine.transition_to("move")
	Current.action_lock = false

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
	if Current.power_skill == 1:
		for grid_index in Current.skill_target_range:
			## 鼠标选中格子等于技能格子,显示伤害范围
			if Current.grid_index == grid_index:
				if grid_index.x == Current.clicked_hero.hero_grid_index.x:
					var offset = grid_index.y - Current.clicked_hero.hero_grid_index.y
					for attack_grid_index in \
					[grid_index + Vector2(-1, 0),
					grid_index,
					grid_index + Vector2(1, 0),
					grid_index + Vector2(-1, offset),
					grid_index + Vector2(0, offset),
					grid_index + Vector2(1, offset)]:
						if attack_grid_index in game_manager.all_grid_dict:
							game_manager.all_grid_dict[attack_grid_index].attack.visible = true
							Current.skill_attack_range.append(attack_grid_index)
				if grid_index.y == Current.clicked_hero.hero_grid_index.y:
					var offset = grid_index.x - Current.clicked_hero.hero_grid_index.x
					for attack_grid_index in \
					[grid_index + Vector2(0, -1),
					grid_index,
					grid_index + Vector2(0, 1),
					grid_index + Vector2(offset, -1),
					grid_index + Vector2(offset, 0),
					grid_index + Vector2(offset, 1)]:
						if attack_grid_index in game_manager.all_grid_dict:
							game_manager.all_grid_dict[attack_grid_index].attack.visible = true
							Current.skill_attack_range.append(attack_grid_index)
	else:
		for grid_index in Current.skill_target_range:
			## 鼠标选中格子等于技能格子,显示伤害范围
			if Current.grid_index == grid_index:
				if grid_index.x == Current.clicked_hero.hero_grid_index.x:
					for attack_grid_index in \
					[grid_index + Vector2(-1, 0), grid_index, grid_index + Vector2(1, 0)]:
						if attack_grid_index in game_manager.all_grid_dict:
							game_manager.all_grid_dict[attack_grid_index].attack.visible = true
							Current.skill_attack_range.append(attack_grid_index)
				if grid_index.y == Current.clicked_hero.hero_grid_index.y:
					for attack_grid_index in \
					[grid_index + Vector2(0, -1), grid_index, grid_index + Vector2(0, 1)]:
						if attack_grid_index in game_manager.all_grid_dict:
							game_manager.all_grid_dict[attack_grid_index].attack.visible = true
							Current.skill_attack_range.append(attack_grid_index)
	var attack_slime_array_info = _fetch_attack_slime_array_info(_fetch_attack_slime_array())
	#count_highest_score([['red',1],['red',5],['blue',2]])
	#var dice_type_point = _count_dice_type(attack_slime_array_info)
	var dice_type_point = ScoringAlgorithm.count_total_score(attack_slime_array_info)
	Current.dice_type_point = dice_type_point[0]
	#print(dice_type_point)
	_show_dice_panel(dice_type_point)

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
	Current.skill_attack_range = []
	if Current.power_skill == 2:
		for grid_index in Current.skill_target_range:
			## 鼠标选中格子等于技能格子,显示伤害范围
			if Current.grid_index == grid_index:
				Current.skill_attack_range = Current.skill_target_range.duplicate()
				## 加入英雄围四个角的坐标
				var offset_list = [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
				for offset in offset_list:
					Current.skill_attack_range.append(Current.clicked_hero.hero_grid_index + offset)
				for attack_grid_index in Current.skill_attack_range:
					if attack_grid_index in game_manager.all_grid_dict:
						game_manager.all_grid_dict[attack_grid_index].attack.visible = true
	else:
		for grid_index in Current.skill_target_range:
			## 鼠标选中格子等于技能格子,显示伤害范围
			if Current.grid_index == grid_index:
				Current.skill_attack_range = Current.skill_target_range
				for attack_grid_index in Current.skill_attack_range:
					if attack_grid_index in game_manager.all_grid_dict:
						game_manager.all_grid_dict[attack_grid_index].attack.visible = true
	var attack_slime_array_info = _fetch_attack_slime_array_info(_fetch_attack_slime_array())
	#_count_dice_type([['red',1],['red',5],['blue',2]])
	#var dice_type_point = _count_dice_type(attack_slime_array_info)
	var dice_type_point = ScoringAlgorithm.count_total_score(attack_slime_array_info)
	Current.dice_type_point = dice_type_point[0]
	#print(dice_type_point)
	_show_dice_panel(dice_type_point)

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
	Current.skill_attack_range = []
	for grid_index in Current.skill_target_range:
			## 鼠标选中格子等于技能格子,显示伤害范围
			if Current.grid_index == grid_index:
				## 上
				if grid_index.x == Current.clicked_hero.hero_grid_index.x and \
				grid_index.y < Current.clicked_hero.hero_grid_index.y:
					for attack_grid_index in [
						grid_index + Vector2(-1, 0),
						grid_index + Vector2(1, 0),
						grid_index + Vector2(-1, -1),
					 	grid_index + Vector2(0, -1),
					 	grid_index + Vector2(1, -1)
					]:
						if attack_grid_index in game_manager.all_grid_dict:
							game_manager.all_grid_dict[attack_grid_index].attack.visible = true
							Current.skill_attack_range.append(attack_grid_index)
				## 下
				if grid_index.x == Current.clicked_hero.hero_grid_index.x and \
				grid_index.y > Current.clicked_hero.hero_grid_index.y:
					for attack_grid_index in [
						grid_index + Vector2(-1, 0),
						grid_index + Vector2(1, 0),
						grid_index + Vector2(-1, 1),
					 	grid_index + Vector2(0, 1),
					 	grid_index + Vector2(1, 1)
					]:
						if attack_grid_index in game_manager.all_grid_dict:
							game_manager.all_grid_dict[attack_grid_index].attack.visible = true
							Current.skill_attack_range.append(attack_grid_index)
				## 左
				if grid_index.y == Current.clicked_hero.hero_grid_index.y and \
				grid_index.x < Current.clicked_hero.hero_grid_index.x:
					for attack_grid_index in [
						grid_index + Vector2(0, -1),
						grid_index + Vector2(0, 1),
						grid_index + Vector2(-1, 1),
					 	grid_index + Vector2(-1, 0),
					 	grid_index + Vector2(-1, -1)
					]:
						if attack_grid_index in game_manager.all_grid_dict:
							game_manager.all_grid_dict[attack_grid_index].attack.visible = true
							Current.skill_attack_range.append(attack_grid_index)
				## 右
				if grid_index.y == Current.clicked_hero.hero_grid_index.y and \
				grid_index.x > Current.clicked_hero.hero_grid_index.x:
					for attack_grid_index in [
						grid_index + Vector2(0, 1),
						grid_index + Vector2(0, -1),
						grid_index + Vector2(1, 1),
					 	grid_index + Vector2(1, 0),
					 	grid_index + Vector2(1, -1)
					]:
						if attack_grid_index in game_manager.all_grid_dict:
							game_manager.all_grid_dict[attack_grid_index].attack.visible = true
							Current.skill_attack_range.append(attack_grid_index)

## 直线三格和直线到底
func _show_soldier_skill_3_attack_bak():
	Current.skill_attack_range = []
	if Current.power_skill == 3:
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
	else:
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
	var attack_slime_array_info = _fetch_attack_slime_array_info(_fetch_attack_slime_array())
	#_count_dice_type([['red',1],['red',5],['blue',2]])
	var dice_type_point = ScoringAlgorithm.count_highest_score(attack_slime_array_info)
	Current.dice_type_point = dice_type_point[1]
	#print(dice_type_point)
	_show_dice_panel(dice_type_point)

## 所有在红格子里的史莱姆组
func _fetch_attack_slime_array():
	var slime_array: Array
	for slime in Current.all_enemy_array:
		if slime.enemy_grid_index in Current.skill_attack_range:
			slime_array.append(slime)
	return slime_array

## 统计史莱姆骰子的颜色、点数、数量, return: [[<color>, <dice_num>], ...]
## example: [[\"red\"， 3]， [\"blue\", 3]]
## 包含掉落格子骰子（如果有）
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
	## 追加掉落格子骰子
	if Current.drop_slot_dice != null:
		attack_slime_array_info.append(Current.drop_slot_dice.duplicate())
	return attack_slime_array_info

## 骰型板展示待攻击史莱姆的分值条和骰型
func _show_dice_panel(dice_type_point):
	## 分值条
	var score_bar_child_array = game_manager.score_bar.get_children()
	var iter_times = 0
	var score_bar_label_text = ""
	var score = dice_type_point[0]
	var thresholds = [10, 50, 100, 200, 400, 800, 1200, 2400]
	if score > 0 and score < thresholds[0]:
		iter_times = 0
	else:
		for i in range(thresholds.size()):
			if score >= thresholds[i]:
				iter_times = i + 1
	score_bar_label_text = str(score)
	for num in range(iter_times):
		score_bar_child_array[num].set_self_modulate(Color(1, 1, 1, 1))
	game_manager.score_bar_label.text = score_bar_label_text
	game_manager.score_bar_label.show()

	var frame_dict = {
		1: game_manager.one_score_frame.get("theme_override_styles/panel"),
		2: game_manager.two_score_frame.get("theme_override_styles/panel"),
		3: game_manager.three_score_frame.get("theme_override_styles/panel"),
		4: game_manager.four_score_frame.get("theme_override_styles/panel"),
		5: game_manager.five_score_frame.get("theme_override_styles/panel"),
		6: game_manager.six_score_frame.get("theme_override_styles/panel"),
		'duizi': game_manager.duizi_percent_frame.get("theme_override_styles/panel"),
		'shunzi': game_manager.shunzi_percent_frame.get("theme_override_styles/panel"),
		'tongse': game_manager.tongse_percent_frame.get("theme_override_styles/panel"),
		'tongdui': game_manager.tongdui_percent_frame.get("theme_override_styles/panel"),
		'tongshun': game_manager.tongshun_percent_frame.get("theme_override_styles/panel")
	}

	## 骰型框线和设置倍率
	#for type in dice_type_point[1]:
		#frame_dict[type].border_color = Color.html(game_manager.color["red"])
	for index in range(dice_type_point[1].size()):
		var dice_type = dice_type_point[1][index]
		## "none"类型没有对应的骰型行UI，跳过
		if dice_type == "none":
			continue
		frame_dict[dice_type].border_color = Color.html(game_manager.color["red"])
		Current.set(dice_type_dict[dice_type], Current.dice_multiplier_dict[dice_type_point[2][index]][dice_type])

## 清空板展示史莱姆对应的点数和骰型
func _reset_dice_panel():
	var score_bar_child_array = game_manager.score_bar.get_children()
	for child in score_bar_child_array:
		child.set_self_modulate(Color(1, 1, 1, 0.3))
	game_manager.score_bar_label.text = ""
	game_manager.score_bar_label.hide()
	var frame_dict = {
		1: game_manager.one_score_frame.get("theme_override_styles/panel"),
		2: game_manager.two_score_frame.get("theme_override_styles/panel"),
		3: game_manager.three_score_frame.get("theme_override_styles/panel"),
		4: game_manager.four_score_frame.get("theme_override_styles/panel"),
		5: game_manager.five_score_frame.get("theme_override_styles/panel"),
		6: game_manager.six_score_frame.get("theme_override_styles/panel"),
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
	## 恢复初始lv1倍率
	for key in dice_type_dict.keys():
		if Current.get(dice_type_dict[key]) != Current.dice_multiplier_dict[2][key]:
			Current.set(dice_type_dict[key], Current.dice_multiplier_dict[2][key])
	## 重置掉落行显示（反映当前 drop_slot_dice 状态）
	Current._update_drop_slot_ui()

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
		## 没有任何骰型组合 → 返回分数0
		return ['none', 0, []]

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
