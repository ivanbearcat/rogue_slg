extends SceneTree
## 回归验证脚本（一次性）：splash 启动场景经 SceneManager 切两次场景后必须被释放
## 用法：godot --headless -s test/scripts/scene/splash_leak_regression.gd --path .
## 断言：进入 main 后，/root 下不存在 SplashMenu / HeroSelect；且 current_scene == main 根

var _failed := false

func _check(cond: bool, what: String) -> void:
	if not cond:
		printerr("[regression] FAIL: " + what)
		_failed = true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# 复现完整启动流：splash 作为启动主场景（由 current_scene 指向）
	var splash: Node = load("res://scenes/splash.tscn").instantiate()
	root.add_child(splash)
	current_scene = splash
	# 等待 _ready 连接信号
	await process_frame
	# 1) splash._on_start_pressed → change_scene(hero_select)
	splash._on_start_pressed()
	await process_frame
	await process_frame
	_check(root.get_node_or_null("SplashMenu") == null, "SplashMenu 未被释放（泄漏仍存在）")
	_check(root.get_node_or_null("HeroSelect") != null, "HeroSelect 未挂载")
	print("[regression] 1) splash->hero_select 完成, SplashMenu已释放=", root.get_node_or_null("SplashMenu") == null)
	# 2) hero_select 确认 → 预加载后 change_scene_preloaded(main)
	var hero_select: Node = root.get_node("HeroSelect")
	root.get_node("/root/Current").selected_hero = "soldier"
	print("[regression] step2: change_scene(main) 开始")
	root.get_node("/root/SceneManager").change_scene(&"main")
	print("[regression] step2: change_scene 返回")
	# 等待 deferred 挂载
	for i in 60:
		await process_frame
		if root.get_node_or_null("main") != null:
			break
	print("[regression] step2: 挂载等待结束")
	var main: Node = root.get_node_or_null("main")
	_check(main != null, "main 未挂载")
	if main == null:
		quit(1)
		return
	await process_frame
	_check(root.get_node_or_null("SplashMenu") == null, "SplashMenu 泄漏")
	_check(root.get_node_or_null("HeroSelect") == null, "HeroSelect 泄漏")
	_check(current_scene == main, "current_scene 未写回 main")
	var current_autoload: Node = root.get_node_or_null("/root/Current")
	_check(current_autoload != null and current_autoload.hero != null, "英雄未创建")
	print("[regression] 2) hero_select->main 完成, root场上节点=")
	var names := []
	for c in root.get_children():
		names.append(str(c.name))
	print("[regression] ", names)
	print("[regression] EXIT_CODE=0 PASS" if not _failed else "[regression] EXIT_CODE=1 FAIL")
	quit(1 if _failed else 0)
