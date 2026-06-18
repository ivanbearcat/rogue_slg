extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	if randf() < 0.3:
		var _dice_types = ["duizi", "shunzi", "tongse", "tongdui", "tongshun"]
		var _rand_type = _dice_types[randi_range(0, 4)]
		EffectManager.buff_pop_effect(buff_texture)
		match _rand_type:
			"duizi": Current.duizi_percent += 3; game_manager._update_multiplier_dict("duizi_percent", "add", 3)
			"shunzi": Current.shunzi_percent += 3; game_manager._update_multiplier_dict("shunzi_percent", "add", 3)
			"tongse": Current.tongse_percent += 3; game_manager._update_multiplier_dict("tongse_percent", "add", 3)
			"tongdui": Current.tongdui_percent += 3; game_manager._update_multiplier_dict("tongdui_percent", "add", 3)
			"tongshun": Current.tongshun_percent += 3; game_manager._update_multiplier_dict("tongshun_percent", "add", 3)

func clear_buff():
	pass
