extends RefCounted

class_name ScoringAlgorithm

## 计算最高分（递归）
## 输入参数范例: [["red", 3], ["blue", 3]]
## 返回：[分数, ["骰型", "骰型"]]
static func count_total_score(attack_slime_array_info):
	var score_dict := {
		1: Current.one_score,
		2: Current.two_score,
		3: Current.three_score,
		4: Current.four_score,
		5: Current.five_score,
		6: Current.six_score
	}
	### 空数组返回0分和空骰型
	#if attack_slime_array_info == []:
		#return [0, []]
	### 初始化最高分和最高分组合名称数组
	#var highest_score := 0
	#var highest_type_array := []
	### 基准骰子
	#var base_dice: Array = attack_slime_array_info[0]
	### 剩余骰子
	#var other_dice_array: Array
	#if attack_slime_array_info.size() > 1:
		#other_dice_array = attack_slime_array_info.slice(1)
	#else:
		#other_dice_array = []
	### 基准骰子单独情况
	#var base_score: int = score_dict[base_dice[1]]
	#var count_total_score_tmp = count_total_score(other_dice_array)
	#var other_dice_score: int = count_total_score_tmp[0]
	#var other_type_array = count_total_score_tmp[1]
	#highest_score = base_score + other_dice_score
	#highest_type_array = ["none"] + other_type_array
	### 剩余骰子数量
	#var dice_num: int = other_dice_array.size()
	### 遍历除了单骰子情况其余情况
	##for mask in range(1, 2 ^ dice_num - 1 ):
	#for mask in range(1, 1 << dice_num):
		### 当前骰子组合
		#var current_dice_group: Array = [base_dice]
		### 剩余骰子组合
		#var other_dice_group: Array = []
		### 根据位掩码创建组合
		#for dice_index in range(dice_num):
			#if (mask >> dice_index) & 1 == 1:
				### 剩余骰子[dice_index] 加入 当前骰子组合
				#current_dice_group.append(other_dice_array[dice_index])
			#else:
				### 剩余骰子[dice_index] 加入 剩余骰子组合
				#other_dice_group.append(other_dice_array[dice_index])
		### 计算当前骰子组的最高分和最高分组合名
		#var count_highest_score_result = count_highest_score(current_dice_group)
		#var current_dice_group_score = count_highest_score_result[1]
		#var current_dice_type_array = count_highest_score_result[0]
		### 递归计算剩余骰子组总分和组合名称
		#var count_total_score_result = count_total_score(other_dice_group)
		#var other_dice_group_score = count_total_score_result[0]
		#var iter_dice_type_array = count_total_score_result[1]
		### 这种组合的得分和组合名
		#var total_score = current_dice_group_score + other_dice_group_score
		#var all_dice_type_array = [current_dice_type_array] + iter_dice_type_array
		### 更新最高分和组合名称
		#if total_score > highest_score:
			#highest_score = total_score
			#highest_type_array = all_dice_type_array
		### 返回最高分组合
	#return [highest_score, highest_type_array]
	
	## 空数组返回0分和空骰型
	if attack_slime_array_info == []:
		return [0, [], []]
	## 初始化最高分和最高分组合名称数组
	var highest_score := 0
	var highest_type_array := []
	var highest_dice_array := []
	## 基准骰子
	var base_dice: Array = attack_slime_array_info[0]
	## 剩余骰子
	var other_dice_array: Array
	if attack_slime_array_info.size() > 1:
		other_dice_array = attack_slime_array_info.slice(1)
	else:
		other_dice_array = []
	## 基准骰子单独情况
	var base_score: int = score_dict[base_dice[1]]
	var count_total_score_tmp = count_total_score(other_dice_array)
	var other_dice_score: int = count_total_score_tmp[0]
	var other_type_array = count_total_score_tmp[1]
	var other_dice_group_array = count_total_score_tmp[2]
	highest_score = base_score + other_dice_score
	highest_type_array = ["none"] + other_type_array
	highest_dice_array = [2] + other_dice_group_array
	## 剩余骰子数量
	var dice_num: int = other_dice_array.size()
	## 遍历除了单骰子情况其余情况
	#for mask in range(1, 2 ^ dice_num - 1 ):
	for mask in range(1, 1 << dice_num):
		## 当前骰子组合
		var current_dice_group: Array = [base_dice]
		## 剩余骰子组合
		var other_dice_group: Array = []
		## 根据位掩码创建组合
		for dice_index in range(dice_num):
			if (mask >> dice_index) & 1 == 1:
				## 剩余骰子[dice_index] 加入 当前骰子组合
				current_dice_group.append(other_dice_array[dice_index])
			else:
				## 剩余骰子[dice_index] 加入 剩余骰子组合
				other_dice_group.append(other_dice_array[dice_index])
		## 计算当前骰子组的最高分和最高分组合名
		var count_highest_score_result = count_highest_score(current_dice_group)
		var current_dice_group_score = count_highest_score_result[1]
		var current_dice_type_array = count_highest_score_result[0]
		var current_dice_group_size = count_highest_score_result[2].size()
		## 递归计算剩余骰子组总分和组合名称
		var count_total_score_result = count_total_score(other_dice_group)
		var other_dice_group_score = count_total_score_result[0]
		var iter_dice_type_array = count_total_score_result[1]
		var iter_dice_group_array = count_total_score_result[2]
		## 这种组合的得分和组合名
		var total_score = current_dice_group_score + other_dice_group_score
		var all_dice_type_array = [current_dice_type_array] + iter_dice_type_array
		var all_dice_group_size = [current_dice_group_size] + iter_dice_group_array
		## 更新最高分和组合名称
		if total_score > highest_score:
			highest_score = total_score
			highest_type_array = all_dice_type_array
			highest_dice_array = all_dice_group_size
		## 返回最高分组合
	return [highest_score, highest_type_array, highest_dice_array]

## 计算选中的最高最终骰型
## return ['none', round(none_score_dice[0]), none_score_dice[1]]
## [<类型>, <分数>, <参与计算的骰子数组>]
static func count_highest_score(attack_slime_array_info):
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
	
## 对子算法
static func _count_duizi(attack_slime_array_info):
	var score_dict := {
		1: Current.one_score,
		2: Current.two_score,
		3: Current.three_score,
		4: Current.four_score,
		5: Current.five_score,
		6: Current.six_score
	}
	var point_dict := {1: [], 2: [], 3: [], 4: [], 5: [], 6: []}
	for point in attack_slime_array_info:
		point_dict[point[1]].append(point[1])
	var score := 0.0
	var tmp_item := []
	for v in point_dict.values():
		var tmp_score := 0.0
		if v.size() >= 2:
			for point in v:
				tmp_score += score_dict[point]
			tmp_score = tmp_score * (Current.dice_multiplier_dict[v.size()]["duizi"] / 100.0)
			if tmp_score > score:
				score = tmp_score
				tmp_item = v
	return [score, tmp_item]

## 顺子算法
static func _count_shunzi(attack_slime_array_info):
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
	var tmp_array := []
	var unique_porint_array := []
	for point in attack_slime_array_info:
		if not unique_porint_array.has(point[1]):
			unique_porint_array.append(point[1])
	unique_porint_array.sort()
	tmp_array.append(unique_porint_array.pop_front())
	for point in unique_porint_array:
		if point == tmp_array[-1] + 1:
			tmp_array.append(point)
		else:
			if tmp_array.size() >= 2:
				for sub_point in tmp_array:
					tmp_score += score_dict[sub_point]
				tmp_score = tmp_score * (Current.dice_multiplier_dict[tmp_array.size()]["shunzi"] / 100.0)
				if tmp_score > score:
					score = tmp_score
					tmp_item = tmp_array
				tmp_score = 0
			tmp_array = [point]
	if tmp_array.size() >= 2:
		for sub_point in tmp_array:
			tmp_score += score_dict[sub_point]
		tmp_score = tmp_score * (Current.dice_multiplier_dict[tmp_array.size()]["shunzi"] / 100.0)
		if tmp_score > score:
			score = tmp_score
			tmp_item = tmp_array
	return [score, tmp_item]

## 同色算法
static func _count_tongse(attack_slime_array_info):
	var score_dict := {
		1: Current.one_score,
		2: Current.two_score,
		3: Current.three_score,
		4: Current.four_score,
		5: Current.five_score,
		6: Current.six_score
	}
	var color_dict := {"red": [], "yellow": [], "green": [], "blue": []}
	for point in attack_slime_array_info:
		color_dict[point[0]].append(point[1])
	var score := 0.0
	var tmp_item := []
	for v in color_dict.values():
		var tmp_score := 0.0
		if  v.size() >= 2:
			for point in v:
				tmp_score += score_dict[point]
			tmp_score = tmp_score * (Current.dice_multiplier_dict[v.size()]["tongse"] / 100.0)
			if tmp_score > score:
				score = tmp_score
				tmp_item = v
	return [score, tmp_item]

## 同色对子算法
static func _count_tongdui(attack_slime_array_info):
	var score_dict := {
		1: Current.one_score,
		2: Current.two_score,
		3: Current.three_score,
		4: Current.four_score,
		5: Current.five_score,
		6: Current.six_score
	}
	var color_dict := {"red": [], "yellow": [], "green": [], "blue": []}
	for point in attack_slime_array_info:
		color_dict[point[0]].append(point[1])
	var score := 0.0
	var tmp_array := []
	var tmp_item := []
	for v in color_dict.values():
		if  v.size() >= 2:
			tmp_array.append(v)
	for same_color in tmp_array:
		var point_dict := {1: [], 2: [], 3: [], 4: [], 5: [], 6: []}
		for point in same_color:
			point_dict[point].append(point)
		for v in point_dict.values():
			var tmp_score := 0.0
			if v.size() >= 2:
				for sub_point in v:
					tmp_score += score_dict[sub_point]
				tmp_score = tmp_score * (Current.dice_multiplier_dict[v.size()]["tongdui"] / 100.0)
				if tmp_score > score:
					score = tmp_score
					tmp_item = v
	return [score, tmp_item]

## 同色顺子算法
static func _count_tongshun(attack_slime_array_info):
	var score_dict := {
		1: Current.one_score,
		2: Current.two_score,
		3: Current.three_score,
		4: Current.four_score,
		5: Current.five_score,
		6: Current.six_score
	}
	var color_dict := {"red": [], "yellow": [], "green": [], "blue": []}
	for point in attack_slime_array_info:
		color_dict[point[0]].append(point[1])
	var score := 0.0
	var tmp_score := 0.0
	var same_color_array := []
	var tmp_item := []
	for v in color_dict.values():
		if  v.size() >= 2:
			same_color_array.append(v)
	for same_color in same_color_array:
		var tmp_array := []
		var unique_porint_array := []
		for point in same_color:
			if not unique_porint_array.has(point):
				unique_porint_array.append(point)
		unique_porint_array.sort()
		tmp_array.append(unique_porint_array.pop_front())
		for point in unique_porint_array:
			if point == tmp_array[-1] + 1:
				tmp_array.append(point)
			else:
				if tmp_array.size() >= 2:
					for sub_point in tmp_array:
						tmp_score += score_dict[sub_point]
					tmp_score = tmp_score * (Current.dice_multiplier_dict[tmp_array.size()]["tongshun"] / 100.0)
					if tmp_score > score:
						score = tmp_score
						tmp_item = tmp_array
					tmp_score = 0
				tmp_array = [point]
		if tmp_array.size() >= 2:
			for sub_point in tmp_array:
				tmp_score += score_dict[sub_point]
			tmp_score = tmp_score * (Current.dice_multiplier_dict[tmp_array.size()]["tongshun"] / 100.0)
			if tmp_score > score:
				score = tmp_score
				tmp_item = tmp_array
			tmp_score = 0
	return [score, tmp_item]

## 无骰型法
static func _count_none(attack_slime_array_info):
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
