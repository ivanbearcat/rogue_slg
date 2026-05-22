extends Buff

var _immune_point: int = 0
var _saved_score: int = 0
var _point_names := {1: "一点", 2: "二点", 3: "三点", 4: "四点", 5: "五点", 6: "六点"}
var _score_vars := {1: "one_score", 2: "two_score", 3: "three_score", 4: "four_score", 5: "five_score", 6: "six_score"}

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	## 随机选择1个点数免疫
	_immune_point = randi_range(1, 6)
	buff_texture.tooltip_text = buff_meta["buff_tooltip"] + "（免疫" + _point_names[_immune_point] + "）"

func process_buff():
	## 在disable buff将分数设为0后，恢复免疫点数的分数
	## 保存被禁用前的分数，如果当前为0则恢复
	var score_var: String = _score_vars[_immune_point]
	var current_val: int = Current.get(score_var)
	if current_val == 0 and _saved_score > 0:
		Current.set(score_var, _saved_score)
		EffectManager.big_flow_effect(buff_texture)
	_saved_score = Current.get(score_var)

func clear_buff():
	pass
