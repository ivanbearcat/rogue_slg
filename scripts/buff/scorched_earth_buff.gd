extends Buff

var _active_this_turn := false

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	var timing = BuffSystem._current_timing
	if timing == "pre_hero_turn":
		_do_pre_hero_turn()
	elif timing == "post_attack":
		_do_post_attack()

## pre_hero_turn：扣血并激活本回合加成标记
func _do_pre_hero_turn():
	## 回退上回合残留的加成标记（如跳过攻击回合时）
	if _active_this_turn:
		Current.scorched_earth_bonus = 0.0
		_active_this_turn = false
	## HP>2时扣1HP并激活本回合+35%得分加成
	if Current.player_hp > 2:
		Current.player_hp -= 1
		Current.scorched_earth_bonus = 0.35
		_active_this_turn = true
		EffectManager.buff_pop_effect(buff_texture)

## post_attack：攻击动画完成后加分飘字（与其他post_attack buff时序一致）
func _do_post_attack():
	if Current.scorched_earth_bonus > 0:
		var se_add_num = roundi(Current.once_total_score * Current.scorched_earth_bonus)
		if se_add_num > 0:
			var se_float_number = EffectManager.float_number_effect(se_add_num)
			Current.hero.add_child(se_float_number)
			Current.total_score += se_add_num
			EffectManager.buff_pop_effect(buff_texture)

func clear_buff():
	## 清除时回退加成标记
	if _active_this_turn:
		Current.scorched_earth_bonus = 0.0
		_active_this_turn = false
