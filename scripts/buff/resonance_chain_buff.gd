extends Buff

var chain_multiplier: float = 0.0

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta, _get_tooltip_extra()))

func process_buff():
	## 1. 先应用本次叠层效益（上次累积的 chain_multiplier）
	if chain_multiplier > 0.0:
		Current.public_lock_array.append("resonance_chain_buff")
		var add_num = int(Current.once_total_score * chain_multiplier)
		var float_number_instantiate = EffectManager.float_number_effect(add_num)
		Current.hero.add_child(float_number_instantiate)
		EffectManager.buff_pop_effect(buff_texture)
		await Tools.time_sleep(1)
		Current.total_score += add_num
		Current.public_lock_array.erase("resonance_chain_buff")
	## 2. 判定本次是否触发同色类骰型，调整叠层
	var triggered := false
	for dice_type in Current.active_dice_types:
		if dice_type in ["tongse", "tongdui", "tongshun"]:
			triggered = true
			break
	if triggered:
		chain_multiplier += 0.10
	else:
		chain_multiplier = max(0.0, chain_multiplier - 0.10)

func clear_buff():
	chain_multiplier = 0.0

## 覆写以提供 hover 时动态追加的"当前叠层"行（BBCode着色）
func _get_tooltip_extra() -> String:
	var n := int(chain_multiplier / 0.10)
	var m := int(chain_multiplier * 100)
	return "\n[color=#42A5F5]当前叠层：%d层（+%d%%）[/color]" % [n, m]
