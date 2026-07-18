@tool
class_name FxOutlineEffect
extends FxShaderEffect


## FxOutlineEffect — 描边发光特效。
## 挂载 outline_glow.gdshader 的 ShaderMaterial 到目标，呈现描边效果。
## 无 duration（持续型，需 Fx.stop 取消）。


@export var shader: Shader = preload("res://addons/fx/shaders/outline_glow.gdshader")
@export var color: Color = Color.WHITE
@export var width: float = 2.0


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not target is CanvasItem:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("outline_color", color)
	mat.set_shader_parameter("outline_width", width)
	target.material = mat
