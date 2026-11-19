extends "res://test/scripts/save/save_flow_test.gd"

## phase2 薄包装场景：MCP/编辑器通道无法传 `-- --phase=2` 命令行参数时，
## 以独立场景在新进程内直接驱动 _run_phase2（进程隔离语义与命令行两阶段一致：
## phase1 先行落盘 user://save.bin，本场景运行时即"重启进程后读档"）。
## 命令行路径保持不变：save_flow_test.tscn -- --phase=2 仍是标准用法。
##
## 用法: godot --headless --path . res://test/scripts/save/save_flow_test_phase2.tscn
## （或编辑器/MCP project_run custom scene）

func _ready() -> void:
	## 探针保活：与父类 _ready 同款（场景作为启动 current_scene 时摘除注册）
	if get_tree().current_scene == self:
		get_tree().current_scene = null
	await _run_phase2()
	print("\n=== SaveFlow(phase=2 wrapper) 测试：通过 %d / 失败 %d ===" % [_passed, _failed])
	for fail_name in _fail_names:
		print("  [FAIL-项] ", fail_name)
	await get_tree().process_frame
	get_tree().quit(1 if _failed > 0 else 0)
