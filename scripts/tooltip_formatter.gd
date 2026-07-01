class_name TooltipFormatter
extends RefCounted

## BBCode富文本Tooltip格式化工具类
## 集中管理数值着色、家族颜色、标签高亮、图标嵌入等BBCode转换

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
	"coin": "每回合+2金币，且获得金币量20%的分数",
	"resonance": "共鸣系≥4时激活，正向贡献时永久+1%叠层，下次攻击额外获得once×叠层倍率的得分",
	"desperation": "获得1次全局免死，每有1个debuff绝境系得分额外+8%",
	"vitality": "过关时hp+1；若满血则max_hp+1",
	"hunt": "猎杀系得分额外+15%",
	"swift": "移动力+1，疾风系得分额外+5%",
	"evolution": "所有基础分额外+1",
}

## 门槛类型中文名映射
const GATE_TYPE_NAMES := {
	"duizi": "对子",
	"shunzi": "顺子",
	"tongse": "同色",
	"tongdui": "同对",
	"tongshun": "同顺",
}

## 格式化buff tooltip
static func format_buff(buff_meta: Dictionary, extra_text: String = "") -> String:
	var icon: String = str(buff_meta.get("buff_icon", ""))
	var name: String = str(buff_meta.get("buff_name", ""))
	var tooltip: String = str(buff_meta.get("buff_tooltip", ""))
	var family: String = str(buff_meta.get("family", ""))
	var tags = buff_meta.get("tags", [])

	var bbcode: String = ""

	# 标题行：图标 + 名称
	if not icon.is_empty():
		bbcode += "[img=24]%s[/img] " % icon
	bbcode += "[b][font_size=18]%s[/font_size][/b]" % name

	# 家族行
	if not family.is_empty():
		if FAMILY_COLORS.has(family):
			var family_color: String = FAMILY_COLORS[family]
			var family_cn: String = FAMILY_NAMES.get(family, family)
			bbcode += "\n[color=%s]%s系[/color]" % [family_color, family_cn]

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
				bbcode += "\n💡 [color=#0fff5b]%s系Buff≥4时激活[%s]：%s（当前：4/4）已激活[/color]" % [FAMILY_NAMES.get(family, family), overlord_name, overlord_effect]
			else:
				bbcode += "\n💡 [color=#AAAAAA]%s系Buff≥4时激活[%s]：%s（当前：%d/4）[/color]" % [FAMILY_NAMES.get(family, family), overlord_name, overlord_effect, family_count]

	# 领主BUFF自身显示已激活状态
	if tags.has("legendary") and tags.has("multiplicative"):
		bbcode += "\n[color=#0fff5b][b]（已激活 ✓）[/b][/color]"

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
	var name: String = str(debuff_meta.get("debuff_name", ""))
	var tooltip: String = str(debuff_meta.get("debuff_tooltip", ""))

	var bbcode: String = ""

	# 标题行：图标 + 减益标识 + 名称
	if not icon.is_empty():
		bbcode += "[img=24]%s[/img] " % icon
	bbcode += "[color=%s]▼ 减益[/color] " % DECREASE_COLOR
	bbcode += "[b][font_size=18]%s[/font_size][/b]" % name

	# 描述文本行（数值倾向debuff=红色）
	bbcode += "\n" + _colorize_numbers(tooltip, "debuff")

	return bbcode

## 格式化coin_skill tooltip
static func format_coin_skill(skill_meta: Dictionary) -> String:
	var icon: String = str(skill_meta.get("coin_skill_icon", ""))
	var name: String = str(skill_meta.get("coin_skill_name", ""))
	var tooltip: String = str(skill_meta.get("coin_skill_tooltip", ""))

	var bbcode: String = ""

	# 标题行：图标 + 名称
	if not icon.is_empty():
		bbcode += "[img=24]%s[/img] " % icon
	bbcode += "[b][font_size=18]%s[/font_size][/b]" % name

	# 描述文本行
	bbcode += "\n" + _colorize_numbers(tooltip, "buff")

	return bbcode

## 格式化精英/BOSS史莱姆tooltip
static func format_elite_slime(is_boss: bool, gate_type: String, gate_count: int, dice_point: int) -> String:
	var bbcode: String = ""

	# 标题行
	if is_boss:
		bbcode += "[color=%s]★ BOSS史莱姆[/color]" % BOSS_COLOR
	else:
		bbcode += "[color=%s]★ 精英史莱姆[/color]" % ELITE_COLOR

	# 门槛行
	var gate_cn: String = GATE_TYPE_NAMES.get(gate_type, gate_type)
	bbcode += "\n[color=#FFD700]需要: %s ×%d[/color]" % [gate_cn, gate_count]

	# 骰子行
	bbcode += "\n骰子: [b]%d点[/b]" % dice_point

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

	# 3. 匹配增加关键词后的数值
	var increase_words := ["增加", "加分", "提升", "强化", "额外增加", "额外"]
	var increase_pattern := "(" + "|".join(increase_words) + ")([0-9]+\\.?[0-9]*%?)"
	var regex_inc_word := RegEx.create_from_string(increase_pattern)
	result = regex_inc_word.sub(result, "$1[b][color=%s]$2[/color][/b]" % INCREASE_COLOR, true)

	# 4. 匹配减少关键词后的数值
	var decrease_words := ["减少", "下降", "损失", "禁用", "扣", "脆弱"]
	var decrease_pattern := "(" + "|".join(decrease_words) + ")([0-9]+\\.?[0-9]*%?)"
	var regex_dec_word := RegEx.create_from_string(decrease_pattern)
	result = regex_dec_word.sub(result, "$1[b][color=%s]$2[/color][/b]" % DECREASE_COLOR, true)

	# 5. 变为0 → 红色
	var regex_zero := RegEx.create_from_string("变为([0-9]+)")
	result = regex_zero.sub(result, "变为[b][color=%s]$1[/color][/b]" % DECREASE_COLOR, true)

	return result
