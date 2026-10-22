extends SceneTree
## 存档编解码/原子写/坏档处置 单元测试（headless）
## 运行: godot --headless --path . --script res://test/scripts/save/save_codec_test.gd
## 注意：--script 主循环脚本在 autoload 注册前编译，autoload 一律运行时取用。
## 直接操作 user:// 下的存档文件（save.bin/save.tmp/save.corrupt），跑完清理。

var _passed := 0
var _failed := 0
var sm: Node  ## SaveManager autoload


func _init() -> void:
	await process_frame
	sm = root.get_node("SaveManager")
	_run_all()
	print("\n=== SaveCodec 测试：通过 %d / 失败 %d ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(test_name: String, cond: bool) -> void:
	if cond:
		_passed += 1
		print("  [PASS] ", test_name)
	else:
		_failed += 1
		print("  [FAIL] ", test_name)


func _clean_slot_files() -> void:
	for path in [sm.SAVE_PATH, sm.STAGING_PATH, sm.CORRUPT_PATH]:
		sm._remove_file(path)


func _run_all() -> void:
	print("=== SaveCodec 单元测试（headless）===")
	_clean_slot_files()

	## ---- 1) encode/decode roundtrip（task 1.2）----
	var original := {
		"save_version": 1,
		"meta": {"hero": "soldier", "stage": 3, "round": 7, "saved_at": "2026-01-01T00:00:00"},
		"run_state": {
			"total_score": 1234, "once_total_score": 0, "max_once_score": 56,
			"player_hp": 3, "max_hp": 5, "player_defense": 2,
			"potion_count": 2, "potion_max": 3,
			"scorched_earth_bonus": 0.35, "percent_score": 150.0,
			"has_death_immunity": true, "death_immunity_used": false,
			"drop_slot_dice": ["red", 3], "dice_multiplier_dict": {"2": {"duizi": 100}, "3": {"shunzi": 120}},
			"coin_skill_array_dict": [{"coin_skill_id": "reroll_all", "coin_skill_shop_cost": 5}],
			"coin_skill_used": [false, true],
			"killed_slime_colors": ["red", "blue"], "public_lock_array": [],
			"turn": "hero_turn", "action_lock": false,
			"pre_move_position": [0.0, 0.0], "pre_move_grid_index": [0, 0],
			"marker": "STGTESTMARK",
		},
		"board": {"hero": {"hero_grid_index": [3, 3], "hero_movement": 3}, "slimes": [], "pending": [], "last_created": []},
		"shop": {},
		"buffs": {"rows": []},
		"resonance_ramp": 0.05,
	}
	var payload: PackedByteArray = sm.encode(original)
	_check("encode 输出非空", payload.size() > 0)
	_check("magic 头为 RGSAVE1", payload.slice(0, 7).get_string_from_ascii() == "RGSAVE1")
	## JSON 往返会把所有数字收敛为 float（parse 侧无类型信息），深度相等
	## 断言以 JSON 归一化参照为准（真实快照链路中 apply_run_state 逐字段显式转回目标类型）
	var json_normalized: Variant = JSON.parse_string(JSON.stringify(original))
	var decoded: Variant = sm.decode(payload)
	_check("decode 返回 Dictionary", typeof(decoded) == TYPE_DICTIONARY)
	_check("roundtrip 与 JSON 归一化原 Dictionary 相等", typeof(decoded) == TYPE_DICTIONARY and decoded == json_normalized)
	## 落盘形态为非可读密文：整体字节流不含 schema 明文标记
	var as_text := payload.get_string_from_utf8()
	_check("密文不含 schema 明文标记", not as_text.contains("STGTESTMARK"))
	_check("密文不以 '{' 开头（非明文 JSON）", not as_text.begins_with("{"))

	## ---- 2) 篡改/截断/伪造 magic 均拒绝（task 1.2/1.3）----
	var tampered := payload.duplicate()
	tampered[tampered.size() - 1] ^= 0xFF
	_check("篡改 body 一个字节被 HMAC 拒绝", sm.decode(tampered) == null)
	_check("截断 payload 被拒", sm.decode(payload.slice(0, 30)) == null)
	var wrong_magic := payload.duplicate()
	wrong_magic[0] = 0x58  ## 'X'
	_check("magic 错误被拒", sm.decode(wrong_magic) == null)
	_check("空输入被拒", sm.decode(PackedByteArray()) == null)

	## ---- 3) flush 落盘 + has_valid_save（task 1.3/1.4）----
	## 注：open_encrypted 每次写入生成随机 IV，相同明文的两次 encode 密文不同——
	## 落盘校验以"解码结果 == 原数据"为准，不做密文字节级比较
	_check("无档时 has_valid_save=false", not sm.has_valid_save())
	_check("无快照 flush 返回 false", not sm.flush_to_disk())
	_check("flush 成功", sm.flush_to_disk(original))
	_check("save.bin 存在", FileAccess.file_exists(sm.SAVE_PATH))
	_check("落盘后暂存文件已清（原子 rename）", not FileAccess.file_exists(sm.STAGING_PATH))
	var disk_bytes: PackedByteArray = sm._read_file_bytes(sm.SAVE_PATH)
	var disk_decoded: Variant = sm.decode(disk_bytes)
	_check("盘上数据解码回原快照", typeof(disk_decoded) == TYPE_DICTIONARY and disk_decoded == json_normalized)
	_check("有档时 has_valid_save=true", sm.has_valid_save())
	var progress: Dictionary = sm.get_save_progress()
	_check("进度展示 关卡3·回合7", int(progress.get("stage", 0)) == 3 and int(progress.get("round", 0)) == 7)
	var reloaded: Dictionary = sm.read_save_data()
	_check("read_save_data 与快照相等", reloaded == json_normalized)

	## ---- 4) 版本不可识别按坏档处置（task 1.4）----
	var wrong_version: Dictionary = original.duplicate(true)
	wrong_version["save_version"] = 99
	var wv_bytes: PackedByteArray = sm.encode(wrong_version)
	var wf := FileAccess.open(sm.SAVE_PATH, FileAccess.WRITE)
	wf.store_buffer(wv_bytes)
	wf = null
	_check("版本不识别 has_valid_save=false", not sm.has_valid_save())
	_check("坏档已转存 save.corrupt", FileAccess.file_exists(sm.CORRUPT_PATH))
	_check("坏档已隔离（save.bin 删除）", not FileAccess.file_exists(sm.SAVE_PATH))
	var corrupt_bytes: PackedByteArray = sm._read_file_bytes(sm.CORRUPT_PATH)
	_check("save.corrupt 保留原字节", corrupt_bytes == wv_bytes)

	## ---- 5) 手工篡改真实档 → 失败分支 + save.corrupt + 无报错（task 1.3）----
	var good_bytes: PackedByteArray = sm.encode(original)
	var gf := FileAccess.open(sm.SAVE_PATH, FileAccess.WRITE)
	gf.store_buffer(good_bytes)
	gf = null
	_check("重放完整档 has_valid_save=true", sm.has_valid_save())
	var raw: PackedByteArray = sm._read_file_bytes(sm.SAVE_PATH)
	raw[raw.size() / 2] ^= 0x5A  ## 模拟外部截断/篡改
	var hf := FileAccess.open(sm.SAVE_PATH, FileAccess.WRITE)
	hf.store_buffer(raw)
	hf = null
	var bad_result: Dictionary = sm.read_save_data()
	_check("篡改档 read_save_data 返回空（失败分支）", bad_result.is_empty())
	_check("篡改档已转存 save.corrupt", FileAccess.file_exists(sm.CORRUPT_PATH))
	_check("篡改档已隔离", not FileAccess.file_exists(sm.SAVE_PATH))
	_check("隔离后 has_valid_save=false", not sm.has_valid_save())

	## ---- 6) flush 失败路径（task 4.2）：目标目录不可达时返回 false 且不崩溃 ----
	var ok_flush: bool = sm.flush_to_disk(original)
	_check("正常档重新落盘", ok_flush)
	_check("不存在目录的 flush 返回 false", not sm._atomic_write(payload, "user://no_such_dir/x.bin"))
	_check("失败路径不影响已有存档", sm.has_valid_save())

	## ---- 7) 写入中断模拟（task 7.3）：save.tmp 残留不构成可读档，下次落盘覆盖 ----
	var junk := PackedByteArray()
	junk.append_array("JUNK-JUNK-JUNK".to_ascii_buffer())
	var jf := FileAccess.open(sm.STAGING_PATH, FileAccess.WRITE)
	jf.store_buffer(junk)
	jf = null
	_check("残留 save.tmp 不被当作存档（bin 完整可读）", sm.has_valid_save())
	_check("残留 save.tmp 下再次 flush 成功", sm.flush_to_disk(original))
	_check("残留 save.tmp 被原子写覆盖清理", not FileAccess.file_exists(sm.STAGING_PATH))
	_check("save.bin 仍为最近完整档", sm.read_save_data() == json_normalized)
	## ---- 8) 无 bin 只有残留 tmp：等同无档（半档永不被读）----
	_clean_slot_files()
	var jf2 := FileAccess.open(sm.STAGING_PATH, FileAccess.WRITE)
	jf2.store_buffer(junk)
	jf2 = null
	_check("只有残留 tmp 时 has_valid_save=false", not sm.has_valid_save())

	_clean_slot_files()
