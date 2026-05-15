extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]

func process_buff():
	var type_array: Array = Current.active_dice_types
	var type_to_percent := {
		"duizi": "duizi_percent",
		"shunzi": "shunzi_percent",
		"tongse": "tongse_percent",
		"tongdui": "tongdui_percent",
		"tongshun": "tongshun_percent",
	}
	for dice_type in type_array:
		if type_to_percent.has(dice_type):
			EffectManager.big_flow_effect(buff_texture)
			Current.set(type_to_percent[dice_type], Current.get(type_to_percent[dice_type]) + 2)

func clear_buff():
	pass
