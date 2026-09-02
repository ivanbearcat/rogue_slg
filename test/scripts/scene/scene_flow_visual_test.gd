extends Node

## 场景流可视回归测试：splash → hero_select → main 全链路 + 视口截图
## 用法: godot --path . res://test/scripts/scene/scene_flow_visual_test.tscn
## 产出: test/scripts/scene/out/ 下三张截图

const OUT_DIR := "res://test/scripts/scene/out"

func _ready() -> void:
	DirAccess.open("res://").make_dir_recursive("test/scripts/scene/out")
	_run_visual_flow_test()

func _snapshot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/" + file_name)
	print("[VISUAL-TEST] 截图已保存: ", file_name)

func _run_visual_flow_test() -> void:
	print("[VISUAL-TEST] === 可视场景流测试开始 ===")
	## 第 1 步：进入启动画面并等待布局稳定
	SceneManager.change_scene(&"splash")
	await get_tree().create_timer(2.0).timeout
	var splash := SceneManager.current_scene
	if splash == null or splash.name != &"SplashMenu":
		print("[VISUAL-TEST] ❌ 失败：期望 SplashMenu，实际 ", splash.name if splash else "null")
		get_tree().quit(1)
		return
	await _snapshot("01_splash.png")
	## 第 2 步：模拟「开始」按钮 → 英雄选择
	splash._on_start_pressed()
	await get_tree().create_timer(2.0).timeout
	var select := SceneManager.current_scene
	if select == null or select.name != &"HeroSelect":
		print("[VISUAL-TEST] ❌ 失败：期望 HeroSelect，实际 ", select.name if select else "null")
		get_tree().quit(1)
		return
	await _snapshot("02_hero_select.png")
	## 第 3 步：模拟「选择出征」→ 预加载进战局
	## 双击回归：第二次点击应被切换锁忽略（用户报障场景）
	select._on_confirm_pressed()
	select._on_confirm_pressed()
	await get_tree().create_timer(10.0).timeout
	var battle := SceneManager.current_scene
	if battle == null or battle.name != &"game_manager":
		print("[VISUAL-TEST] ❌ 失败：期望 game_manager，实际 ", battle.name if battle else "null")
		get_tree().quit(1)
		return
	await _snapshot("03_battle.png")
	## 幂等断言：root 下只应存在一个 game_manager 实例
	var gm_count := 0
	for child in get_tree().root.get_children():
		if child.name == &"game_manager":
			gm_count += 1
	if gm_count != 1:
		print("[VISUAL-TEST] ❌ 失败：root 下存在 ", gm_count, " 个 game_manager 实例（重复切换未防住）")
		get_tree().quit(1)
		return
	print("[VISUAL-TEST] ✅ 双击幂等：root 下仅 1 个战局实例")
	## 汇总校验
	if Current.game_manager != battle:
		print("[VISUAL-TEST] ❌ 失败：Current.game_manager 未对准当前战局")
		get_tree().quit(1)
		return
	var heros: Array = battle.get_node("heros").get_children()
	print("[VISUAL-TEST] ✅ 全链路可视验证通过：",
		"scene=", battle.name,
		" game_manager=已注册",
		" hero=", heros[0].hero_name if heros.size() > 0 else "无",
		" selected=", Current.selected_hero)
	print("[VISUAL-TEST] === 测试完成，退出 ===")
	get_tree().quit(0)
