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
	[ "[color=#FFD700]击杀条件：[/color]由 %s 个或以上的史莱姆组成 %s 骰型[color=#FFB74D]（%s，需包含自身）[/color]", {
		"en": "[color=#FFD700]Kill condition:[/color] formed from %s or more Slimes composing a %s Type[color=#FFB74D] (%s, must include self)[/color]",
		"ja": "[color=#FFD700]撃破条件：[/color]%s 体以上のスライムで %s 種類を構成[color=#FFB74D]（%s、自身を含む）[/color]",
		"ko": "[color=#FFD700]처치 조건:[/color]슬라임 %s마리 이상으로 %s 종류를 구성[color=#FFB74D](%s, 자신 포함)[/color]",
		"zh_TW": "[color=#FFD700]擊殺條件：[/color]由 %s 個或以上的史萊姆組成 %s 骰型[color=#FFB74D]（%s，需包含自身）[/color]",
		"fr": "[color=#FFD700]Condition d'élimination :[/color] constituée de %s slimes ou plus formant un Type %s[color=#FFB74D] (%s, doit s'inclure)[/color]",
		"de": "[color=#FFD700]Kill-Bedingung:[/color] aus %s oder mehr Slimes aufgebaut, die einen %s-Typ bilden[color=#FFB74D] (%s, muss sich selbst enthalten)[/color]",
		"es": "[color=#FFD700]Condición de derribo:[/color] formada por %s o más Slimes que compongan un Tipo %s[color=#FFB74D] (%s, debe incluirse a sí mismo)[/color]",
		"pt_BR": "[color=#FFD700]Condição de abate:[/color] formada por %s ou mais Slimes compondo um Tipo %s[color=#FFB74D] (%s, deve incluir a si mesmo)[/color]",
		"it": "[color=#FFD700]Condizione di uccisione:[/color] formata da %s o più Slime che compongono un Tipo %s[color=#FFB74D] (%s, deve includere se stesso)[/color]" }],
	[ "同色且点数连续", {
		"en": "Same color and consecutive points", "ja": "同色かつ連続点数", "ko": "같은 색이며 연속된 점수",
		"zh_TW": "同色且點數連續", "fr": "Même couleur et points consécutifs",
		"de": "Gleiche Farbe und aufeinanderfolgende Punkte", "es": "Mismo color y puntos consecutivos",
		"pt_BR": "Mesma cor e pontos consecutivos", "it": "Stesso colore e punti consecutivi" }],
	[ "需要能量", { "en": "Needs Energy", "ja": "エネルギー要", "ko": "에너지 필요", "zh_TW": "需要能量",
		"fr": "Énergie requise", "de": "Energie nötig", "es": "Necesita Energía",
		"pt_BR": "Precisa de Energia", "it": "Serve Energia" }],
	## —— i18n-gap-fill-hotswitch 新登记样本：帮助页标签/整段 tooltip/英雄技能/槽位名/进度行 ——
	[ "骰型倍率", { "en": "Type Multipliers", "ja": "種類倍率", "ko": "종류 배수", "zh_TW": "骰型倍率",
		"fr": "Multiplicateurs de Type", "de": "Typ-Multiplikatoren", "es": "Multiplicadores de Tipo",
		"pt_BR": "Multiplicadores de Tipo", "it": "Moltiplicatori di Tipo" }],
	[ "横斩", { "en": "Horizontal Slash", "ja": "横斬り", "ko": "가로 베기", "zh_TW": "橫斬",
		"fr": "Taillade horizontale", "de": "Horizontalschlag", "es": "Tajo horizontal",
		"pt_BR": "Corte horizontal", "it": "Taglio orizzontale" }],
	[ "面前横向3格击杀范围内史莱姆，使用能量时为面前2排3列共6格", {
		"en": "Kills Slimes within 3 tiles horizontally in front; when Energy is used, covers 2 rows × 3 columns (6 tiles in total) in front.",
		"ja": "正面横3マス以内のスライムを撃破。エネルギー使用時は正面2行3列の計6マス",
		"ko": "정면 가로 3칸 범위의 슬라임을 처치합니다. 에너지 사용 시 정면 2행 3열 총 6칸",
		"zh_TW": "面前橫向3格擊殺範圍內史萊姆，使用能量時為面前2排3列共6格",
		"fr": "Tue les slimes dans les 3 cases horizontales devant ; en utilisant l'Énergie, 2 rangées × 3 colonnes (6 cases au total) devant.",
		"de": "Tötet Slimes im horizontalen 3-Felder-Bereich nach vorn; mit Energie 2 Reihen × 3 Spalten (insgesamt 6 Felder) nach vorn.",
		"es": "Elimina a los slimes en 3 casillas horizontales al frente; al usar Energía, 2 filas × 3 columnas (6 casillas en total) al frente.",
		"pt_BR": "Mata os slimes em 3 casas horizontais à frente; ao usar Energia, 2 fileiras × 3 colunas (6 casas no total) à frente.",
		"it": "Uccide gli slime entro 3 caselle orizzontali davanti; usando l'Energia, 2 righe × 3 colonne (6 caselle in totale) davanti." }],
	[ "重掷骰子", { "en": "Reroll Dice", "ja": "サイコロリロール", "ko": "주사위 다시 던지기", "zh_TW": "重擲骰子",
		"fr": "Relancer les dés", "de": "Würfel neu würfeln", "es": "Relanzar dado",
		"pt_BR": "Relançar dado", "it": "Rilanciare il dado" }],
	[ "继续游戏", { "en": "Continue", "ja": "ゲーム続行", "ko": "이어서 하기", "zh_TW": "繼續遊戲",
		"fr": "Continuer la partie", "de": "Fortsetzen", "es": "Continuar partida",
		"pt_BR": "Continuar partida", "it": "Continua partita" }],
	[ "关卡", { "en": "Stage", "ja": "ステージ", "ko": "스테이지", "zh_TW": "關卡",
		"fr": "Étage", "de": "Stufe", "es": "Ronda", "pt_BR": "Fase", "it": "Livello" }],
	[ "回合", { "en": "Turn", "ja": "ターン", "ko": "턴", "zh_TW": "回合",
		"fr": "Tour", "de": "Runde", "es": "Turno", "pt_BR": "Turno", "it": "Turno" }],
	[ "[color=#FFD700][font_size=20]骰型倍率[/font_size][/color]\n[hr color=#777777 height=1 width=100%]\n攻击范围内的史莱姆骰子与口袋骰子共同组成骰型。\n[color=#42A5F5]至少 2 个骰子：2 个为 Lv.1，每多 1 个升 1 级，6 个及以上为 Lv.5。[/color]\n系统选择整次攻击总分最高的组合；一套组合可包含多个骰型，分数相加。\n[color=#FFB74D]同一分组同时满足多种骰型时，只取该组最高分的一种，不重复叠加。[/color]\n单个骰型得分 = 参与骰子的基础分值之和 × 该骰型倍率。\n[color=#AAAAAA]未组成骰型的骰子不得分。[/color]", {
		"en": "[color=#FFD700][font_size=20]Type Multipliers[/font_size][/color]\n[hr color=#777777 height=1 width=100%]\nSlime dice within your attack range and pocket dice together form Types.\n[color=#42A5F5]At least 2 dice: 2 make Lv.1, each extra die raises the level by 1, 6 or more = Lv.5.[/color]\nThe system picks the combo with the highest total attack score; one combo may contain multiple Types, and scores add up.\n[color=#FFB74D]When a group meets several Types at once, only the highest-scoring Type of that group counts, without stacking.[/color]\nSingle Type score = sum of the base values of the participating dice × that Type's multiplier.\n[color=#AAAAAA]Dice that form no Type score nothing.[/color]",
		"ja": "[color=#FFD700][font_size=20]種類倍率[/font_size][/color]\n[hr color=#777777 height=1 width=100%]\n攻撃範囲内のスライムサイコロとポケットのサイコロが合わさって種類を構成します。\n[color=#42A5F5]最低 2 個：2 個で Lv.1、1 個増えるごとに 1 レベル上昇、6 個以上で Lv.5。[/color]\nシステムは攻撃合計スコアが最も高い組み合わせを選択します。1 つの組み合わせに複数の種類を含められ、スコアは加算されます。\n[color=#FFB74D]同じグループが複数の種類を同時に満たす場合、そのグループでは最も高い得点の 1 種類のみを採用し、重複加算しません。[/color]\n種類 1 つのスコア = 参加サイコロの基礎配点の合計 × その種類の倍率。\n[color=#AAAAAA]種類を構成しなかったサイコロは得点しません。[/color]",
		"ko": "[color=#FFD700][font_size=20]종류 배수[/font_size][/color]\n[hr color=#777777 height=1 width=100%]\n공격 범위 안의 슬라임 주사위와 주머니 주사위가 함께 종류를 이룹니다.\n[color=#42A5F5]최소 2개: 2개면 Lv.1, 1개 추가마다 1레벨 상승, 6개 이상은 Lv.5.[/color]\n시스템은 공격 총점이 가장 높은 조합을 선택하며, 하나의 조합에 여러 종류가 포함될 수 있고 점수는 합산됩니다.\n[color=#FFB74D]한 그룹이 여러 종류를 동시에 만족할 때는 해당 그룹에서 가장 높은 점수의 한 가지만 적용하며 중복 누적되지 않습니다.[/color]\n종류 1개의 점수 = 참여 주사위의 기본 점수 합 × 해당 종류의 배수.\n[color=#AAAAAA]종류를 이루지 못한 주사위는 점수를 얻지 못합니다.[/color]",
		"zh_TW": "[color=#FFD700][font_size=20]骰型倍率[/font_size][/color]\n[hr color=#777777 height=1 width=100%]\n攻擊範圍內的史萊姆骰子與口袋骰子共同組成骰型。\n[color=#42A5F5]至少 2 個骰子：2 個為 Lv.1，每多 1 個升 1 級，6 個及以上為 Lv.5。[/color]\n系統選擇整次攻擊總分最高的組合；一套組合可包含多個骰型，分數相加。\n[color=#FFB74D]同一分組同時滿足多種骰型時，只取該組最高分的一種，不重複疊加。[/color]\n單個骰型得分 = 參與骰子的基礎分值之和 × 該骰型倍率。\n[color=#AAAAAA]未組成骰型的骰子不得分。[/color]",
		"fr": "[color=#FFD700][font_size=20]Multiplicateurs de Type[/font_size][/color]\n[hr color=#777777 height=1 width=100%]\nLes dés slime dans la portée d'attaque et les dés de la poche forment ensemble des Types.\n[color=#42A5F5]Au moins 2 dés : 2 dés = Lv.1, chaque dé supplémentaire monte d'un niveau, 6 ou plus = Lv.5.[/color]\nLe système choisit la combinaison au score d'attaque total le plus élevé ; une combinaison peut contenir plusieurs Types, et les scores s'additionnent.\n[color=#FFB74D]Quand un groupe satisfait plusieurs Types à la fois, seul le Type au score le plus élevé du groupe compte, sans cumul.[/color]\nScore d'un Type = somme des valeurs de base des dés participants × multiplicateur de ce Type.\n[color=#AAAAAA]Les dés ne formant aucun Type ne marquent rien.[/color]",
		"de": "[color=#FFD700][font_size=20]Typ-Multiplikatoren[/font_size][/color]\n[hr color=#777777 height=1 width=100%]\nSlime-Würfel in der Angriffsreichweite und Taschen-Würfel bilden zusammen Typen.\n[color=#42A5F5]Mindestens 2 Würfel: 2 = Lv.1, jeder weitere +1 Level, 6 oder mehr = Lv.5.[/color]\nDas System wählt die Kombination mit der höchsten Gesamtangriffspunktzahl; eine Kombination kann mehrere Typen enthalten, die Punkte addieren sich.\n[color=#FFB74D]Erfüllt eine Gruppe mehrere Typen gleichzeitig, zählt nur der punktehöchste Typ dieser Gruppe, ohne Stapelung.[/color]\nPunktzahl eines Typs = Summe der Grundwerte der beteiligten Würfel × Multiplikator dieses Typs.\n[color=#AAAAAA]Würfel, die keinen Typ bilden, bringen keine Punkte.[/color]",
		"es": "[color=#FFD700][font_size=20]Multiplicadores de Tipo[/font_size][/color]\n[hr color=#777777 height=1 width=100%]\nLos dados slime dentro del rango de ataque y los dados de la bolsa forman juntos los Tipos.\n[color=#42A5F5]Al menos 2 dados: 2 = Lv.1, cada dado extra sube 1 nivel, 6 o más = Lv.5.[/color]\nEl sistema elige la combinación con la puntuación total de ataque más alta; una combinación puede contener varios Tipos, y las puntuaciones se suman.\n[color=#FFB74D]Cuando un grupo satisface varios Tipos a la vez, solo cuenta el Tipo de mayor puntuación de ese grupo, sin acumular.[/color]\nPuntuación de un Tipo = suma de los valores base de los dados participantes × multiplicador de ese Tipo.\n[color=#AAAAAA]Los dados que no forman Tipo no puntúan.[/color]",
		"pt_BR": "[color=#FFD700][font_size=20]Multiplicadores de Tipo[/font_size][/color]\n[hr color=#777777 height=1 width=100%]\nOs dados slime dentro do alcance de ataque e os dados da bolsa formam juntos os Tipos.\n[color=#42A5F5]No mínimo 2 dados: 2 = Lv.1, cada dado extra sobe 1 nível, 6 ou mais = Lv.5.[/color]\nO sistema escolhe a combinação com a maior pontuação total de ataque; uma combinação pode conter vários Tipos, e as pontuações se somam.\n[color=#FFB74D]Quando um grupo satisfaz vários Tipos ao mesmo tempo, conta apenas o Tipo de maior pontuação desse grupo, sem acumular.[/color]\nPontuação de um Tipo = soma dos valores base dos dados participantes × multiplicador desse Tipo.\n[color=#AAAAAA]Dados que não formam Tipo não pontuam.[/color]",
		"it": "[color=#FFD700][font_size=20]Moltiplicatori di Tipo[/font_size][/color]\n[hr color=#777777 height=1 width=100%]\nI dadi slime nel raggio d'attacco e i dadi della tasca formano insieme i Tipi.\n[color=#42A5F5]Almeno 2 dadi: 2 = Lv.1, ogni dado extra sale di 1 livello, 6 o più = Lv.5.[/color]\nIl sistema sceglie la combinazione col punteggio totale d'attacco più alto; una combinazione può contenere più Tipi, e i punteggi si sommano.\n[color=#FFB74D]Quando un gruppo soddisfa più Tipi contemporaneamente, conta solo il Tipo col punteggio più alto del gruppo, senza accumuli.[/color]\nPunteggio di un Tipo = somma dei valori base dei dadi partecipanti × moltiplicatore di quel Tipo.\n[color=#AAAAAA]I dadi che non formano Tipi non fanno punteggio.[/color]" }],
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
			print("✓ ", loc, "（字体=", tag, "，样本 ", SAMPLES.size(), "/", SAMPLES.size(), " 一致）")

	print("RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
