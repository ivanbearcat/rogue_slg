extends SceneTree

## 2.4 自检：重导入后 10 语言抽查新 key 命中（含一条帮助页整段 blob 与"横斩"）。
## 命中判据：translate(key) 与 CSV 期望值精确一致；zh_CN 等于 key 本身（同文列）。

## —— 单行新 key 抽查（10 语期望值取自 locale/translations.csv）——
const SAMPLES := {
	"横斩": {
		"zh_CN": "横斩", "zh_TW": "橫斬", "en": "Horizontal Slash", "ja": "横斬り", "ko": "가로 베기",
		"fr": "Taillade horizontale", "de": "Horizontalschlag", "es": "Tajo horizontal",
		"pt_BR": "Corte horizontal", "it": "Taglio orizzontale",
	},
	"加载中": {
		"zh_CN": "加载中", "zh_TW": "載入中", "en": "Loading", "ja": "読み込み中", "ko": "불러오는 중",
		"fr": "Chargement", "de": "Laden", "es": "Cargando", "pt_BR": "Carregando", "it": "Caricamento",
	},
	"关卡": {
		"zh_CN": "关卡", "zh_TW": "關卡", "en": "Stage", "ja": "ステージ", "ko": "스테이지",
		"fr": "Étage", "de": "Stufe", "es": "Ronda", "pt_BR": "Fase", "it": "Livello",
	},
	"右键取消": {
		"zh_CN": "右键取消", "zh_TW": "右鍵取消", "en": "Right-click to cancel", "ja": "右クリックで取消",
		"ko": "우클릭으로 취소", "fr": "Clic droit pour annuler", "de": "Rechtsklick zum Abbrechen",
		"es": "Clic derecho para cancelar", "pt_BR": "Clique direito para cancelar", "it": "Tasto destro per annullare",
	},
	"金币霸主": {
		"zh_CN": "金币霸主", "zh_TW": "金幣霸主", "en": "Coin Overlord", "ja": "金貨の覇者", "ko": "주화의 패자",
		"fr": "Overlord Monnayage", "de": "Münz-Overlord", "es": "Señor de la Acuñación",
		"pt_BR": "Soberano da Cunhagem", "it": "Sovrano della Coniazione",
	},
	"骰型等级奖励": {
		"zh_CN": "骰型等级奖励", "zh_TW": "骰型等級獎勵", "en": "Type Level Bonus", "ja": "種類レベルボーナス",
		"ko": "종류 레벨 보상", "fr": "Bonus de niveau de Type", "de": "Typstufen-Bonus",
		"es": "Bonus de nivel de Tipo", "pt_BR": "Bônus de nível de Tipo", "it": "Bonus di livello di Tipo",
	},
}

## —— 帮助页整段 blob（dice_type）：en 精确期望 + 非 zh 语区"命中≠回退中文"判据 ——
const BLOB_KEY := "[color=#FFD700][font_size=20]骰型倍率[/font_size][/color]\n[hr color=#777777 height=1 width=100%]\n攻击范围内的史莱姆骰子与口袋骰子共同组成骰型。\n[color=#42A5F5]至少 2 个骰子：2 个为 Lv.1，每多 1 个升 1 级，6 个及以上为 Lv.5。[/color]\n系统选择整次攻击总分最高的组合；一套组合可包含多个骰型，分数相加。\n[color=#FFB74D]同一分组同时满足多种骰型时，只取该组最高分的一种，不重复叠加。[/color]\n单个骰型得分 = 参与骰子的基础分值之和 × 该骰型倍率。\n[color=#AAAAAA]未组成骰型的骰子不得分。[/color]"
const BLOB_EN := "[color=#FFD700][font_size=20]Type Multipliers[/font_size][/color]\n[hr color=#777777 height=1 width=100%]\nSlime dice within your attack range and pocket dice together form Types.\n[color=#42A5F5]At least 2 dice: 2 make Lv.1, each extra die raises the level by 1, 6 or more = Lv.5.[/color]\nThe system picks the combo with the highest total attack score; one combo may contain multiple Types, and scores add up.\n[color=#FFB74D]When a group meets several Types at once, only the highest-scoring Type of that group counts, without stacking.[/color]\nSingle Type score = sum of the base values of the participating dice × that Type's multiplier.\n[color=#AAAAAA]Dice that form no Type score nothing.[/color]"

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
	var ok := true
	for lang in gs.LANGUAGES:
		var loc: String = str(lang["locale"])
		TranslationServer.set_locale(loc)
		var ok_loc := true
		for key in SAMPLES:
			var expect: String = SAMPLES[key].get(loc, key)
			var got := TranslationServer.translate(key)
			if got != expect:
				ok_loc = false
				print("✗ [", loc, "] ", key, " 期望=", expect, " 实际=", got)
		## 整段 blob：zh_CN 同文；en 精确一致；其余非 zh 语命中即 ≠ key
		var got_blob := TranslationServer.translate(BLOB_KEY)
		if loc == "zh_CN":
			if got_blob != BLOB_KEY:
				ok_loc = false
				print("✗ [zh_CN] blob 应同文回显，实际不同")
		elif loc == "en":
			if got_blob != BLOB_EN:
				ok_loc = false
				print("✗ [en] blob 与期望不一致：", got_blob.left(40), "…")
		elif got_blob == BLOB_KEY:
			ok_loc = false
			print("✗ [", loc, "] blob 未命中（回退中文）")
		if not ok_loc:
			ok = false
		print("✓ " if ok_loc else "✗ ", loc)
	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
