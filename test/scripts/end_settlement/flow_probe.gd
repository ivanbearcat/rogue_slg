extends Node

## 复现探针：splash → hero_select → main 全流程，监控 run_end/失败/settlement 状态
## 用法: godot --headless --path . res://test/scripts/end_settlement/flow_probe.tscn

func _ready() -> void:
	_run()

func _probe_run_end(result) -> void:
	print("[FLOW-PROBE] run_end 被触发: ", str(result), " | player_hp=", Current.player_hp, " paused=", get_tree().paused)

func _run() -> void:
	print("[FLOW-PROBE] === 测试开始 ===")
	EventBus.subscribe("run_end", _probe_run_end)
	SceneManager.change_scene(&"hero_select")
	await get_tree().create_timer(2.0).timeout
	var hs := SceneManager.current_scene
	print("[FLOW-PROBE] 选人画面: ", hs.name if hs else "null", " | player_hp=", Current.player_hp)
	hs._on_confirm_pressed()
	for i in 6:
		await get_tree().create_timer(5.0).timeout
		var sc := SceneManager.current_scene
		var settle: Node = null
		if sc != null:
			var end_ui := sc.get_node_or_null("end_ui")
			if end_ui != null:
				for c in end_ui.get_children():
					if String(c.name) == "end_settlement_ui":
						settle = c
		print("[FLOW-PROBE] t+", (i + 1) * 5, "s scene=", sc.name if sc else "null",
			" hp=", Current.player_hp, " paused=", get_tree().paused,
			" settle=", (settle.visible if settle else "no-node"))
	get_tree().quit(0)
