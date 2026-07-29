extends Buff

func _init(meta: Dictionary = {}, game_manager_node: Node2D = null) -> void:
	super(meta, game_manager_node)

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))
	var disabled_points = buff_meta.get("data", {}).get("disabled_points", [])
	var score_map := {
		1: "one_score",
		2: "two_score",
		3: "three_score",
		4: "four_score",
		5: "five_score",
		6: "six_score",
	}
	for point in disabled_points:
		if score_map.has(point):
			var key = score_map[point]
			data[key] = Current.get(key)
			Current.set(key, 0)

func process_buff():
	var disabled_points = buff_meta.get("data", {}).get("disabled_points", [])
	var score_map := {
		1: "one_score",
		2: "two_score",
		3: "three_score",
		4: "four_score",
		5: "five_score",
		6: "six_score",
	}
	for point in disabled_points:
		if score_map.has(point):
			var key = score_map[point]
			data[key] = data.get(key, 0) + Current.get(key)
			Current.set(key, 0)

func clear_buff():
	var disabled_points = buff_meta.get("data", {}).get("disabled_points", [])
	var score_map := {
		1: "one_score",
		2: "two_score",
		3: "three_score",
		4: "four_score",
		5: "five_score",
		6: "six_score",
	}
	for point in disabled_points:
		if score_map.has(point):
			var key = score_map[point]
			if data.has(key):
				Current.set(key, data[key])
				data.erase(key)
	debuff_texture.queue_free()
