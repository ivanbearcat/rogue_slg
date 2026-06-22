extends Buff

## 骰型到图标的映射
const TYPE_ICON_MAP := {
	"duizi": "res://images/debuff_icon/disable_duizi.png",
	"shunzi": "res://images/debuff_icon/disable_shunzi.png",
	"tongse": "res://images/debuff_icon/disable_tongse.png",
	"tongdui": "res://images/debuff_icon/disable_tongdui.png",
	"tongshun": "res://images/debuff_icon/disable_tongshun.png",
}

func _init(meta: Dictionary = {}, game_manager_node: Node2D = null) -> void:
	super(meta, game_manager_node)
	# 如果 data 中有 candidate_types（候选池）且没有 disabled_types，随机选一个
	var data_dict: Dictionary = buff_meta.get("data", {})
	if not data_dict.has("disabled_types") and data_dict.has("candidate_types"):
		_randomize_type()

## 从候选骰型中随机选1个，更新 buff_meta
func _randomize_type() -> void:
	var candidates: Array = buff_meta.get("data", {}).get("candidate_types", [])
	if candidates.is_empty():
		return
	var chosen: String = candidates[randi() % candidates.size()]
	# 设置选中的骰型
	buff_meta["data"]["disabled_types"] = [chosen]
	# 替换图标为对应骰型的图标
	if TYPE_ICON_MAP.has(chosen):
		buff_meta["debuff_icon"] = TYPE_ICON_MAP[chosen]

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
