extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	# 黄金之手效果在关卡结束时由 game_manager 委托调用 process_stage_clear() 执行
	pass

## 关卡结算时每有10个金币+1金币（由 game_manager 委托调用，非管线触发）
func process_stage_clear():
	var golden_touch_add = int(Current.total_coins / 10)
	if golden_touch_add > 0:
		Current.total_coins += golden_touch_add
		var float_number_instantiate = EffectManager.float_number_effect(golden_touch_add, "yellow")
		Current.hero.add_child(float_number_instantiate)
		await Tools.time_sleep(1)

func clear_buff():
	pass
