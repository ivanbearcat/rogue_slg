extends Node

## 场景流回归测试：splash → hero_select → main 全链路（命令行无头运行）
## 用法: godot --headless --path . res://test/scripts/scene/scene_flow_test.tscn

func _ready() -> void:
	_run_flow_test()

func _run_flow_test() -> void:
	print("[FLOW-TEST] === 场景流测试开始 ===")
	## 第 1 步：模拟 splash「开始」按钮 → 切到英雄选择
	SceneManager.change_scene(&"hero_select")
	await get_tree().create_timer(1.0).timeout
	var hs := SceneManager.current_scene
	if hs == null or hs.name != &"HeroSelect":
		print("[FLOW-TEST] ❌ 第1步失败：期望 HeroSelect，实际 ", hs.name if hs else "null")
		get_tree().quit(1)
		return
	print("[FLOW-TEST] ✅ 第1步：进入英雄选择画面 (", hs.name, ")")
	## 第 2 步：模拟「选择出征」→ 预加载切换进战局
	hs._on_confirm_pressed()
	await get_tree().create_timer(12.0).timeout
	var battle := SceneManager.current_scene
	if battle == null or battle.name != &"game_manager":
		print("[FLOW-TEST] ❌ 第2步失败：期望 game_manager，实际 ", battle.name if battle else "null")
		get_tree().quit(1)
		return
	print("[FLOW-TEST] ✅ 第2步：进入战局场景 (", battle.name, ")")
	## 第 3 步：验证自注册与英雄数据
	if Current.game_manager == null:
		print("[FLOW-TEST] ❌ 第3步失败：Current.game_manager 未注册")
		get_tree().quit(1)
		return
	if Current.game_manager != battle:
		print("[FLOW-TEST] ❌ 第3步失败：注册引用与当前场景不一致")
		get_tree().quit(1)
		return
	print("[FLOW-TEST] ✅ 第3步：Current.game_manager 自注册生效")
	var heros: Array = Current.game_manager.get_node("heros").get_children()
	if heros.size() == 0:
		print("[FLOW-TEST] ❌ 第3步失败：战局无英雄")
		get_tree().quit(1)
		return
	print("[FLOW-TEST] ✅ 英雄按 selected_hero 生成: ", heros[0].hero_name,
		" (Current.selected_hero=", Current.selected_hero, ")")
	## 第 4 步：验证 getter 引用链（Tools/EffectManager 等跟随注册）
	if Tools.game_manager != battle:
		print("[FLOW-TEST] ❌ 第4步失败：Tools.game_manager 未跟随注册")
		get_tree().quit(1)
		return
	print("[FLOW-TEST] ✅ 第4步：Tools.game_manager 跟随注册")
	print("[FLOW-TEST] === 场景流测试全部通过 ===")
	get_tree().quit(0)
