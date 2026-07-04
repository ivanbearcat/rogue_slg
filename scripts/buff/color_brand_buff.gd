extends Buff

## 同色烙印：跨回合颜色承诺
## 记录上一回合击杀的史莱姆主色，本回合击杀同色时 +25% 加成
var branded_color: String = ""

## 颜色→中文名映射
const COLOR_CN := {"green": "绿", "red": "红", "blue": "蓝", "yellow": "黄"}

## 颜色→BBCode颜色码映射
const COLOR_CODE := {"green": "#4CAF50", "red": "#F44336", "blue": "#2196F3", "yellow": "#FFD700"}

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	_update_tooltip()

func process_buff():
	## 1. 烙印匹配加成：若 branded_color 存在于本回合击杀列表中，则 +25%
	if branded_color != "" and branded_color in Current.killed_slime_colors:
		Current.public_lock_array.append("color_brand_buff")
		var add_num = int(Current.once_total_score * 0.25)
		var float_number_instantiate = EffectManager.float_number_effect(add_num)
		Current.hero.add_child(float_number_instantiate)
		EffectManager.buff_pop_effect(buff_texture)
		await Tools.time_sleep(1)
		Current.total_score += add_num
		Current.public_lock_array.erase("color_brand_buff")
	## 2. 统计本回合击杀主色，更新烙印（平票或无击杀则保持不变）
	_update_branded_color()
	## 3. 更新tooltip显示当前烙印颜色
	_update_tooltip()

func clear_buff():
	branded_color = ""
	_update_tooltip()

## 覆写以提供 hover 时动态追加的"当前烙印"行（BBCode着色）
func _get_tooltip_extra() -> String:
	if branded_color != "":
		var cn := str(COLOR_CN.get(branded_color, branded_color))
		var code := str(COLOR_CODE.get(branded_color, "#FFFFFF"))
		return "\n[color=%s]当前烙印：%s[/color]" % [code, cn]
	else:
		return "\n[color=#888888]当前烙印：无[/color]"

## 更新tooltip（fallback：缓存_rich_tooltip_text，hover时会动态重生成）
func _update_tooltip() -> void:
	if buff_texture == null:
		return
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta, _get_tooltip_extra()))

## 统计 killed_slime_colors 中出现次数最多的颜色作为新主色
## 若存在唯一主色（无平票）则更新 branded_color，否则保持不变
func _update_branded_color() -> void:
	var colors: Array = Current.killed_slime_colors
	if colors.is_empty():
		return
	var count_dict := {}
	for c in colors:
		count_dict[c] = count_dict.get(c, 0) + 1
	var max_count := 0
	var max_color := ""
	var tie := false
	for c in count_dict:
		if count_dict[c] > max_count:
			max_count = count_dict[c]
			max_color = c
			tie = false
		elif count_dict[c] == max_count:
			tie = true
	if not tie and max_color != "":
		branded_color = max_color
