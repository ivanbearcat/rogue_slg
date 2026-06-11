extends Buff

## 点数到图标的映射
const POINT_ICON_MAP := {
	1: "res://images/enemy_icon/disable_one.png",
	2: "res://images/enemy_icon/disable_two.png",
	3: "res://images/enemy_icon/disable_three.png",
	4: "res://images/enemy_icon/disable_four.png",
	5: "res://images/enemy_icon/disable_five.png",
	6: "res://images/enemy_icon/disable_six.png",
}

func _init(meta: Dictionary = {}, game_manager_node: Node2D = null) -> void:
	super(meta, game_manager_node)
	# 如果 data 中有 candidate_points（候选池）且没有 disabled_points，随机选一个
	var data_dict: Dictionary = buff_meta.get("data", {})
	if not data_dict.has("disabled_points") and data_dict.has("candidate_points"):
		_randomize_point()

## 从候选点数中随机选1个，更新 buff_meta
func _randomize_point() -> void:
	var candidates: Array = buff_meta.get("data", {}).get("candidate_points", [])
	if candidates.is_empty():
		return
	var chosen: int = candidates[randi() % candidates.size()]
	# 设置选中的点数
	buff_meta["data"]["disabled_points"] = [chosen]
	# 替换图标为对应点数的图标
	if POINT_ICON_MAP.has(chosen):
		buff_meta["debuff_icon"] = POINT_ICON_MAP[chosen]

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
