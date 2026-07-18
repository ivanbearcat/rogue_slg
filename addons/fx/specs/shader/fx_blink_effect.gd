@tool
class_name FxBlinkEffect
extends FxShaderEffect


## FxBlinkEffect — 闪烁特效。
## 挂载 blink.gdshader 的 ShaderMaterial 到目标，呈现闪烁效果。
## 无 duration（持续型，需 Fx.stop 取消）。


@export var shader: Shader = preload("res://addons/fx/shaders/blink.gdshader")
@export var color: Color = Color.WHITE
@export var frequency: float = 10.0


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not target is CanvasItem:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("blink_speed", frequency)
	target.material = mat
	target.modulate = color
