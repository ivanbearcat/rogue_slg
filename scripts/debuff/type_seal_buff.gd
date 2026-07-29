extends Buff

func _init(meta: Dictionary = {}, game_manager_node: Node2D = null) -> void:
	super(meta, game_manager_node)

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))
	var disabled_types = buff_meta.get("data", {}).get("disabled_types", [])
	var type_map := {
		"duizi": "duizi_percent",
		"shunzi": "shunzi_percent",
		"tongse": "tongse_percent",
		"tongdui": "tongdui_percent",
		"tongshun": "tongshun_percent",
	}
	for dice_type in disabled_types:
		if type_map.has(dice_type):
			var key = type_map[dice_type]
			data[key] = Current.get(key)
			Current.set(key, 0)

func process_buff():
	var disabled_types = buff_meta.get("data", {}).get("disabled_types", [])
	var type_map := {
		"duizi": "duizi_percent",
		"shunzi": "shunzi_percent",
		"tongse": "tongse_percent",
		"tongdui": "tongdui_percent",
		"tongshun": "tongshun_percent",
	}
	for dice_type in disabled_types:
		if type_map.has(dice_type):
			var key = type_map[dice_type]
			data[key] = data.get(key, 0) + Current.get(key)
			Current.set(key, 0)

func clear_buff():
	var disabled_types = buff_meta.get("data", {}).get("disabled_types", [])
	var type_map := {
		"duizi": "duizi_percent",
		"shunzi": "shunzi_percent",
		"tongse": "tongse_percent",
		"tongdui": "tongdui_percent",
		"tongshun": "tongshun_percent",
	}
	for dice_type in disabled_types:
		if type_map.has(dice_type):
			var key = type_map[dice_type]
			if data.has(key):
				Current.set(key, data[key])
				data.erase(key)
	debuff_texture.queue_free()
