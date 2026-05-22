extends Buff

var _defense_applied := false

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"]

func process_buff():
	## 回退上回合的临时加成
	if _defense_applied:
		Current.player_defense -= 2
		_defense_applied = false
	## HP≤2时临时+2防御
	if Current.player_hp <= 2:
		Current.player_defense += 2
		_defense_applied = true

func clear_buff():
	## 清除时回退临时加成
	if _defense_applied:
		Current.player_defense -= 2
		_defense_applied = false
