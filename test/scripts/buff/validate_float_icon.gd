extends SceneTree
## 校验 buff-float-icon 变更：脚本解析、float_number 场景结构、icon_texture 行为
## 用法: godot --headless --script res://test/scripts/buff/validate_float_icon.gd

var _scripts_to_check: Array = [
	"res://scripts/ui/float_number.gd",
	"res://scripts/autoload/effect_manager.gd",
	"res://scripts/autoload/buff_system.gd",
	"res://scripts/game_manager.gd",
	"res://scripts/skill_system.gd",
]

func _init():
	await_frame()

func await_frame():
	await process_frame
	run_validation()
	quit()

func run_validation():
	print("\n==================================================")
	print("  buff-float-icon Validation")
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

	## 场景结构与 icon_texture setter 行为
	var packed = load("res://scenes/float_number.tscn")
	if packed == null:
		print("  FAIL: res://scenes/float_number.tscn (load returned null)")
		failed += 1
	else:
		var icon_node_checks := _check_scene_structure(packed)
		passed += icon_node_checks[0]
		failed += icon_node_checks[1]
		var icon_setter_checks := _check_icon_setter(packed)
		passed += icon_setter_checks[0]
		failed += icon_setter_checks[1]

	print("--------------------------------------------------")
	print("  Passed: %d | Failed: %d" % [passed, failed])
	print("==================================================\n")

func _check_scene_structure(packed) -> Array:
	var passed := 0
	var failed := 0
	var inst = packed.instantiate()
	var icon = inst.get_node_or_null("Icon")
	if icon == null:
		print("  FAIL: float_number.tscn 缺少 Icon 节点")
		return [passed, failed + 1]
	if icon.visible:
		print("  FAIL: Icon 默认应为隐藏")
		failed += 1
	else:
		print("  PASS: Icon 默认隐藏")
		passed += 1
	if icon.z_index != 195:
		print("  FAIL: Icon z_index 应为195，实际 %d" % icon.z_index)
		failed += 1
	else:
		print("  PASS: Icon z_index = 195（与 Label 一致）")
		passed += 1
	if not is_equal_approx(icon.size.y, 36.0):
		print("  FAIL: Icon 本地高度应为36，实际 %s" % icon.size.y)
		failed += 1
	else:
		print("  PASS: Icon 本地高 36px")
		passed += 1
	inst.free()
	return [passed, failed]

func _check_icon_setter(packed) -> Array:
	var passed := 0
	var failed := 0
	var inst = packed.instantiate()
	var icon: TextureRect = inst.get_node("Icon")
	var label: Label = inst.get_node("Label")
	## 无图标：保持原布局
	inst.icon_texture = null
	if icon.visible or icon.texture != null or not is_zero_approx(label.position.x):
		print("  FAIL: 无图标时应隐藏 Icon 且 Label 偏移为0")
		failed += 1
	else:
		print("  PASS: 无图标 → Icon 隐藏，Label 偏移 0（原布局）")
		passed += 1
	## 有图标：显示 Icon、Label 右移
	var tex = load("res://images/buff_icon/coin_storm.png")
	if tex == null:
		print("  FAIL: 图标资源加载失败 res://images/buff_icon/coin_storm.png")
		inst.free()
		return [passed, failed + 1]
	inst.icon_texture = tex
	if icon.visible and icon.texture == tex and label.position.x > 0.0:
		print("  PASS: 有图标 → Icon 显示，Label 右移 %.1f" % label.position.x)
		passed += 1
	else:
		print("  FAIL: 有图标时 Icon.visible=%s texture=%s Label.x=%s" % [icon.visible, icon.texture, label.position.x])
		failed += 1
	## 撤回图标：恢复原布局
	inst.icon_texture = null
	if not icon.visible and icon.texture == null and is_zero_approx(label.position.x):
		print("  PASS: 图标置空 → 恢复纯数字布局")
		passed += 1
	else:
		print("  FAIL: 图标置空后 visible=%s texture=%s Label.x=%s" % [icon.visible, icon.texture, label.position.x])
		failed += 1
	inst.free()
	return [passed, failed]
