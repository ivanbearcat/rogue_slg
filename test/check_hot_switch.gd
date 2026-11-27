extends SceneTree

## 5.3 热切换自动抽测：主菜单场景内切换语言，"继续游戏"按钮（含进度行）立即随语言刷新。
## （场景静态按钮由 Godot auto_translate 自动刷新；本断言钉住代码赋值的 label 通知分支。）
## 战局内槽位名/横幅/悬停 tooltip 的真机抽测见 test/hot_switch_manual.md。

func _initialize() -> void:
	await _run()

func _run() -> void:
	await process_frame
	await process_frame
	var gs := root.get_node_or_null("/root/GameSettings")
	if gs == null:
		print("FATAL: 无 GameSettings")
		quit(1)
		return
	## 回到中文基线
	gs.set("language_id", 0)
	gs.apply_settings()
	## 实例化主菜单场景（splash.tscn 的脚本即 splash_menu.gd）
	var splash: Node = (load("res://scenes/splash.tscn") as PackedScene).instantiate()
	root.add_child(splash)
	await process_frame
	var cont: TextureButton = splash.get_node("ButtonColumn/continue_button")
	var label: Label = cont.get_node("Label")
	var before: String = label.text
	if not before.contains("继续游戏"):
		print("RESULT: FAIL (基线 label 不是中文：", before, ")")
		quit(1)
		return
	## 热切换到英语（id 1=en，注册表见 game_settings.gd）：set_locale 触发全树 NOTIFICATION_TRANSLATION_CHANGED
	gs.set("language_id", 1)
	gs.apply_settings()
	await process_frame
	var after: String = label.text
	## 无存档时 label 恰为 tr("继续游戏")="Continue"；有存档时带进度行（Continue\n…）。
	## 精确前缀断言可排除 fr "Continuer la partie" 等同前缀干扰。
	if not (after == "Continue" or after.begins_with("Continue\n")):
		print("RESULT: FAIL (切换到 en 后未随语言刷新：", after, ")")
		quit(1)
		return
	## 再切回中文，确认往返可逆
	gs.set("language_id", 0)
	gs.apply_settings()
	await process_frame
	if not label.text.contains("继续游戏"):
		print("RESULT: FAIL (切回 zh_CN 未还原：", label.text, ")")
		quit(1)
		return
	print("主菜单热切换 ✓ zh→en→zh：label 均随语言刷新")
	print("RESULT: PASS")
	quit(0)
