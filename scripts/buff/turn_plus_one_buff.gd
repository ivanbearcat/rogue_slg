extends Buff

var _is_used := false

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]
	
func process_buff():
	if Current.count_round == 1 and _is_used == false:
		EffectManager.big_flow_effect(buff_texture)
		Current.count_round -= 1
		_is_used = true
	if Current.count_round == 1 and _is_used == true:
		_is_used = false
		
func clear_buff():
	pass
