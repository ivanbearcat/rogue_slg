extends Buff

var _boosted_color: String = ""
var _suppressed_color: String = ""
var _color_scenes := {"green": "slime_small", "red": "slime_small_red", "yellow": "slime_small_yellow", "blue": "slime_small_blue"}

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))

func process_buff():
	var colors = ["green", "red", "yellow", "blue"]
	colors.shuffle()
	_boosted_color = colors[0]
	_suppressed_color = colors[1]
	var boosted_scene = _color_scenes[_boosted_color]
	var suppressed_scene = _color_scenes[_suppressed_color]
	game_manager.slime_scene_array.append(boosted_scene)
	var suppressed_indices := []
	for i in range(game_manager.slime_scene_array.size()):
		if game_manager.slime_scene_array[i] == suppressed_scene:
			suppressed_indices.append(i)
	for idx in suppressed_indices:
		game_manager.slime_scene_array.remove_at(idx)

func clear_buff():
	debuff_texture.queue_free()
