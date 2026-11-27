extends SceneTree

## 临时自检：i18n 热切换改动后 headless load() 编译验证

func _initialize() -> void:
	var script: Script = load("res://scripts/autoload/tooltip_manager.gd")
	if script == null:
		print("RESULT: FAIL (tooltip_manager load null)")
		quit(1)
		return
	## 逐个关键方法确认存在（load 通过即已编译成功，此处再防拼写漂移）
	for method in ["set_tooltip", "set_dynamic_tooltip", "unset_tooltip", "set_skill_tooltip"]:
		if not script.get_script_method_list().any(func(m): return m["name"] == method):
			print("RESULT: FAIL (missing method ", method, ")")
			quit(1)
			return
	## 迁移过的脚本逐个 load（autoload 已注册，可解析 TooltipManager/TooltipFormatter 引用）
	for path in [
		"res://scripts/game_manager.gd",
		"res://scripts/autoload/current.gd",
		"res://scripts/ui/drop_selection_ui.gd",
		"res://scripts/ui/splash_menu.gd",
	]:
		var s: Script = load(path)
		if s == null:
			print("RESULT: FAIL (", path, ")")
			quit(1)
			return
	print("RESULT: PASS")
	quit(0)

