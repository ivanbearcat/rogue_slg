extends Buff

var _immune_type: String = ""
var _saved_percent: int = 0
var _type_names := {"duizi": "对子", "shunzi": "顺子", "tongse": "同色", "tongdui": "同对", "tongshun": "同顺"}
var _type_vars := {"duizi": "duizi_percent", "shunzi": "shunzi_percent", "tongse": "tongse_percent", "tongdui": "tongdui_percent", "tongshun": "tongshun_percent"}

func set_buff():
	var texture = load(buff_meta["buff_icon"])
	buff_texture = SceneManager.create_scene("buff_texture")
	buff_texture.texture = texture
	game_manager.buff_container.add_child(buff_texture)
	## 随机选择1个骰型免疫
	var types = _type_names.keys()
	_immune_type = types[randi_range(0, types.size() - 1)]
	buff_texture.set_rich_tooltip(TooltipFormatter.format_buff(buff_meta, "（免疫" + _type_names[_immune_type] + "）"))

func process_buff():
	## 在disable buff将倍率设为0后，恢复免疫骰型的倍率
	var percent_var: String = _type_vars[_immune_type]
	var current_val: int = Current.get(percent_var)
	if current_val == 0 and _saved_percent > 0:
		Current.set(percent_var, _saved_percent)
		EffectManager.big_flow_effect(buff_texture)
	_saved_percent = Current.get(percent_var)

func clear_buff():
	pass
