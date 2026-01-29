extends RefCounted

class_name ScoringAlgorithm

## 计算选中的最高最终骰型
## return ['none', round(none_score_dice[0]), none_score_dice[1]]
## [<类型>, <分数>, <参与计算的骰子数组>]
static func count_dice_type(attack_slime_array_info):
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
static func _count_tongse(attack_slime_array_info):
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
static func _count_tongdui(attack_slime_array_info):
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
static func _count_tongshun(attack_slime_array_info):
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
