extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]
	
func process_buff():
	for i in range(Current.slime_die_sum):
		var _rand_num = randi_range(1, 6)
		EffectManager.big_flow_effect(buff_texture)
		match _rand_num:
			1:
				Current.none_percent += int(Current.none_percent * 0.02)
			2:
				Current.duizi_percent += int(Current.duizi_percent * 0.02)
			3:
				Current.shunzi_percent += int(Current.shunzi_percent * 0.02)
			4:
				Current.tongse_percent += int(Current.tongse_percent * 0.02)
			5:
				Current.tongdui_percent += int(Current.tongdui_percent * 0.02)
			6:
				Current.tongshun_percent += int(Current.tongshun_percent * 0.02)
				
			
func clear_buff():
	pass
