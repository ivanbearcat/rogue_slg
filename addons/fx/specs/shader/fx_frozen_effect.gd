@tool
class_name FxFrozenEffect
extends FxShaderEffect


## FxFrozenEffect — 冰冻特效。
## 挂载 frozen.gdshader 的 ShaderMaterial 到目标，呈现冰冻效果。
## 持续型特效，需 Fx.stop 取消。


@export var shader: Shader = preload("res://addons/fx/shaders/frozen.gdshader")
@export var duration: float = 5.0
@export var ice_color: Color = Color(0.5, 0.8, 1.0)
@export var crystal_intensity: float = 0.5


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not target is CanvasItem:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("freeze_amount", 1.0)
	mat.set_shader_parameter("ice_color", ice_color)
	mat.set_shader_parameter("crystal_intensity", crystal_intensity)
	target.material = mat
