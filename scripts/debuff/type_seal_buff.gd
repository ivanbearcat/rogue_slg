extends Buff

## 骰型封印（type_seal）：把封印骰型的倍率在两处存储同步归零——
## 1) 倍率表 Current.dice_multiplier_dict 的该骰型整列：结算（ScoringAlgorithm 计分查表）、
##    攻击预览（skill_system._show_dice_panel 查表写入显示值）、预览重置（_reset_dice_panel
##    查表恢复显示值）三条路径共用真相，封印写入表内即三路同步生效。
##    （修复：此前只归零显示值 Current.<骰型>_percent，倍率表未动 →
##    框选→取消→再框选后显示值被表内原值写回"解除封印"，且结算照常按原倍率计分）
## 2) 计分板显示值 Current.<骰型>_percent（既有语义，set 即生效）。
## 原值存 data：<骰型>_percent 键存显示值原值，mult_<骰型> 键存 {dice_sum: 表列原值}；
## clear_buff 恢复；封印期间被加进两处的增量由 process_buff 吸进保存值（clear 时归还）。

## 骰型名 → 计分板显示属性名
const TYPE_MAP := {
	"duizi": "duizi_percent",
	"shunzi": "shunzi_percent",
	"tongse": "tongse_percent",
	"tongdui": "tongdui_percent",
	"tongshun": "tongshun_percent",
}

func _init(meta: Dictionary = {}, game_manager_node: Node2D = null) -> void:
	super(meta, game_manager_node)

func set_buff():
	var texture = load(buff_meta["debuff_icon"])
	debuff_texture = SceneManager.create_scene("debuff_texture")
	debuff_texture.texture = texture
	game_manager.debuff_container.add_child(debuff_texture)
	debuff_texture.set_rich_tooltip(TooltipFormatter.format_debuff(buff_meta))
	for dice_type in _disabled_types():
		var key: String = TYPE_MAP[dice_type]
		## 计分板显示值：存原值并归零
		data[key] = Current.get(key)
		Current.set(key, 0)
		## 倍率表整列：存各档位原值并归零
		var column := {}
		for dice_sum in Current.dice_multiplier_dict.keys():
			column[int(dice_sum)] = int(Current.dice_multiplier_dict[dice_sum][dice_type])
			Current.dice_multiplier_dict[dice_sum][dice_type] = 0
		data["mult_" + dice_type] = column

func process_buff():
	for dice_type in _disabled_types():
		var key: String = TYPE_MAP[dice_type]
		## 显示值被改动（预览重置写回/买buff加值）→ 吸进保存值后重申归零
		data[key] = data.get(key, 0) + Current.get(key)
		Current.set(key, 0)
		## 倍率表列同款语义：封印期间加进表列的增量吸进保存列，重申归零
		var column: Dictionary = data.get("mult_" + dice_type, {})
		for dice_sum in Current.dice_multiplier_dict.keys():
			column[int(dice_sum)] = column.get(int(dice_sum), 0) \
					+ int(Current.dice_multiplier_dict[dice_sum][dice_type])
			Current.dice_multiplier_dict[dice_sum][dice_type] = 0
		data["mult_" + dice_type] = column

func clear_buff():
	for dice_type in _disabled_types():
		var key: String = TYPE_MAP[dice_type]
		if data.has(key):
			Current.set(key, data[key])
			data.erase(key)
		var column_key: String = "mult_" + str(dice_type)
		if data.has(column_key):
			for dice_sum in data[column_key].keys():
				## 键经 JSON 存档往返可能变字符串，统一按 int 归一化查表
				var sum_int := int(dice_sum)
				if Current.dice_multiplier_dict.has(sum_int):
					Current.dice_multiplier_dict[sum_int][dice_type] = data[column_key][dice_sum]
			data.erase(column_key)
	clear_debuff_texture()

## buff_meta.data.disabled_types 中映射合法的骰型名
func _disabled_types() -> Array:
	var valid := []
	for dice_type in buff_meta.get("data", {}).get("disabled_types", []):
		if TYPE_MAP.has(dice_type):
			valid.append(dice_type)
	return valid

## ============================================================
## 存档钩子（读档 rebuild 路径闭环）
## ============================================================
## rebuild_from_save 次序为 实例化 → set_buff（此时倍率表已是被封印的存档快照 0，
## data 会照 0 污染）→ restore_state。此处用存档时的 data 原值覆盖修正，
## 并重申两处存储的封禁态（防存档瞬间预览写回的残留）。

func save_state() -> Dictionary:
	return {"seal_data": data.duplicate(true)}

func restore_state(state: Dictionary) -> void:
	var seal_data: Dictionary = state.get("seal_data", {})
	if seal_data.is_empty():
		return
	data = seal_data.duplicate(true)
	## JSON 往返归一化：mult_ 列键变字符串 → 转 int；数值 float → 转 int
	for data_key in data.keys():
		if str(data_key).begins_with("mult_"):
			var raw: Dictionary = data[data_key]
			var normalized := {}
			for k in raw.keys():
				normalized[int(k)] = int(raw[k])
			data[data_key] = normalized
		else:
			data[data_key] = int(data[data_key])
	## 重申封禁态：显示值与倍率表列归零
	for dice_type in _disabled_types():
		Current.set(TYPE_MAP[dice_type], 0)
		for dice_sum in Current.dice_multiplier_dict.keys():
			Current.dice_multiplier_dict[dice_sum][dice_type] = 0
