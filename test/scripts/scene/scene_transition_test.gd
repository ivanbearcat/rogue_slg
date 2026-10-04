extends Node

## 转场冒烟测试：SceneTransition.transition_to 全链路（命令行无头运行）
## 用法: godot --headless --path . res://test/scripts/scene/scene_transition_test.tscn
## 注意：本节点作为启动场景会被 change_scene 释放，
## _ready 时先复制一个驱动节点常驻 root，由驱动节点执行实际流程。

func _ready() -> void:
	if get_tree().current_scene == self:
		var driver := Node.new()
		driver.set_script(get_script())
		driver.name = "TransitionSmokeDriver"
		get_tree().root.add_child.call_deferred(driver)
		return
	_run_test()

func _run_test() -> void:
	print("[SMOKE] === transition test start ===")
	## 第 1 步：进入英雄选择画面
	SceneManager.change_scene(&"hero_select")
	await get_tree().create_timer(1.0).timeout
	var hs := SceneManager.current_scene
	if hs == null or hs.name != &"HeroSelect":
		print("[SMOKE] FAIL step1: expect HeroSelect, got ", hs.name if hs else "null")
		get_tree().quit(1)
		return
	print("[SMOKE] OK step1 hero_select")
	## 第 2 步：走新转场进入战局（铺帘 → 骰子加载 → 等 stage_start → 拉帘）
	Current.selected_hero = "soldier"
	var battle := await SceneTransition.transition_to(&"main", &"stage_start")
	if battle == null or battle.name != &"game_manager":
		print("[SMOKE] FAIL step2: expect game_manager, got ", battle.name if battle else "null")
		get_tree().quit(1)
		return
	print("[SMOKE] OK step2 main (transition done)")
	## 第 3 步：转场层已收起、注册引用一致
	if SceneTransition.visible:
		print("[SMOKE] FAIL step3: transition layer still visible")
		get_tree().quit(1)
		return
	if Current.game_manager != battle:
		print("[SMOKE] FAIL step3: game_manager not registered")
		get_tree().quit(1)
		return
	print("[SMOKE] OK step3 layer hidden + registered")
	print("[SMOKE] === ALL PASS ===")
	get_tree().quit(0)
