extends Buff

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.overlord_container.add_child(buff_texture)
	## 领主激活动画：scale 0→1.2→1 + modulate.a 0→1
	buff_texture.scale = Vector2.ZERO
	buff_texture.modulate.a = 0.0
	var tween = buff_texture.create_tween()
	tween.tween_property(buff_texture, "scale", Vector2(1.2, 1.2), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(buff_texture, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(buff_texture, "modulate:a", 1.0, 0.3)
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta))

func process_buff():
	# 族主逻辑在 buff_system._apply_overlord_multiplier() 和 game_manager 回血流程中处理
	pass

func clear_buff():
	pass
