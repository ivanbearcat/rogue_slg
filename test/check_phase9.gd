extends SceneTree

## 阶段9自检：10 语言运行时验证矩阵
##  1. GameSettings 注册表逐语言 apply_settings：locale 与主字体切换正确
##  2. 代表样本（场景/代码/数据/模板四类）×10 语：TranslationServer 输出与 CSV 期望值精确一致
## 样本期望值由 tools/_gen_samples.py 从 locale/translations.csv 生成后固化于此（.translation 派生自该 CSV）

const SAMPLES := [
	[ "史莱姆潮", { "en": "Slime Tide", "ja": "スライムタイド", "ko": "슬라임 물결", "zh_TW": "史萊姆潮",
		"fr": "Vague de slimes", "de": "Slime-Flut", "es": "Marea de Slimes", "pt_BR": "Maré de Slimes", "it": "Marea di Slime" }],
	[ "危险⚠️", { "en": "Danger⚠️", "ja": "危険⚠️", "ko": "위험⚠️", "zh_TW": "危險⚠️",
		"fr": "Danger ⚠️", "de": "Gefahr⚠️", "es": "¡Peligro⚠️", "pt_BR": "Perigo⚠️", "it": "Pericolo⚠️" }],
	[ "同色烙印", { "en": "Same-color Brand", "ja": "同色の烙印", "ko": "동색 브랜드", "zh_TW": "同色烙印",
		"fr": "Marque de couleur", "de": "Gleichfarbiges Brandmal", "es": "Marca del Mismo Color",
		"pt_BR": "Marca da Mesma Cor", "it": "Marchio Stesso Colore" }],
	[ "对子", { "en": "Pair", "ja": "ペア", "ko": "페어", "zh_TW": "對子",
		"fr": "Paire", "de": "Paar", "es": "Par", "pt_BR": "Par", "it": "Coppia" }],
	[ "通关达成", { "en": "Stage Cleared", "ja": "クリア達成", "ko": "클리어 달성", "zh_TW": "通關達成",
		"fr": "Victoire", "de": "Stufe geschafft", "es": "Ronda Superada", "pt_BR": "Concluído", "it": "Livello Completato" }],
	[ "战败", { "en": "Defeat", "ja": "敗北", "ko": "패배", "zh_TW": "戰敗",
		"fr": "Défaite", "de": "Niederlage", "es": "Derrota", "pt_BR": "Derrota", "it": "Sconfitta" }],
	[ "换一批[img=14 ]res://images/ui_icon/coin.png[/img]%d", { "en": "New batch[img=14 ]res://images/ui_icon/coin.png[/img]%d",
		"ja": "リフレッシュ[img=14 ]res://images/ui_icon/coin.png[/img]%d",
		"ko": "새로고침[img=14 ]res://images/ui_icon/coin.png[/img]%d",
		"zh_TW": "換一批[img=14 ]res://images/ui_icon/coin.png[/img]%d",
		"fr": "Changer de lot [img=14 ]res://images/ui_icon/coin.png[/img]%d",
		"de": "Neue Ware[img=14 ]res://images/ui_icon/coin.png[/img]%d",
		"es": "Labor nuevo[img=14 ]res://images/ui_icon/coin.png[/img]%d",
		"pt_BR": "Nova leva[img=14 ]res://images/ui_icon/coin.png[/img]%d",
		"it": "Nuova merce[img=14 ]res://images/ui_icon/coin.png[/img]%d" }],
	[ "[color=%s]★ BOSS史莱姆[/color]", { "en": "[color=%s]★ BOSS Slime[/color]", "ja": "[color=%s]★ BOSSスライム[/color]",
		"ko": "[color=%s]★ BOSS 슬라임[/color]", "zh_TW": "[color=%s]★ BOSS史萊姆[/color]",
		"fr": "[color=%s]★ slime BOSS[/color]", "de": "[color=%s]★ BOSS-Slime[/color]",
		"es": "[color=%s]★ Slime JEFE[/color]", "pt_BR": "[color=%s]★ Slime CHEFE[/color]",
		"it": "[color=%s]★ Slime BOSS[/color]" }],
	[ "💡 [color=#42A5F5]共鸣霸主·当前共振：%d层（+%d%%）[/color]", { "en": "💡 [color=#42A5F5]Resonance Overlord · current resonance: %d stacks (+%d%%)[/color]",
		"ja": "💡 [color=#42A5F5]共鳴の覇者・現在の共振：%dスタック（+%d%%）[/color]",
		"ko": "💡 [color=#42A5F5]공명의 패자 · 현재 공진: %d스택 (+%d%%)[/color]",
		"zh_TW": "💡 [color=#42A5F5]共鳴霸主·當前共振：%d層（+%d%%）[/color]",
		"fr": "💡 [color=#42A5F5]Overlord Résonance·charge actuelle : %d (%d%%)[/color]",
		"de": "💡 [color=#42A5F5]Resonanz-Overlord · aktuelle Resonanz: %d Stapel (+%d%%)[/color]",
		"es": "💡 [color=#42A5F5]Señor de la Resonancia · resonancia actual: %d cargas (+%d%%)[/color]",
		"pt_BR": "💡 [color=#42A5F5]Soberano da Ressonância · ressonância atual: %d cargas (+%d%%)[/color]",
		"it": "💡 [color=#42A5F5]Sovrano della Risonanza · risonanza attuale: %d cariche (+%d%%)[/color]" }],
	[ "过关时hp+1；若满血则max_hp+1", { "en": "On stage clear hp+1; if at full HP, max_hp+1 instead",
		"ja": "クリア時 hp+1；体力が満タンならmax_hp+1",
		"ko": "스테이지 클리어 시 hp+1; 체력이 가득 찬 상태라면 max_hp+1",
		"zh_TW": "過關時hp+1；若滿血則max_hp+1",
		"fr": "En fin d'Étage, hp+1 ; si la vie est pleine, max_hp+1",
		"de": "Bei Stufenende hp+1; bei vollem Leben stattdessen max_hp+1",
		"es": "Al superar la ronda hp+1; con vida llena, max_hp+1",
		"pt_BR": "Ao concluir a fase hp+1; com vida cheia, max_hp+1",
		"it": "Al completamento del livello hp+1; a vita piena, max_hp+1" }],
	[ "骰子: [b]%d点[/b]", { "en": "Dice: [b]%d points[/b]", "ja": "サイコロ: [b]%d点[/b]", "ko": "주사위: [b]%d점[/b]",
		"zh_TW": "骰子: [b]%d點[/b]", "fr": "Dé : [b]%d points[/b]", "de": "Würfel: [b]%d Punkte[/b]",
		"es": "Dado: [b]%d puntos[/b]", "pt_BR": "Dado: [b]%d pontos[/b]", "it": "Dado: [b]%d punti[/b]" }],
	[ "需要能量", { "en": "Needs Energy", "ja": "エネルギー要", "ko": "에너지 필요", "zh_TW": "需要能量",
		"fr": "Énergie requise", "de": "Energie nötig", "es": "Necesita Energía",
		"pt_BR": "Precisa de Energia", "it": "Serve Energia" }],
]

const EXPECTED_FONT := {
	"zh_CN": "zh_hans", "zh_TW": "zh_hant", "ja": "-ja", "ko": "-ko",
	"en": "latin", "fr": "latin", "de": "latin", "es": "latin", "pt_BR": "latin", "it": "latin",
}

func _initialize() -> void:
	await _run()

func _run() -> void:
	# autoload 在 _initialize 之后一帧才注入 root，等两帧再取
	await process_frame
	await process_frame
	var gs := root.get_node_or_null("/root/GameSettings")
	if gs == null:
		print("FATAL: 无 GameSettings")
		quit(1)
		return

	var ok := true
	for i in gs.LANGUAGES.size():
		var lang: Dictionary = gs.LANGUAGES[i]
		var loc: String = str(lang["locale"])
		gs.set("language_id", i)
		gs.apply_settings()
		# 1) locale 生效
		var actual := TranslationServer.get_locale()
		if actual != loc:
			ok = false
			print("✗ language_id=", i, " 期望 ", loc, " 实际 ", actual)
		# 2) 主字体切换
		var font_res: Resource = root.theme.default_font if root.theme else null
		var font_path: String = font_res.resource_path if font_res else ""
		var tag: String = EXPECTED_FONT.get(loc, "")
		if not font_path.contains(tag):
			ok = false
			print("✗ ", loc, " 主字体错误：", font_path, "（期望含 ", tag, "）")
		# 3) 样本矩阵
		var bad := 0
		for s in SAMPLES:
			var key: String = s[0]
			var expect: String = str(s[1].get(loc, key))
			var got := TranslationServer.translate(key)
			if got != expect:
				bad += 1
				if bad <= 3:
					print("   - [", loc, "] key=", key.substr(0, 24), "… 期望=", expect.substr(0, 24), "… 实际=", got.substr(0, 24), "…")
		if bad > 0:
			ok = false
			print("✗ ", loc, " 样本不一致 ", bad, "/", SAMPLES.size())
		else:
			print("✓ ", loc, "（字体=", tag, "，样本 ", SAMPLES.size(), "/12 一致）")

	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
