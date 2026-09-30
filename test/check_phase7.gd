extends SceneTree

func _initialize() -> void:
	print("locale=", TranslationServer.get_locale())
	var gs := root.get_node_or_null("/root/GameSettings")
	print("GameSettings: ", gs != null, " default_font=", root.theme.default_font.get_file() if root.theme and root.theme.default_font else "None")
	for loc in ["en", "ja", "ko", "zh_TW", "fr", "de", "es", "pt_BR", "it"]:
		TranslationServer.set_locale(loc)
		print(loc, " → ", TranslationServer.translate("史莱姆潮"), " | ", TranslationServer.translate("危险⚠️"))
	if gs:
		for loc in ["ja", "de", "zh_CN"]:
			gs.set("language_id", {"ja":2, "de":6, "zh_CN":0}[loc])
			gs.apply_settings()
			var f: FontFile = root.theme.default_font
			var el: LabelSettings = load("res://fonts/pixel_cn_label_settings.tres")
			print(loc, " → 主字体=", f.get_file(), " fallbacks=", f.fallbacks.size(), " LabelSettings=", el.font.get_file() if el.font else "")
	quit(0)
