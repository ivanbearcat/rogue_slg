extends SceneTree
## 校验所有修改过的脚本能否被Godot解析（语法错误检查）
## 用法: godot --headless --script res://test/scripts/buff/validate_scripts.gd

var _scripts_to_check: Array = [
	"res://scripts/game_manager.gd",
	"res://scripts/autoload/buff_system.gd",
	"res://scripts/buff/swarm_overlord_buff.gd",
	"res://scripts/buff/resonance_overlord_buff.gd",
	"res://scripts/buff/desperation_overlord_buff.gd",
	"res://scripts/buff/hunt_overlord_buff.gd",
	"res://scripts/buff/swift_overlord_buff.gd",
	"res://scripts/buff/evolution_overlord_buff.gd",
	"res://scripts/buff/vitality_overlord_buff.gd",
	"res://scripts/buff/swarm_call_buff.gd",
	"res://test/scripts/buff/test_buff_system.gd",
	"res://test/scripts/buff/test_swarm_buffs.gd",
]

func _init():
	await_frame()

func await_frame():
	await process_frame
	run_validation()
	quit()

func run_validation():
	print("\n==================================================")
	print("  Script Syntax Validation")
	print("==================================================")
	var passed := 0
	var failed := 0
	for script_path in _scripts_to_check:
		var script = load(script_path)
		if script == null:
			print("  FAIL: %s (load returned null — syntax error)" % script_path)
			failed += 1
		else:
			print("  PASS: %s" % script_path)
			passed += 1
	print("--------------------------------------------------")
	print("  Passed: %d | Failed: %d" % [passed, failed])
	print("==================================================\n")
