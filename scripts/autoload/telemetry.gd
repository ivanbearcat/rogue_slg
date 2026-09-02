extends Node

## 遥测:战局数据以 JSONL 事件流落盘(user://telemetry/,每局一个文件)
## 埋点通过 EventBus 事件订阅,公共信封字段直接读 Current 标量,埋点处只传 id/价格等最小 payload。

const SCHEMA_VER := 1
const TELEMETRY_DIR := "user://telemetry"
const DEVICE_CFG_PATH := "user://telemetry/device.cfg"

## 客户端版本(项目未设置版本号/为空时记 "dev",_ready 中解析)
var client_ver: String = "dev"
## 设备匿名 id(安装级,首次生成后持久化)
var device_id: String = ""
## 当前 run 的 id 与文件路径(run_end 后置空,防止后续事件写入旧文件)
var run_id: String = ""
var run_file_path: String = ""
## 写盘失败后禁用遥测(静默降级,不影响游戏)
var _disabled: bool = false

## 本 run 内存累积:buff 清单 [{id, source, acquired_stage}]
var _run_buffs: Array = []
## 本关金币技能使用明细 [{id, round}]
var _stage_coin_skills_used: Array = []
## 本关血瓶使用次数
var _stage_potions_used: int = 0
## 本关开始时刻(Unix 秒,float)
var _stage_start_ts: float = 0.0


func _ready() -> void:
	## client_ver:application/config/version 存在但可能为空串,空值记 "dev"
	var raw_ver := str(ProjectSettings.get_setting("application/config/version", "dev"))
	if not raw_ver.is_empty():
		client_ver = raw_ver
	_ensure_dir()
	device_id = _load_or_create_device_id()
	## 订阅全部埋点事件(EventBus 回调只收到 payload,不含事件名)
	EventBus.subscribe("run_start", _on_run_start)
	EventBus.subscribe("stage_start", _on_stage_start)
	EventBus.subscribe("stage_clear", _on_stage_clear)
	EventBus.subscribe("shop_tx", _on_shop_tx)
	EventBus.subscribe("buff_acquired", _on_buff_acquired)
	EventBus.subscribe("coin_skill_used", _on_coin_skill_used)
	EventBus.subscribe("potion_used", _on_potion_used)
	EventBus.subscribe("run_end", _on_run_end)
	## 订阅现成 clear_stage_buff 事件:过关时清掉累积清单中 STAGE/ELITE 生命周期的条目
	EventBus.subscribe("clear_stage_buff", _on_clear_stage_buff)


## ============================================================
## EventBus 事件处理
## ============================================================

## 新 run 开始:生成 run_id 与文件路径,重置累积结构
func _on_run_start(hero_id: String) -> void:
	run_id = _random_hex(8)
	var ts: Dictionary = Time.get_datetime_dict_from_system()
	var stamp := "%04d%02d%02d_%02d%02d%02d" % [
		ts.year, ts.month, ts.day, ts.hour, ts.minute, ts.second
	]
	run_file_path = TELEMETRY_DIR + "/run_%s_%s.jsonl" % [stamp, run_id]
	_run_buffs = []
	_stage_coin_skills_used = []
	_stage_potions_used = 0
	_stage_start_ts = Time.get_unix_time_from_system()
	_safe_write("run_start", {"hero": hero_id, "client_ver": client_ver})


## 关卡开始:重置本关累积,记录起点(含目标分/等级/经验/血瓶数)
func _on_stage_start() -> void:
	_stage_coin_skills_used = []
	_stage_potions_used = 0
	_stage_start_ts = Time.get_unix_time_from_system()
	_safe_write("stage_start", {
		"target_score": Current.target_score,
		"level": Current.level,
		"exp": Current.hero_exp,
		"potions": Current.potion_count,
	})


## 过关:合成用时/回合数/金币分解/buff/金币技能/血瓶明细
func _on_stage_clear(stage_coin: int, hp_coin: int, dice_coin: int) -> void:
	var duration := Time.get_unix_time_from_system() - _stage_start_ts
	_safe_write("stage_clear", {
		"duration_sec": snappedf(duration, 0.1),
		"rounds_used": Current.count_round,
		"coins_earned": {"stage": stage_coin, "hp": hp_coin, "highest_dice": dice_coin},
		"buffs": _run_buffs.duplicate(true),
		"coin_skills_used": _stage_coin_skills_used.duplicate(true),
		"potions_used": _stage_potions_used,
	})


## 商店交易:buff 购买 / 金币技能购买 / buff 刷新
func _on_shop_tx(tx_type: String, item_id: String, price: int) -> void:
	_safe_write("shop_tx", {"tx_type": tx_type, "item_id": item_id, "price": price})


## buff/debuff 获得:写事件行并累积到本 run 清单(source: shop/elite/boss/stage)
func _on_buff_acquired(id: String, source: String) -> void:
	_run_buffs.append({"id": id, "source": source, "acquired_stage": Current.count_stage})
	_safe_write("buff_acquired", {"id": id, "source": source})


## 金币技能使用:写事件行并累积到本关明细(玩家点击唯一收口,含替换后技能)
func _on_coin_skill_used(skill_id: String) -> void:
	_stage_coin_skills_used.append({"id": skill_id, "round": Current.count_round})
	_safe_write("coin_skill_used", {"id": skill_id})


## 血瓶使用:写事件行,本关计数 +1
func _on_potion_used() -> void:
	_stage_potions_used += 1
	_safe_write("potion_used", {})


## run 结束:记录结果后清空当前 run 引用
func _on_run_end(result: String) -> void:
	_safe_write("run_end", {"result": result})
	run_id = ""
	run_file_path = ""


## 过关清 buff(现成事件):移除累积清单中 STAGE/ELITE 生命周期的条目
## source 与生命周期映射:shop=ALWAYS 保留;elite/boss=ELITE、stage=STAGE 清除
func _on_clear_stage_buff() -> void:
	_run_buffs = _run_buffs.filter(func(buff: Dictionary) -> bool:
		return buff["source"] == "shop"
	)


## ============================================================
## 落盘
## ============================================================

## 组装公共信封 + payload,单行 JSON 追加写入当前 run 文件
## 失败时 push_warning 一次并置 _disabled,后续跳过(静默降级,不阻塞游戏)
func _safe_write(event: String, payload: Dictionary) -> void:
	if _disabled or run_file_path.is_empty():
		return
	var record := {
		"schema_ver": SCHEMA_VER,
		"event": event,
		"ts": Time.get_unix_time_from_system(),
		"device_id": device_id,
		"run_id": run_id,
		"stage": Current.count_stage,
		"round": Current.count_round,
		"coins": Current.total_coins,
		"hp": Current.player_hp,
		"score": Current.total_score,
	}
	record.merge(payload, true)
	_ensure_dir()
	## READ_WRITE = 非截断读写(要求文件已存在);首次创建用 WRITE_READ
	## 注意:Godot 4.7 Windows 下 WRITE_READ 打开即清空,已存在的文件必须用 READ_WRITE 追加
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(run_file_path) else FileAccess.WRITE_READ
	var file := FileAccess.open(run_file_path, mode)
	if file == null:
		_disable_after_write_failure()
		return
	file.seek_end()
	file.store_line(JSON.stringify(record))
	file.flush()
	## flush 后释放 FileAccess 引用即关闭句柄(逐行 append,崩溃时已写行不丢)
	file = null


## 首次写盘失败:警告一次后禁用遥测
func _disable_after_write_failure() -> void:
	_disabled = true
	push_warning("[Telemetry] 写盘失败,遥测已禁用: %s (error=%s)" % [
		run_file_path, error_string(FileAccess.get_open_error())
	])


## ============================================================
## 基础设施
## ============================================================

## 确保遥测目录存在
func _ensure_dir() -> void:
	DirAccess.make_dir_recursive_absolute(TELEMETRY_DIR)


## 读取或首次生成 device_id(ConfigFile 持久化,16 字节随机 hex)
func _load_or_create_device_id() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(DEVICE_CFG_PATH) == OK:
		var saved: Variant = cfg.get_value("device", "id", "")
		if saved is String and not (saved as String).is_empty():
			return saved
	_ensure_dir()
	var new_id := _random_hex(32)
	cfg.set_value("device", "id", new_id)
	cfg.save(DEVICE_CFG_PATH)
	return new_id


## 生成指定长度的随机 hex 字符串
func _random_hex(length: int) -> String:
	var bytes := Crypto.new().generate_random_bytes(ceili(length / 2.0))
	return bytes.hex_encode().substr(0, length)
