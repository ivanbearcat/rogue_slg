extends SceneTree

## 窗口关闭收口的外部回读（headless，task 4.3）
## 用法: godot --headless --path . --script res://test/scripts/save/save_close_checker.gd
## 前置: save_close_test.tscn 已跑完并退出进程（应已落盘最近回合边界快照）
## 断言: save.bin 存在 + 完整解码 + 版本识别 + 回合边界无锁 + 主档清形（无 save.corrupt）

var _passed := 0
var _failed := 0


func _init() -> void:
	await process_frame
	var sm: Node = root.get_node("SaveManager")
	_check("save.bin 存在（窗口关闭已落盘）", FileAccess.file_exists(sm.SAVE_PATH))
	_check("无 save.corrupt（非坏档路径）", not FileAccess.file_exists(sm.CORRUPT_PATH))
	var data: Dictionary = sm.read_save_data()
	_check("解码成功且版本识别", not data.is_empty())
	if not data.is_empty():
		_check("回合边界无锁（action_lock=false）", not bool(data.run_state.get("action_lock", true)))
		_check("回合边界公共锁为空", (data.run_state.get("public_lock_array", ["x"]) as Array).is_empty())
		print("[CLOSE-CHECK] 存档 meta: %s" % JSON.stringify(data.meta))
	print("=== SaveCloseChecker：通过 %d / 失败 %d ===" % [_passed, _failed])
	## 清理验证产物（保持 user:// 槽位干净）
	sm._remove_file(sm.SAVE_PATH)
	sm._remove_file(sm.STAGING_PATH)
	sm._remove_file(sm.CORRUPT_PATH)
	quit(1 if _failed > 0 else 0)


func _check(test_name: String, cond: bool) -> void:
	if cond:
		_passed += 1
		print("  [PASS] ", test_name)
	else:
		_failed += 1
		print("  [FAIL] ", test_name)
