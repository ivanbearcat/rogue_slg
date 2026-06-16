extends Buff

var _active_this_turn := false

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	## 回退上回合的加成标记
	if _active_this_turn:
		Current.scorched_earth_bonus = 0.0
		_active_this_turn = false
	## HP>2时扣1HP并激活本回合+35%得分加成
	if Current.player_hp > 2:
		Current.player_hp -= 1
		Current.scorched_earth_bonus = 0.35
		_active_this_turn = true
		EffectManager.buff_pop_effect(buff_texture)

func clear_buff():
	## 清除时回退加成标记
	if _active_this_turn:
		Current.scorched_earth_bonus = 0.0
		_active_this_turn = false
