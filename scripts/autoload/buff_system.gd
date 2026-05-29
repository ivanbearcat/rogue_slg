extends Node2D

@onready var game_manager: Node2D = $"/root/game_manager"

var pre_attack_buff_once: Array
var pre_attack_buff_stage: Array
var pre_attack_buff_always: Array
var pre_attack_buff_elite: Array
var post_attack_buff_once: Array
var post_attack_buff_stage: Array
var post_attack_buff_always: Array
var post_attack_buff_elite: Array
var pre_enemy_turn_buff_once: Array
var pre_enemy_turn_buff_stage: Array
var pre_enemy_turn_buff_always: Array
var pre_enemy_turn_buff_elite: Array
var pre_hero_turn_buff_once: Array
var pre_hero_turn_buff_stage: Array
var pre_hero_turn_buff_always: Array
var pre_hero_turn_buff_elite: Array
var post_hero_move_buff_once: Array
var post_hero_move_buff_stage: Array
var post_hero_move_buff_always: Array
var post_hero_move_buff_elite: Array

func _ready() -> void:
	EventBus.subscribe("clear_stage_buff", clear_stage_buff)
	EventBus.subscribe("clear_elite_buff", clear_elite_buff)
	EventBus.subscribe("do_pre_attack_buff", do_pre_attack_buff)
	EventBus.subscribe("do_post_attack_buff", do_post_attack_buff)
	EventBus.subscribe("do_pre_enemy_turn_buff", do_pre_enemy_turn_buff)
	EventBus.subscribe("do_pre_hero_turn_buff", do_pre_hero_turn_buff)
	EventBus.subscribe("do_post_hero_move_buff", do_post_hero_move_buff)

enum buff_type{
	ONCE,
	STAGE,
	ALWAYS,
	ELITE
}

## ============================================================
## 家族/标签查询 API
## ============================================================

## 检查指定 buff_id 是否已在系统中注册
func is_buff_registered(buff_id: String) -> bool:
	for arr in _get_all_buff_arrays():
		for buff in arr:
			if buff.buff_meta.get("buff_id", "") == buff_id:
				return true
	return false

## 获取指定家族的已注册 Buff 数量
func get_family_count(family_name: String) -> int:
	var count := 0
	for arr in _get_all_buff_arrays():
		for buff in arr:
			if buff.family == family_name:
				count += 1
	return count

## 获取包含指定标签的所有已注册 Buff
func get_buffs_by_tag(tag: String) -> Array:
	var result := []
	for arr in _get_all_buff_arrays():
		for buff in arr:
			if tag in buff.tags:
				result.append(buff)
	return result

## 获取所有 Buff 数组的引用（用于遍历）
func _get_all_buff_arrays() -> Array:
	return [
		pre_attack_buff_once, pre_attack_buff_stage, pre_attack_buff_always, pre_attack_buff_elite,
		post_attack_buff_once, post_attack_buff_stage, post_attack_buff_always, post_attack_buff_elite,
		pre_enemy_turn_buff_once, pre_enemy_turn_buff_stage, pre_enemy_turn_buff_always, pre_enemy_turn_buff_elite,
		pre_hero_turn_buff_once, pre_hero_turn_buff_stage, pre_hero_turn_buff_always, pre_hero_turn_buff_elite,
		post_hero_move_buff_once, post_hero_move_buff_stage, post_hero_move_buff_always, post_hero_move_buff_elite,
	]

## 获取指定时序的所有 Buff 数组（含 once/stage/always/elite）
func _get_timing_arrays(timing: String) -> Array:
	match timing:
		"pre_attack":
			return [pre_attack_buff_once, pre_attack_buff_stage, pre_attack_buff_always, pre_attack_buff_elite]
		"post_attack":
			return [post_attack_buff_once, post_attack_buff_stage, post_attack_buff_always, post_attack_buff_elite]
		"pre_enemy_turn":
			return [pre_enemy_turn_buff_once, pre_enemy_turn_buff_stage, pre_enemy_turn_buff_always, pre_enemy_turn_buff_elite]
		"pre_hero_turn":
			return [pre_hero_turn_buff_once, pre_hero_turn_buff_stage, pre_hero_turn_buff_always, pre_hero_turn_buff_elite]
		"post_hero_move":
			return [post_hero_move_buff_once, post_hero_move_buff_stage, post_hero_move_buff_always, post_hero_move_buff_elite]
	return []

## 族主 ×1.5 乘法逻辑：在管线末尾追加族主奖励
## 条件简化为仅检查 family_count >= 4（领主自动激活，无需注册检查）
func _apply_overlord_multiplier(timing: String, family_accumulation: Dictionary) -> void:
	for family_name in family_accumulation:
		var accumulated = family_accumulation[family_name]
		if accumulated <= 0:
			continue
		## 检查该族是否满足族主条件：同族已激活 Buff≥4
		var family_count = get_family_count(family_name)
		if family_count < 4:
			continue
		## 追加 ×0.5 的额外得分（等效 ×1.5）
		var bonus = int(accumulated * 0.5)
		if bonus > 0:
			Current.total_score += bonus
			## 族主激活飘字效果
			var float_number_instantiate = EffectManager.float_number_effect(bonus, "gold")
			Current.hero.add_child(float_number_instantiate)

## ============================================================
## 清理
## ============================================================

## 清理关卡buff
func clear_stage_buff():
	clear_elite_buff()
	for buff in pre_attack_buff_stage:
		buff.clear_buff()
	for buff in post_attack_buff_stage:
		buff.clear_buff()
	for buff in pre_enemy_turn_buff_stage:
		buff.clear_buff()
	for buff in pre_hero_turn_buff_stage:
		buff.clear_buff()
	for buff in post_hero_move_buff_stage:
		buff.clear_buff()
	pre_attack_buff_stage.clear()
	post_attack_buff_stage.clear()
	pre_enemy_turn_buff_stage.clear()
	pre_hero_turn_buff_stage.clear()
	post_hero_move_buff_stage.clear()

## 清理精英buff
func clear_elite_buff():
	for buff in pre_attack_buff_elite:
		buff.clear_buff()
	for buff in post_attack_buff_elite:
		buff.clear_buff()
	for buff in pre_enemy_turn_buff_elite:
		buff.clear_buff()
	for buff in pre_hero_turn_buff_elite:
		buff.clear_buff()
	for buff in post_hero_move_buff_elite:
		buff.clear_buff()
	pre_attack_buff_elite.clear()
	post_attack_buff_elite.clear()
	pre_enemy_turn_buff_elite.clear()
	pre_hero_turn_buff_elite.clear()
	post_hero_move_buff_elite.clear()

## ============================================================
## 攻击前
## ============================================================

func set_pre_attack_buff(buff: Object, type: buff_type):
	buff.set_buff()
	match type:
		buff_type.ONCE:
			pre_attack_buff_once.append(buff)
		buff_type.STAGE:
			pre_attack_buff_stage.append(buff)
		buff_type.ALWAYS:
			pre_attack_buff_always.append(buff)
		buff_type.ELITE:
			pre_attack_buff_elite.append(buff)

func do_pre_attack_buff():
	## 记录 total_score 快照用于族主累加
	var score_before := Current.total_score
	var family_accumulation := {}
	## once
	for buff in pre_attack_buff_once:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
		buff.clear_buff()
	pre_attack_buff_once = []
	## stage
	for buff in pre_attack_buff_stage:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	## elite
	for buff in pre_attack_buff_elite:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	## always
	for buff in pre_attack_buff_always:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	## 族主 ×1.5 乘法
	_apply_overlord_multiplier("pre_attack", family_accumulation)

## ============================================================
## 攻击后
## ============================================================

func set_post_attack_buff(buff: Object, type: buff_type):
	buff.set_buff()
	match type:
		buff_type.ONCE:
			post_attack_buff_once.append(buff)
		buff_type.STAGE:
			post_attack_buff_stage.append(buff)
		buff_type.ALWAYS:
			post_attack_buff_always.append(buff)
		buff_type.ELITE:
			post_attack_buff_elite.append(buff)

func do_post_attack_buff():
	var family_accumulation := {}
	## once
	for buff in post_attack_buff_once:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
		buff.clear_buff()
	post_attack_buff_once = []
	## stage
	for buff in post_attack_buff_stage:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	## elite
	for buff in post_attack_buff_elite:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	## always
	for buff in post_attack_buff_always:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	_apply_overlord_multiplier("post_attack", family_accumulation)

## ============================================================
## 敌人回合前
## ============================================================

func set_pre_enemy_turn_buff(buff: Object, type: buff_type):
	buff.set_buff()
	match type:
		buff_type.ONCE:
			pre_enemy_turn_buff_once.append(buff)
		buff_type.STAGE:
			pre_enemy_turn_buff_stage.append(buff)
		buff_type.ALWAYS:
			pre_enemy_turn_buff_always.append(buff)
		buff_type.ELITE:
			pre_enemy_turn_buff_elite.append(buff)

func do_pre_enemy_turn_buff():
	var family_accumulation := {}
	## once
	for buff in pre_enemy_turn_buff_once:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
		buff.clear_buff()
	pre_enemy_turn_buff_once = []
	## stage
	for buff in pre_enemy_turn_buff_stage:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	## elite
	for buff in pre_enemy_turn_buff_elite:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	## always
	for buff in pre_enemy_turn_buff_always:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	_apply_overlord_multiplier("pre_enemy_turn", family_accumulation)

## ============================================================
## 玩家回合前
## ============================================================

func set_pre_hero_turn_buff(buff: Object, type: buff_type):
	buff.set_buff()
	match type:
		buff_type.ONCE:
			pre_hero_turn_buff_once.append(buff)
		buff_type.STAGE:
			pre_hero_turn_buff_stage.append(buff)
		buff_type.ALWAYS:
			pre_hero_turn_buff_always.append(buff)
		buff_type.ELITE:
			pre_hero_turn_buff_elite.append(buff)

func do_pre_hero_turn_buff():
	var family_accumulation := {}
	## once
	for buff in pre_hero_turn_buff_once:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
		buff.clear_buff()
	pre_hero_turn_buff_once = []
	## stage
	for buff in pre_hero_turn_buff_stage:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	## elite
	for buff in pre_hero_turn_buff_elite:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	## always
	for buff in pre_hero_turn_buff_always:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	_apply_overlord_multiplier("pre_hero_turn", family_accumulation)

## ============================================================
## 玩家移动后
## ============================================================

func set_post_hero_move_buff(buff: Object, type: buff_type):
	buff.set_buff()
	match type:
		buff_type.ONCE:
			post_hero_move_buff_once.append(buff)
		buff_type.STAGE:
			post_hero_move_buff_stage.append(buff)
		buff_type.ALWAYS:
			post_hero_move_buff_always.append(buff)
		buff_type.ELITE:
			post_hero_move_buff_elite.append(buff)

func do_post_hero_move_buff():
	var family_accumulation := {}
	## once
	for buff in post_hero_move_buff_once:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
		buff.clear_buff()
	post_hero_move_buff_once = []
	## stage
	for buff in post_hero_move_buff_stage:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	## elite
	for buff in post_hero_move_buff_elite:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	## always
	for buff in post_hero_move_buff_always:
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before, family_accumulation)
	_apply_overlord_multiplier("post_hero_move", family_accumulation)

## ============================================================
## 内部辅助：追踪每个家族的得分贡献
## ============================================================

func _track_family_contribution(buff: Buff, score_before: int, family_accumulation: Dictionary) -> void:
	if buff.family == "":
		return
	var delta := Current.total_score - score_before
	if delta > 0:
		if not family_accumulation.has(buff.family):
			family_accumulation[buff.family] = 0
		family_accumulation[buff.family] += delta
