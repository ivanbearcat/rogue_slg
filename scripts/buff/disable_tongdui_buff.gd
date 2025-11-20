extends Buff

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.tooltip_text = buff_meta["debuff_tooltip"]
	data["tongdui_percent"] = Current.tongdui_percent
	Current.tongdui_percent = 0
	
func process_buff():
	data["tongdui_percent"] += Current.tongdui_percent
	Current.tongdui_percent = 0
	
func clear_buff():
	Current.tongdui_percent = data["tongdui_percent"]
	data.erase("tongdui_percent")
	debuff_texture.queue_free()
