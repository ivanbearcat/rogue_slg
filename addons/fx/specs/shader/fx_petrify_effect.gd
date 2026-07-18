@tool
class_name FxPetrifyEffect
extends FxShaderEffect


## FxPetrifyEffect — 石化特效。
## 挂载 petrify.gdshader 的 ShaderMaterial 到目标，呈现石化效果。
## 持续型特效，需 Fx.stop 取消。


@export var shader: Shader = preload("res://addons/fx/shaders/petrify.gdshader")
@export var duration: float = 10.0
@export var stone_color: Color = Color(0.5, 0.5, 0.5)
@export var crack_intensity: float = 0.5


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not target is CanvasItem:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("petrify_amount", 1.0)
	mat.set_shader_parameter("stone_color", stone_color)
	mat.set_shader_parameter("crack_intensity", crack_intensity)
	target.material = mat
