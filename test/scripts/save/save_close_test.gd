extends Node

## 窗口关闭 = 退出即保存 验证（headless，task 4.3）
## 用法: godot --headless --path . res://test/scripts/save/save_close_test.tscn
## 流程: 启动战局 → 回合边界快照就绪 → 传播 NOTIFICATION_WM_CLOSE_REQUEST（等价用户点 X）
##       → SaveManager 落盘 + 进程收口退出 → 外部用 save_close_checker.gd 回读断言
## 本脚本自身不 quit：退出动作由 SaveManager 的关闭拦截执行（这正是被验证的行为）

func _ready() -> void:
	## 探针保活：摘除启动 current_scene 注册，避免被 change_scene 释放
	if get_tree().current_scene == self:
		get_tree().current_scene = null
	print("[CLOSE-TEST] === 窗口关闭收口验证开始 ===")
	## 清槽后启动战局（新 run 路径，等待 boot 回合边界快照）
	for path in [SaveManager.SAVE_PATH, SaveManager.STAGING_PATH, SaveManager.CORRUPT_PATH]:
		SaveManager._remove_file(path)
	SceneManager.change_scene(&"main")
	var got := await _wait_until(func() -> bool:
		var sc: Node = SceneManager.current_scene
		if sc == null or not (sc is Node2D) or not sc.is_inside_tree() \
			or not sc.is_node_ready() or SceneManager._pending_scene != null:
			return false
		return not sc.turn_button.disabled, 60.0)
	if not got:
		print("[CLOSE-TEST] FAIL 战局启动超时")
		get_tree().quit(1)
		return
	var snap: Dictionary = SaveManager.get_last_snapshot()
	print("[CLOSE-TEST] 快照就绪：关卡 %d · 回合 %d" % \
		[int(snap.meta.stage), int(snap.meta.round)])
	print("[CLOSE-TEST] 传播 WM_CLOSE_REQUEST（等价用户点击窗口 X）...")
	get_tree().root.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	## 此后 SaveManager 应落盘并退出进程（探针不再执行任何代码）


func _wait_until(predicate: Callable, timeout_s := 60.0, poll_s := 0.06) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_s * 1000)
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await get_tree().create_timer(poll_s).timeout
	return false
