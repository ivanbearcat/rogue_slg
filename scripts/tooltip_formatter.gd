class_name TooltipFormatter
extends RefCounted

## BBCode富文本Tooltip格式化工具类
## 集中管理数值着色、家族颜色、标签高亮、图标嵌入等BBCode转换

## static 上下文的翻译入口（源文本即KEY：查不到时原样返回）
static func T(s: String) -> String:
	return TranslationServer.translate(s)

## 家族颜色映射
const FAMILY_COLORS := {
	"swarm": "#8BC34A",
	"coin": "#FFD700",
	"resonance": "#42A5F5",
	"desperation": "#AB47BC",
	"vitality": "#66BB6A",
	"hunt": "#E57373",
	"swift": "#4FC3F7",
	"evolution": "#FFB74D",
}

## 家族中文名映射
const FAMILY_NAMES := {
	"swarm": "潮涌",
	"coin": "铸币",
	"resonance": "共鸣",
	"desperation": "绝境",
	"vitality": "生机",
	"hunt": "猎杀",
	"swift": "疾风",
	"evolution": "进化",
}

## 颜色常量
const TAG_COLOR := "#AAAAAA"
const INCREASE_COLOR := "#0fff5b"
const DECREASE_COLOR := "#cc0808"
const ELITE_COLOR := "#cc0808"
const BOSS_COLOR := "#AB47BC"

## 领主中文名映射
const OVERLORD_NAMES := {
	"swarm": "潮涌霸主",
	"coin": "金元帝国",
	"resonance": "共鸣霸主",
	"desperation": "绝境霸主",
	"vitality": "生机霸主",
	"hunt": "猎杀霸主",
	"swift": "疾风霸主",
	"evolution": "进化霸主",
}

## 领主效果描述映射
const OVERLORD_EFFECTS := {
	"swarm": "每有1个史莱姆存活，以这次得分为基础，额外增加3%倍率的分数",
	"coin": "铸币系≥4时激活，每有5个金币，击杀获得1%的得分加成",
	"resonance": "共鸣系≥4时激活，正向贡献时永久+1%叠层，下次攻击额外获得once×叠层倍率的得分",
	"desperation": "绝境系Buff≥4时激活，获得1次全局免死",
	"vitality": "过关时hp+1；若满血则max_hp+1",
	"hunt": "猎杀系≥4时激活，猎杀系累积得分额外+50%",
	"swift": "疾风系≥4时激活，能量上限+1，攻击时本回合每移动过1格+5%得分",
	"evolution": "进化系≥4时激活，每回合随机1个点数基础分+1，随机1个骰型倍率+1%",
}

## 门槛类型中文名映射
const GATE_TYPE_NAMES := {
	"duizi": "对子",
	"shunzi": "顺子",
	"tongse": "同色",
	"tongdui": "同对",
	"tongshun": "同顺",
}

## 击杀条件统一句式骨架（design D1）：五门槛共用同一句式，只有骰型词/定义两个变量
## %s 顺序：徽章(数量N) → 徽章(骰型词) → 骰型定义（琥珀色括号澄清行）
const GATE_KILL_SKELETON := "[color=#FFD700]击杀条件：[/color]由 %s 个或以上的史莱姆组成 %s 骰型[color=#FFB74D]（%s，需包含自身）[/color]"

## 五门槛 {骰型词, 定义} 映射（design D1）
## 对子→点数相同 / 顺子→点数连续 / 同色→颜色相同 / 同对→颜色点数都相同 / 同顺→同色且点数连续
const GATE_DICE_TYPE_INFO := {
	"duizi": {"word": "对子", "definition": "点数相同"},
	"shunzi": {"word": "顺子", "definition": "点数连续"},
	"tongse": {"word": "同色", "definition": "颜色相同"},
	"tongdui": {"word": "同对", "definition": "颜色点数都相同"},
	"tongshun": {"word": "同顺", "definition": "同色且点数连续"},
}

## 自身骰子行（design D3）：%s = 24×24 骰面图标 / 降级文字（颜色名+点数）
const DICE_ROW_ICON := "自身骰子 [img=24]%s[/img]"
const DICE_ROW_TEXT := "自身骰子：%s %d 点"

## 骰面颜色英文（SLIME_COLOR_DICT 值域）→ 颜色中文名KEY映射（文字降级用）
const DICE_COLOR_NAMES := {
	"green": "绿",
	"red": "红",
	"yellow": "黄",
	"blue": "蓝",
}

## 徽章观感常量（design D2）：暗金底 + 金字，与正文同字号、不加粗——
## 颜色与底色反差已足够显眼（owner 手测定稿，覆盖初版"粗体+放大一档"方案）
const BADGE_BGCOLOR := "#4a3800"
const BADGE_COLOR := "#FFD700"

## 格式化buff tooltip
static func format_buff(buff_meta: Dictionary, extra_text: String = "") -> String:
	var icon: String = str(buff_meta.get("buff_icon", ""))
	var name: String = T(str(buff_meta.get("buff_name", "")))
	var tooltip: String = T(str(buff_meta.get("buff_tooltip", "")))
	var family: String = str(buff_meta.get("family", ""))
	var tags = buff_meta.get("tags", [])

	var bbcode: String = ""

	# 标题行：图标 + 名称（help-ui 同款：不加粗、金色大字号）
	if not icon.is_empty():
		bbcode += "[img=24]%s[/img] " % icon
	bbcode += "[color=#FFD700][font_size=20]%s[/font_size][/color]" % name

	# 分割线：标题下方（help-ui 同款样式）
	bbcode += "\n[hr color=#777777 height=1 width=100%]"

	# 家族行
	if not family.is_empty():
		if FAMILY_COLORS.has(family):
			var family_color: String = FAMILY_COLORS[family]
			var family_cn: String = T(str(FAMILY_NAMES.get(family, family)))
			bbcode += "\n" + T("[color=%s]%s系[/color]") % [family_color, family_cn]

	# 描述文本行（数值自动着色，倾向buff=绿色）
	var colorized_tooltip: String = _colorize_numbers(tooltip, "buff")
	if not extra_text.is_empty():
		colorized_tooltip += extra_text
	bbcode += "\n" + colorized_tooltip

		# 领主进度提示：有family的非领主BUFF显示激活进度
	if not family.is_empty() and not tags.has("legendary"):
		if FAMILY_COLORS.has(family):
			var family_count = BuffSystem.get_family_count(family)
			var overlord_name: String = OVERLORD_NAMES.get(family, "")
			var overlord_effect: String = OVERLORD_EFFECTS.get(family, "")
			if family_count >= 4:
				bbcode += "\n" + T("💡 [color=#0fff5b]%s系Buff≥4时激活[%s]：%s（当前：4/4）已激活[/color]") % [T(str(FAMILY_NAMES.get(family, family))), T(str(overlord_name)), T(str(overlord_effect))]
			else:
				bbcode += "\n" + T("💡 [color=#AAAAAA]%s系Buff≥4时激活[%s]：%s（当前：%d/4）[/color]") % [T(str(FAMILY_NAMES.get(family, family))), T(str(overlord_name)), T(str(overlord_effect)), family_count]

	# 共鸣霸主共振叠层：共鸣系且霸主已激活时显示当前共振（ramp=0也显示）
	if family == "resonance" and BuffSystem.get_family_count("resonance") >= 4:
		var ramp_n := int(BuffSystem.resonance_ramp / 0.01)
		var ramp_m := int(BuffSystem.resonance_ramp * 100)
		bbcode += "\n" + T("💡 [color=#42A5F5]共鸣霸主·当前共振：%d层（+%d%%）[/color]") % [ramp_n, ramp_m]

	# 领主BUFF自身显示已激活状态
	if tags.has("legendary") and tags.has("multiplicative"):
		bbcode += "\n" + T("[color=#0fff5b][b]（已激活 ✓）[/b][/color]")

	# 标签行
	if tags.size() > 0:
		bbcode += "\n[color=%s]" % TAG_COLOR
		for tag in tags:
			bbcode += "[b]%s[/b] " % str(tag)
		bbcode += "[/color]"

	return bbcode

## 格式化debuff tooltip
static func format_debuff(debuff_meta: Dictionary) -> String:
	var icon: String = str(debuff_meta.get("debuff_icon", ""))
	var name: String = T(str(debuff_meta.get("debuff_name", "")))
	var tooltip: String = T(str(debuff_meta.get("debuff_tooltip", "")))

	var bbcode: String = ""

	# 标题行：图标 + 减益标识 + 名称（help-ui 同款：不加粗、金色大字号）
	if not icon.is_empty():
		bbcode += "[img=24]%s[/img] " % icon
	bbcode += T("[color=%s]▼ 减益[/color]") % DECREASE_COLOR + " "
	bbcode += "[color=#FFD700][font_size=20]%s[/font_size][/color]" % name

	# 分割线：标题下方（help-ui 同款样式）
	bbcode += "\n[hr color=#777777 height=1 width=100%]"

	# 描述文本行（数值倾向debuff=红色）
	bbcode += "\n" + _colorize_numbers(tooltip, "debuff")

	return bbcode

## 格式化coin_skill tooltip
static func format_coin_skill(skill_meta: Dictionary) -> String:
	var icon: String = str(skill_meta.get("coin_skill_icon", ""))
	var name: String = T(str(skill_meta.get("coin_skill_name", "")))
	var tooltip: String = T(str(skill_meta.get("coin_skill_tooltip", "")))

	var bbcode: String = ""

	# 标题行：图标 + 名称（help-ui 同款：不加粗、金色大字号）
	if not icon.is_empty():
		bbcode += "[img=24]%s[/img] " % icon
	bbcode += "[color=#FFD700][font_size=20]%s[/font_size][/color]" % name

	# 分割线：标题下方（help-ui 同款样式）
	bbcode += "\n[hr color=#777777 height=1 width=100%]"

	# 描述文本行
	bbcode += "\n" + _colorize_numbers(tooltip, "buff")

	return bbcode

## 格式化英雄技能tooltip（沿用coin_skill范式：标题行+数值着色描述行）
## 动画区由TooltipManager装配，本函数只负责文本
static func format_skill(skill_meta: Dictionary) -> String:
	var name: String = T(str(skill_meta.get("skill_name", "")))
	var tooltip: String = T(str(skill_meta.get("skill_tooltip", "")))

	var bbcode: String = ""

	# 标题行：技能名称（help-ui 同款：不加粗、金色大字号）
	bbcode += "[color=#FFD700][font_size=20]%s[/font_size][/color]" % name

	# 分割线：标题下方（help-ui 同款样式）
	bbcode += "\n[hr color=#777777 height=1 width=100%]"

	# 描述文本行（数值自动着色）
	bbcode += "\n" + _colorize_numbers(tooltip, "buff")

	return bbcode

## 徽章辅助（design D2）：暗金底 + 金字，与正文同字号、不加粗，
## 文字两侧留一个空格防止背景色块贴字边缘（"由 ␣2␣ 个"）
static func _badge(text: String) -> String:
	return "[bgcolor=%s][color=%s] %s [/color][/bgcolor]" % [BADGE_BGCOLOR, BADGE_COLOR, text]

## 自身骰子行（design D3）：优先 24×24 骰面图标锚定颜色+点数（dice_{color}_{point}.tres）；
## 资源缺失/颜色非法时降级为文字（颜色名+点数），不阻断 tooltip 渲染
static func _dice_row(dice_color: String, dice_point: int) -> String:
	var icon_path := "res://images/ui_icon/dice_%s_%d.tres" % [dice_color, dice_point]
	if ResourceLoader.exists(icon_path):
		return T(DICE_ROW_ICON) % [icon_path]
	var color_cn: String = T(str(DICE_COLOR_NAMES.get(dice_color, dice_color)))
	return T(DICE_ROW_TEXT) % [color_cn, dice_point]

## 格式化精英/BOSS史莱姆tooltip
static func format_elite_slime(is_boss: bool, gate_type: String, gate_count: int, dice_point: int, dice_color: String) -> String:
	var bbcode: String = ""

	# 标题行（help-ui 同款：大字号不加粗，BOSS/精英保留语义色）
	if is_boss:
		bbcode += "[font_size=20]" + T("[color=%s]★ BOSS史莱姆[/color]") % BOSS_COLOR + "[/font_size]"
	else:
		bbcode += "[font_size=20]" + T("[color=%s]★ 精英史莱姆[/color]") % ELITE_COLOR + "[/font_size]"

	# 分割线：标题下方（help-ui 同款样式）
	bbcode += "\n[hr color=#777777 height=1 width=100%]"

	# 击杀条件行：统一句式（design D1）——金色"击杀条件："标签 + 数量/骰型词暗金底徽章
	# + 琥珀色括号定义行；判定以该史莱姆自身骰子为锚点且自身计入攻击骰子，故注明"需包含自身"
	var info: Dictionary = GATE_DICE_TYPE_INFO.get(gate_type, {})
	if info.is_empty():
		# 未知门槛类型兜底：类型名 + 数量（保留既有分支）
		var gate_cn_fallback: String = T(str(GATE_TYPE_NAMES.get(gate_type, gate_type)))
		bbcode += "\n" + T("[color=#FFD700]需要: %s ×%d[/color]") % [gate_cn_fallback, gate_count]
	else:
		var badge_count: String = _badge(str(gate_count))
		var badge_word: String = _badge(T(str(info["word"])))
		var definition: String = T(str(info["definition"]))
		bbcode += "\n" + T(GATE_KILL_SKELETON) % [badge_count, badge_word, definition]

	# 自身骰子行：骰面图标补齐颜色锚点（design D3），资源加载失败降级为文字
	bbcode += "\n" + _dice_row(dice_color, dice_point)

	return bbcode

## 数值自动着色函数
## default_tendency: "buff" 默认绿色, "debuff" 默认红色
static func _colorize_numbers(text: String, default_tendency: String = "buff") -> String:
	var result: String = text

	# 1. 匹配明确符号：+N/+N% → 绿色
	var regex_plus := RegEx.create_from_string("(\\+[0-9]+\\.?[0-9]*%?)")
	result = regex_plus.sub(result, "[b][color=%s]$1[/color][/b]" % INCREASE_COLOR, true)

	# 2. 匹配明确符号：-N/-N% → 红色
	var regex_minus := RegEx.create_from_string("(\\-[0-9]+\\.?[0-9]*%?)")
	result = regex_minus.sub(result, "[b][color=%s]$1[/color][/b]" % DECREASE_COLOR, true)

	# 3. 匹配增加关键词后的数值（对源语言文本做逻辑匹配,非待翻译文案）
	var increase_words := ["增加", "加分", "提升", "强化", "额外增加", "额外"] # NO_TRANSLATE
	var increase_pattern := "(" + "|".join(increase_words) + ")([0-9]+\\.?[0-9]*%?)"
	var regex_inc_word := RegEx.create_from_string(increase_pattern)
	result = regex_inc_word.sub(result, "$1[b][color=%s]$2[/color][/b]" % INCREASE_COLOR, true)

	# 4. 匹配减少关键词后的数值（对源语言文本做逻辑匹配,非待翻译文案）
	var decrease_words := ["减少", "下降", "损失", "禁用", "扣", "脆弱"] # NO_TRANSLATE
	var decrease_pattern := "(" + "|".join(decrease_words) + ")([0-9]+\\.?[0-9]*%?)"
	var regex_dec_word := RegEx.create_from_string(decrease_pattern)
	result = regex_dec_word.sub(result, "$1[b][color=%s]$2[/color][/b]" % DECREASE_COLOR, true)

	# 5. 变为0 → 红色（匹配模式针对源语言,非待翻译文案）
	var regex_zero := RegEx.create_from_string("变为([0-9]+)") # NO_TRANSLATE
	result = regex_zero.sub(result, T("变为[b][color=%s]$1[/color][/b]") % DECREASE_COLOR, true)

	return result
