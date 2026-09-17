extends Node

## 探针：直接进入 main 场景，检查结算画面是否在游戏开始时被误弹（命令行无头运行）
## 用法: godot --headless --path . res://test/scripts/end_settlement/startup_probe.tscn

func _ready() -> void:
	_run_probe()

func _run_probe() -> void:
	print("[PROBE] === 开始 ===")
	## 换替身 current_scene 前先进入主场景
	EventBus.subscribe("run_end", _probe_on_run_end)
	SceneManager.change_scene(&"main")
	await get_tree().create_timer(6.0).timeout
	var gm := SceneManager.current_scene
	print("[PROBE] current_scene=", gm.name if gm else "null")
	var settle: Node = null
	if gm != null:
		var end_ui := gm.get_node_or_null("end_ui")
		if end_ui != null:
			for c in end_ui.get_children():
				if String(c.name) == "end_settlement_ui":
					settle = c
	print("[PROBE] enum found=", settle != null, " settle.visible=", settle.visible if settle else "-", " layer.visible=", settle.get_parent().visible if settle else "-", " paused=", get_tree().paused)
	get_tree().quit(0)

func _probe_on_run_end(result) -> void:
	print("[PROBE] run_end 被触发: ", str(result))
