extends Node
## MockBuffSystem - 替代 BuffSystem autoload 用于测试

var _registered_buffs: Dictionary = {}  # buff_id -> Buff
var _family_counts: Dictionary = {}  # family -> count

func get_family_count(family_name: String) -> int:
	return _family_counts.get(family_name, 0)

func get_buffs_by_tag(tag: String) -> Array:
	var result = []
	for buff_id in _registered_buffs:
		var buff = _registered_buffs[buff_id]
		if tag in buff.tags:
			result.append(buff)
	return result

func is_buff_registered(buff_id: String) -> bool:
	return _registered_buffs.has(buff_id)

func register_buff(buff_id: String, buff) -> void:
	_registered_buffs[buff_id] = buff
	if buff.family != "":
		_family_counts[buff.family] = _family_counts.get(buff.family, 0) + 1

func clear_registered() -> void:
	_registered_buffs.clear()
	_family_counts.clear()