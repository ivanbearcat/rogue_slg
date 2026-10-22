extends Buff

## count_slime_reroll 不入存档快照（生命周期核对结论，task 3.2）：
## 它是单次 process_buff 执行内的瞬态计数——await 循环里累加、循环结束后立即归零，
## 不跨回合存活，读档重置为 0 与原语义等价。
var count_slime_reroll := 0

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))

func process_buff():
	Current.public_lock_array.append("slime_chaos_buff")
	game_manager.slime_reroll_finished.connect(count_slime_reroll_finished)
	var count := 0
	for slime in Current.all_enemy_array:
		game_manager.slime_reroll(slime)
		count += 1
	while count_slime_reroll != count:
		await Tools.time_sleep(0.05)
	count_slime_reroll = 0
	Current.public_lock_array.erase("slime_chaos_buff")

func count_slime_reroll_finished():
	count_slime_reroll += 1

func clear_buff():
	clear_debuff_texture()
