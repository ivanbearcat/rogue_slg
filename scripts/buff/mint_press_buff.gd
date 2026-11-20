extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	## 薄荷压榨：击杀≥3 只 +2 金币（资源类，非得分贡献 → 不申报）
	## 申报制迁移：删除英雄位置飘字与硬等待（post_attack 管线禁 time_sleep），
	## 金币反馈由 total_coins 的金币 label 更新承载；图标闪烁保留归属提示。
	## ⚠️ 删除 sleep 后 process_buff 变同步上下文，EffectManager.buff_pop_effect
	## 为 void coroutine 不能在此 fire——改用同序列的同步 tween（去尾部 await）
	if Current.slime_die_sum >= 3:
		Current.total_coins += 2
		_pop_buff_texture()

## 同步版图标闪烁（modulate 序列与 EffectManager.buff_pop_effect 一致；
## 该公共函数为 coroutine，同步上下文内调用会编译失败，故此处内联同款）
func _pop_buff_texture() -> void:
	if buff_texture == null or not is_instance_valid(buff_texture):
		return
	var orig_modulate = buff_texture.modulate
	var tween = buff_texture.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(buff_texture, "modulate", Color(3, 3, 3, 1), 0.05)
	tween.tween_property(buff_texture, "modulate", Color(0.7, 0.7, 0.7, 1), 0.05)
	tween.tween_property(buff_texture, "modulate", Color(2.5, 2.5, 2.5, 1), 0.05)
	tween.tween_property(buff_texture, "modulate", orig_modulate, 0.1)

func clear_buff():
	pass
