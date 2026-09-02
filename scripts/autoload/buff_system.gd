extends Node2D

## game_manager引用（跟随 Current 注册状态，场景切换后自动指向新战局）
var game_manager: Node2D:
	get:
		return Current.game_manager

var resonance_ramp: float = 0.0
var _last_family_accumulation: Dictionary = {}
var _current_family_accumulation: Dictionary = {}
## 当前正在执行的时序（pre_attack/post_attack/pre_enemy_turn/pre_hero_turn/post_hero_move）
## do_buff 开始时设置，结束时清空。供 buff.process_buff() 内部区分调用时序
var _current_timing: String = ""
## 记录已初始化的buff实例，避免同一实例注册到多个pipeline时重复调用set_buff()
var _initialized_buff_ids: Dictionary = {}

enum buff_type {
	ONCE,
	STAGE,
	ALWAYS,
	ELITE
}

## 数据驱动管线：5时序 × 4生命周期
var pipelines: Dictionary = {}

const TIMINGS := ["pre_attack", "post_attack", "pre_enemy_turn", "pre_hero_turn", "post_hero_move"]
const LIFECYCLE_KEYS := ["ONCE", "STAGE", "ALWAYS", "ELITE"]

func _ready() -> void:
	## 初始化5个管线，每个包含4个空数组
	for timing in TIMINGS:
		pipelines[timing] = {}
		for key in LIFECYCLE_KEYS:
			pipelines[timing][key] = []
	EventBus.subscribe("clear_stage_buff", clear_stage_buff)
	EventBus.subscribe("clear_elite_buff", clear_elite_buff)
	EventBus.subscribe("do_pre_attack_buff", do_pre_attack_buff)
	EventBus.subscribe("do_post_attack_buff", do_post_attack_buff)
	EventBus.subscribe("do_pre_enemy_turn_buff", do_pre_enemy_turn_buff)
	EventBus.subscribe("do_pre_hero_turn_buff", do_pre_hero_turn_buff)
	EventBus.subscribe("do_post_hero_move_buff", do_post_hero_move_buff)

## ============================================================
## 通用管线方法
## ============================================================

func set_buff(timing: String, buff: Object, lifecycle: int) -> void:
	var key = _lifecycle_key(lifecycle)
	pipelines[timing][key].append(buff)
	## 同一buff实例注册到多个pipeline时，set_buff()只调用一次
	var uid = buff.get_instance_id()
	if not _initialized_buff_ids.has(uid):
		_initialized_buff_ids[uid] = true
		buff.set_buff()

func do_buff(timing: String) -> void:
	var pipeline = pipelines[timing]
	_current_timing = timing
	_current_family_accumulation.clear()
	## ONCE: process + clear + remove
	var once_to_remove := []
	for buff in pipeline["ONCE"]:
		if "drop_bonus_trigger" in buff.tags:
			continue
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before)
		buff.clear_buff()
		once_to_remove.append(buff)
	for buff in once_to_remove:
		pipeline["ONCE"].erase(buff)
	## STAGE: process only
	for buff in pipeline["STAGE"]:
		if "drop_bonus_trigger" in buff.tags:
			continue
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before)
	## ELITE: process only
	for buff in pipeline["ELITE"]:
		if "drop_bonus_trigger" in buff.tags:
			continue
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before)
	## ALWAYS: process only
	for buff in pipeline["ALWAYS"]:
		if "drop_bonus_trigger" in buff.tags:
			continue
		var before := Current.total_score
		await buff.process_buff()
		_track_family_contribution(buff, before)
	## 保存家族累积供查询
	_last_family_accumulation = _current_family_accumulation.duplicate()
	_current_timing = ""

func _lifecycle_key(lifecycle: int) -> String:
	match lifecycle:
		buff_type.ONCE:
			return "ONCE"
		buff_type.STAGE:
			return "STAGE"
		buff_type.ALWAYS:
			return "ALWAYS"
		buff_type.ELITE:
			return "ELITE"
	return "ALWAYS"

## ============================================================
## 向后兼容的 public API wrapper
## ============================================================

func set_pre_attack_buff(buff: Object, type: buff_type):
	set_buff("pre_attack", buff, type)

func set_post_attack_buff(buff: Object, type: buff_type):
	set_buff("post_attack", buff, type)

func set_pre_enemy_turn_buff(buff: Object, type: buff_type):
	set_buff("pre_enemy_turn", buff, type)

func set_pre_hero_turn_buff(buff: Object, type: buff_type):
	set_buff("pre_hero_turn", buff, type)

func set_post_hero_move_buff(buff: Object, type: buff_type):
	set_buff("post_hero_move", buff, type)

func do_pre_attack_buff():
	do_buff("pre_attack")

func do_post_attack_buff():
	do_buff("post_attack")

func do_pre_enemy_turn_buff():
	do_buff("pre_enemy_turn")

func do_pre_hero_turn_buff():
	do_buff("pre_hero_turn")

func do_post_hero_move_buff():
	do_buff("post_hero_move")

## ============================================================
## 家族/标签查询 API
## ============================================================

func is_buff_registered(buff_id: String) -> bool:
	for timing in TIMINGS:
		for key in LIFECYCLE_KEYS:
			for buff in pipelines[timing][key]:
				if buff.buff_meta.get("buff_id", "") == buff_id:
					return true
	return false

## 按 buff_id 查找首个匹配的 buff 实例，未找到返回 null
func get_buff_instance(buff_id: String) -> Buff:
	for timing in TIMINGS:
		for key in LIFECYCLE_KEYS:
			for buff in pipelines[timing][key]:
				if buff.buff_meta.get("buff_id", "") == buff_id:
					return buff
	return null

func get_family_count(family_name: String) -> int:
	var count := 0
	for timing in TIMINGS:
		for key in LIFECYCLE_KEYS:
			for buff in pipelines[timing][key]:
				if buff.family == family_name:
					count += 1
	return count

func get_family_buffs(family_name: String) -> Array:
	var result := []
	for timing in TIMINGS:
		for key in LIFECYCLE_KEYS:
			for buff in pipelines[timing][key]:
				if buff.family == family_name:
					result.append(buff)
	return result

func get_buffs_by_tag(tag: String) -> Array:
	var result := []
	for timing in TIMINGS:
		for key in LIFECYCLE_KEYS:
			for buff in pipelines[timing][key]:
				if tag in buff.tags:
					result.append(buff)
	return result

func get_family_accumulation(family: String) -> int:
	if _current_family_accumulation.has(family):
		return _current_family_accumulation[family]
	return 0

## ============================================================
## 清理
## ============================================================

func clear_stage_buff():
	clear_elite_buff()
	for timing in TIMINGS:
		for buff in pipelines[timing]["STAGE"]:
			buff.clear_buff()
		pipelines[timing]["STAGE"].clear()
	## resonance_ramp 永久跨关卡保留，不重置
	_last_family_accumulation = {}

func clear_elite_buff():
	for timing in TIMINGS:
		for buff in pipelines[timing]["ELITE"]:
			buff.clear_buff()
		pipelines[timing]["ELITE"].clear()

## ============================================================
## 内部辅助
## ============================================================

func _track_family_contribution(buff: Buff, score_before: int) -> void:
	if buff.family == "":
		return
	var delta := Current.total_score - score_before
	if delta > 0:
		if not _current_family_accumulation.has(buff.family):
			_current_family_accumulation[buff.family] = 0
		_current_family_accumulation[buff.family] += delta
		## 共鸣叠层：正向贡献且共鸣系≥4时，resonance_ramp += 0.01（永久，无上限）
		## 领主buff(auto_activate)不叠加ramp，避免自身触发导致雪崩式增长
		if buff.family == "resonance" and get_family_count("resonance") >= 4 and not buff.buff_meta.get("auto_activate", false):
			resonance_ramp += 0.01

## 获取指定时序的所有buff数组（用于game_manager直接访问数组）
func _get_timing_arrays(timing: String) -> Array:
	if pipelines.has(timing):
		return [pipelines[timing]["ONCE"], pipelines[timing]["STAGE"], pipelines[timing]["ALWAYS"], pipelines[timing]["ELITE"]]
	return []

## 获取所有时序的所有buff数组（用于遍历全部buff）
func _get_all_buff_arrays() -> Array:
	var result: Array = []
	for timing in TIMINGS:
		for key in LIFECYCLE_KEYS:
			result.append(pipelines[timing][key])
	return result
