extends Node
## MockEffectManager - 替代 EffectManager autoload 用于测试

var _float_effects: Array = []
var _big_flow_effects: Array = []

func float_number_effect(value, color: String = "") -> Node2D:
	var effect = Node2D.new()
	_float_effects.append({"value": value, "color": color, "node": effect})
	return effect

func big_flow_effect(target) -> void:
	_big_flow_effects.append(target)

func clear_effects() -> void:
	_float_effects.clear()
	_big_flow_effects.clear()
