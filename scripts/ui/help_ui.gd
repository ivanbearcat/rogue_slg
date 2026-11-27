extends Control

## 帮助界面 tooltip 绑定
## 全部帮助文案集中在本脚本的 HELP_TOOLTIPS 字典中，key 与 help_ui/Panel 下的标注节点同名。
## 复用 TooltipManager 的 BBCode 浮窗：只负责注册文案、目标映射和生命周期回收。

## 默认目标路径：Panel/<key>
const TARGET_PATH_PATTERN := "Panel/%s"

## 需要绑定多个目标节点的 key（关闭帮助：文字标注 + 实际关闭按钮）
const TARGET_OVERRIDES := {
	"close_help": ["Panel/close_help", "Panel/help_button_close"],
}

## 帮助文案基准：完整 BBCode，key 用于节点映射，值作为 tr() 的源文本
const HELP_TOOLTIPS := {
	"dice_type": (
		"[color=#FFD700][font_size=20]骰型倍率[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "攻击范围内的史莱姆骰子与口袋骰子共同组成骰型。\n"
		+ "[color=#42A5F5]至少 2 个骰子：2 个为 Lv.1，每多 1 个升 1 级，6 个及以上为 Lv.5。[/color]\n"
		+ "系统选择整次攻击总分最高的组合；一套组合可包含多个骰型，分数相加。\n"
		+ "[color=#FFB74D]同一分组同时满足多种骰型时，只取该组最高分的一种，不重复叠加。[/color]\n"
		+ "单个骰型得分 = 参与骰子的基础分值之和 × 该骰型倍率。\n"
		+ "[color=#AAAAAA]未组成骰型的骰子不得分。[/color]"
	),
	"dice_type_desc": (
		"[color=#FFD700][font_size=20]骰型组合[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "[color=#FFD700]对子[/color]：点数相同的骰子至少 2 个，颜色不限。例：红3+蓝3。\n"
		+ "[color=#FFD700]顺子[/color]：点数连续的骰子至少 2 个，颜色不限，[color=#42A5F5]重复点数只按 1 个参与连续点计数[/color]。例：红2+蓝2+黄3+绿4（两个 2 只算 1 个，连续点为 2/3/4）。\n"
		+ "[color=#FFD700]同色[/color]：颜色相同的骰子至少 2 个，点数不限。例：红2+红5。\n"
		+ "[color=#FFD700]同对[/color]：同色且同点数的骰子至少 2 个。例：红3+红3。\n"
		+ "[color=#FFD700]同顺[/color]：同色且点数连续的骰子至少 2 个，[color=#42A5F5]重复点数只按 1 个参与连续点计数[/color]。例：红2+红2+红3（两个 2 只算 1 个，连续点为 2/3）。\n"
		+ "[color=#42A5F5]骰型等级：与骰型倍率说明相同，2 个为 Lv.1，每多 1 个升 1 级，6 个及以上为 Lv.5；顺子/同顺按去重后的连续点数量计算。[/color]\n"
		+ "[color=#FFB74D]同一分组同时满足多种骰型时（如红3+红3 既是同对又是对子），只取该组最高分的一种，不重复叠加。[/color]"
	),
	"dice_score": (
		"[color=#FFD700][font_size=20]点数分值[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "1～6 点各有独立的基础分值，每局开始时随机分配。\n"
		+ "[color=#42A5F5]每点基础分值在 5～15 之间，六种点数合计 60 点。[/color]\n"
		+ "只有组成骰型的骰子，其基础分值才计入得分。\n"
		+ "[color=#FFD700]单个骰型得分 = 参与骰子的基础分值之和 × 该骰型倍率[/color]\n"
		+ "[color=#AAAAAA]未组成骰型的骰子不产生分数。[/color]"
	),
	"dice_pocket": (
		"[color=#FFD700][font_size=20]骰子口袋[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "口袋最多保存 [color=#FFD700]1 个骰子[/color]，并加入下一次攻击的骰型计算。\n"
		+ "参与计分后立即消耗；未参与计分时进入掉落候选。\n"
		+ "[color=#42A5F5]只有 1 个掉落骰子时自动保留；多个时选择 1 个，其余丢弃。[/color]\n"
		+ "[color=#FFB74D]过关时口袋清空。[/color]"
	),
	"score_preview": (
		"[color=#FFD700][font_size=20]分数预告[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "预告本次选中攻击的骰型得分，[color=#FFD700]包含口袋骰子[/color]。\n"
		+ "[color=#42A5F5]BUFF 已改变的基础分值或骰型倍率，会反映在预告中。[/color]\n"
		+ "[color=#FFB74D]不包含攻击结算后由 BUFF 额外追加的分数。[/color]"
	),
	"buff_bar": (
		"[color=#FFD700][font_size=20]Buff 栏[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "展示本局已获得并生效的 BUFF，悬停图标可查看详情。\n"
		+ "[color=#FFD700]过关后可进入商店购买 BUFF。[/color]\n"
		+ "[color=#0fff5b]部分 BUFF 满足条件时会自动激活。[/color]"
	),
	"debuff_bar": (
		"[color=#FFD700][font_size=20]Debuff 栏[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "精英或 BOSS 可能带来一个或多个 DEBUFF。\n"
		+ "[color=#0fff5b]满足骰型门槛并击杀精英或 BOSS 后，可提前清除对应 DEBUFF。[/color]\n"
		+ "[color=#FFB74D]未提前清除的 DEBUFF 会在过关时统一清除。[/color]"
	),
	"skill_grid": (
		"[color=#FFD700][font_size=20]额外技能格[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "额外技能（金币技能）最多装备 [color=#FFD700]3 个[/color]。\n"
		+ "满栏购买时需要选择替换。\n"
		+ "[color=#42A5F5]每个技能每关可使用 1 次，过关恢复。[/color]\n"
		+ "[color=#FFD700]Q/W/E 分别对应三个技能槽位。[/color]"
	),
	"potion_progress": (
		"[color=#FFD700][font_size=20]血瓶进度[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "按骰型得分累计，[color=#FFB74D]不包含 BUFF 额外追加分数[/color]。\n"
		+ "达到要求获得 1 瓶血瓶，之后所需分数提高。\n"
		+ "[color=#42A5F5]血瓶达到存储上限时，需先使用血瓶腾出位置才能获得下一瓶。[/color]"
	),
	"exp_bar": (
		"[color=#FFD700][font_size=20]经验条[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "每击杀 1 个史莱姆获得 [color=#FFD700]1 点经验[/color]。\n"
		+ "经验满后从三张升级卡牌中选择 1 张。\n"
		+ "[color=#0fff5b]每升 5 级，生命上限 +1[/color]；[color=#FFB74D]当前生命不会因此恢复。[/color]"
	),
	"shield": (
		"[color=#FFD700][font_size=20]护盾[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "回合结算时按 [color=#42A5F5]剩余史莱姆数 － 护盾数[/color] 计算。\n"
		+ "结果小于等于 0 时不受伤；大于 0 时每 3 只造成 1 点伤害，零头也算 1 点。\n"
		+ "[color=#FFD700]例：7 只史莱姆、2 点护盾 → 受到 2 点伤害。[/color]"
	),
	"power": (
		"[color=#FFD700][font_size=20]能量[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "显示当前能量 / 能量上限。\n"
		+ "[color=#0fff5b]击杀青色高亮的能量史莱姆，恢复 1 点能量。[/color]\n"
		+ "[color=#42A5F5]赋能技能成功施放时消耗 1 点。[/color]\n"
		+ "[color=#FFB74D]部分技能必须先赋能才能使用。[/color]"
	),
	"hero_skill": (
		"[color=#FFD700][font_size=20]英雄技能[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "当前英雄的 3 个专属技能。\n"
		+ "[color=#FFD700]数字键 1/2/3 分别对应三个技能。[/color]"
	),
	"power_button": (
		"[color=#FFD700][font_size=20]赋能按钮[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "点击进入赋能状态，再点一次取消。\n"
		+ "[color=#FFB74D]没有能量时不能赋能；同时至多 1 个技能赋能。[/color]\n"
		+ "技能成功施放后消耗 1 点能量并复位。\n"
		+ "[color=#FFD700]快捷键：Alt+1/2/3[/color]"
	),
	"end_trun": (
		"[color=#FFD700][font_size=20]结束回合[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "放弃本次攻击并结束回合，获得随机颜色、随机 1～6 点的骰子。\n"
		+ "[color=#42A5F5]口袋已有骰子时，需要二选一保留。[/color]\n"
		+ "[color=#FFD700]快捷键：空格[/color]"
	),
	"reset_move": (
		"[color=#FFD700][font_size=20]重置移动[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "恢复英雄与场上史莱姆到移动前的位置，并回滚移动产生的分数。\n"
		+ "[color=#FFB74D]只有尚未攻击时才能撤回。[/color]\n"
		+ "[color=#FFD700]快捷键：R[/color]"
	),
	"use_potion": (
		"[color=#FFD700][font_size=20]使用血瓶[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "消耗 1 瓶血瓶恢复 1 点生命，不超过生命上限。\n"
		+ "[color=#FFB74D]没有血瓶或已满血时不能使用。[/color]\n"
		+ "[color=#AAAAAA]部分 BUFF 可以改变恢复量。[/color]\n"
		+ "[color=#FFD700]快捷键：F[/color]"
	),
	"close_help": (
		"[color=#FFD700][font_size=20]关闭帮助[/font_size][/color]\n"
		+ "[hr color=#777777 height=1 width=100%]\n"
		+ "关闭帮助界面并返回战局。\n"
		+ "[color=#FFD700]也可以按 H 关闭。[/color]"
	),
}

## key -> Array[Control]，记录已绑定的目标，便于测试/调试与语言切换时复用
var _bound_targets: Dictionary = {}
var _tooltips_bound := false

func _ready() -> void:
	_bind_tooltips()
	visibility_changed.connect(_on_visibility_changed)

func _notification(what: int) -> void:
	## 语言切换后重新取 tr() 文案；节点映射保持不变
	if what == NOTIFICATION_TRANSLATION_CHANGED and _tooltips_bound:
		_bind_tooltips()

## 遍历字典，按当前语言注册全部帮助项 tooltip
func _bind_tooltips() -> void:
	_bound_targets.clear()
	for key: String in HELP_TOOLTIPS:
		var text: String = tr(HELP_TOOLTIPS[key])
		var targets: Array[Control] = []
		for path: String in get_target_paths(key):
			var target := get_node_or_null(path)
			if target is Control:
				## 标注节点默认 MOUSE_FILTER_IGNORE，需改为 PASS 才能收到 hover，同时不挡住父级
				if target.mouse_filter == Control.MOUSE_FILTER_IGNORE:
					target.mouse_filter = Control.MOUSE_FILTER_PASS
				targets.append(target)
				TooltipManager.set_tooltip(target, text)
			else:
				push_warning("help_ui: tooltip target missing: %s" % path)
		_bound_targets[key] = targets
	_tooltips_bound = true

## 解析 key 的目标节点路径；close_help 返回文字标注与实际关闭按钮两个目标
func get_target_paths(key: String) -> Array[String]:
	var paths: Array[String] = []
	if TARGET_OVERRIDES.has(key):
		for path: String in TARGET_OVERRIDES[key]:
			paths.append(path)
	else:
		paths.append(TARGET_PATH_PATTERN % key)
	return paths

## 测试/调试入口：返回 key -> 已绑定的 Control 数组
func get_bound_targets() -> Dictionary:
	return _bound_targets

func _on_visibility_changed() -> void:
	## 帮助界面隐藏时回收仍可能残留的 tooltip
	if not visible:
		TooltipManager.hide_tooltip()
