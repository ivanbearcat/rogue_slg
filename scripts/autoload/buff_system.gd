extends Node2D

## ⚠️ 存档密钥盐片段 C（三段散落常量之一，完整密钥不出现在任何单一文件；
## 其余片段见 save_manager.gd / current.gd。改动任一片段会使现有存档失效 → 走坏档路径）
const _SAVE_SALT_C := "RG|SALT|C|b37f08e4d5a921c6"

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
		## 飘字图标归属窗口：本 buff 执行期间弹出的得分数字带其图标（读取方见 EffectManager.float_context_buff）
		EffectManager.float_context_buff = buff
		await buff.process_buff()
		EffectManager.float_context_buff = null
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
		EffectManager.float_context_buff = buff
		await buff.process_buff()
		EffectManager.float_context_buff = null
		_track_family_contribution(buff, before)
	## ELITE: process only
	for buff in pipeline["ELITE"]:
		if "drop_bonus_trigger" in buff.tags:
			continue
		var before := Current.total_score
		EffectManager.float_context_buff = buff
		await buff.process_buff()
		EffectManager.float_context_buff = null
		_track_family_contribution(buff, before)
	## ALWAYS: process only
	for buff in pipeline["ALWAYS"]:
		if "drop_bonus_trigger" in buff.tags:
			continue
		var before := Current.total_score
		EffectManager.float_context_buff = buff
		await buff.process_buff()
		EffectManager.float_context_buff = null
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
				if buff.buff_meta.get("buff_id", buff.buff_meta.get("debuff_id", "")) == buff_id:
					return true
	return false

## 按 buff_id/debuff_id 查找首个匹配的 buff 实例，未找到返回 null
func get_buff_instance(buff_id: String) -> Buff:
	for timing in TIMINGS:
		for key in LIFECYCLE_KEYS:
			for buff in pipelines[timing][key]:
				if buff.buff_meta.get("buff_id", buff.buff_meta.get("debuff_id", "")) == buff_id:
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

## 新局清空全部 buff（含 ALWAYS/ONCE/shop 生命周期，过关清理不覆盖）
## 由战局入口 game_manager._ready 的 run_start 重置链调用（再玩一次/退出重开/新局进入）
## 语义边界：run 级清理为静默丢弃——不调用旧实例的 clear_buff()（不执行恢复逻辑，
## 旧局快照回写会污染新局 reset 后的初始状态），不触碰已随旧场景释放的展示节点；
## 新局初始状态由 Current.reset_run_state() 的重置链独立确定。
func clear_run_buffs() -> void:
	for timing in TIMINGS:
		for key in LIFECYCLE_KEYS:
			pipelines[timing][key].clear()
	_initialized_buff_ids.clear()
	_last_family_accumulation = {}
	_current_family_accumulation = {}

## ============================================================
## 存档序列化（读档恢复路径专用，由 SaveManager 调用）
## ============================================================

## 快照导出：管线内全部 buff 实例 → 行列表 [{id, lifecycle, timing, local_state}]。
## 同一实例注册到多个时序（如 scorched_earth 双时序）只产出首行，
## timing 收敛为 Array；重建时按行恢复"一实例多管线"的原始结构。
## timing 存管线名（"pre_attack" 等，非配置里的 "xxx_buff" 字符串）。
func save_buff_rows() -> Array:
	var rows: Array = []
	var seen := {}  ## instance_id → 行下标（多时序实例去重）
	for timing in TIMINGS:
		for key in LIFECYCLE_KEYS:
			for buff in pipelines[timing][key]:
				if not is_instance_valid(buff):
					continue
				var uid: int = buff.get_instance_id()
				if seen.has(uid):
					var row: Dictionary = rows[seen[uid]]
					if row["timing"] is Array:
						row["timing"].append(timing)
					else:
						row["timing"] = [row["timing"], timing]
					continue
				var buff_id = buff.buff_meta.get("buff_id", buff.buff_meta.get("debuff_id", ""))
				rows.append({
					"id": buff_id,
					"lifecycle": _lifecycle_int(key),
					"timing": timing,
					"local_state": buff.save_state(),
				})
				seen[uid] = rows.size() - 1
	return rows

## 从存档行重建管线：按 id 查 buff/debuff JSON 配置实例化 → 注册进对应管线
## （set_buff() 挂图标/tooltip）→ restore_state() 恢复实例本地状态。
##
## ⚠️ 重建次序与副作用审计结论（task 3.3，design Risks 对应项）：
## game_manager._ready 恢复分支的次序是"先 rebuild_from_save、后 SaveManager.apply()"。
## 快照清单内各 set_buff() 的 Current 数值副作用已逐一审计：
##   armor_break（防御-2）、iron_stomach（减伤=1）、desperation_overlord（免死标记重置）、
##   drop_ban（掉落格清空）——它们的 Current 写入随后全部被 apply() 用快照值覆盖中和；
##   其余快照清单内 buff 的 set_buff() 仅挂图标/tooltip（color_brand/resonance_chain/
##   rush 系/life_barrier 等已逐个核对），重建安全。
## 因此恢复路径唯一需要保证的是实例本地状态（restore_state）与快照一致。
func rebuild_from_save(rows: Array) -> void:
	## 防御性清空：恢复前不应有残留注册
	for timing in TIMINGS:
		for key in LIFECYCLE_KEYS:
			pipelines[timing][key].clear()
	_initialized_buff_ids.clear()
	for row in rows:
		if not row is Dictionary:
			continue
		var buff_id := str(row.get("id", ""))
		var timing_v: Variant = row.get("timing", "")
		var lifecycle := int(row.get("lifecycle", buff_type.ALWAYS))
		## timing 为 String 或 Array（多时序实例）；所有时序名必须合法
		var timings: Array = timing_v if timing_v is Array else [timing_v]
		var timings_valid := not buff_id.is_empty()
		for t in timings:
			if not (t in TIMINGS):
				timings_valid = false
		if not timings_valid:
			print("[BuffSystem] 存档重建：跳过无效行 ", buff_id)
			continue
		var config := _find_save_config(buff_id)
		if config.is_empty():
			print("[BuffSystem] 存档重建：跳过无配置的 buff: ", buff_id)
			continue
		var res_path := str(config.get("buff_res", config.get("debuff_res", "")))
		if not ResourceLoader.exists(res_path):
			print("[BuffSystem] 存档重建：脚本不存在，跳过: ", buff_id, " ", res_path)
			continue
		var buff = load(res_path).new(config, game_manager)
		for t in timings:
			set_buff(t, buff, lifecycle)
		buff.restore_state(row.get("local_state", {}))

## 按 id 在 buff.json（buff_id）→ debuff.json（debuff_id）中查找配置行
func _find_save_config(buff_id: String) -> Dictionary:
	var buff_data: Array = game_manager.buff_json_data if \
		game_manager and game_manager.get("buff_json_data") != null else \
		Tools.load_json_file("res://config/buff.json")
	for row in buff_data:
		if str(row.get("buff_id", "")) == buff_id:
			return row
	var debuff_data: Array = game_manager.debuff_json_data if \
		game_manager and game_manager.get("debuff_json_data") != null else \
		Tools.load_json_file("res://config/debuff.json")
	for row in debuff_data:
		if str(row.get("debuff_id", "")) == buff_id:
			return row
	return {}

func _lifecycle_int(key: String) -> int:
	match key:
		"ONCE":
			return buff_type.ONCE
		"STAGE":
			return buff_type.STAGE
		"ALWAYS":
			return buff_type.ALWAYS
		"ELITE":
			return buff_type.ELITE
	return buff_type.ALWAYS

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
