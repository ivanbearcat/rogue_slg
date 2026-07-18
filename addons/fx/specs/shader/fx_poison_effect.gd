@tool
class_name FxPoisonEffect
extends FxShaderEffect


## FxPoisonEffect — 中毒特效。
## 挂载 poison.gdshader 的 ShaderMaterial 到目标，呈现绿色脉动中毒效果。
## 持续型特效，需 Fx.stop 取消。


@export var shader: Shader = preload("res://addons/fx/shaders/poison.gdshader")
@export var duration: float = 3.0
@export var poison_color: Color = Color(0.3, 1.0, 0.3)
@export var pulse_speed: float = 3.0


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not target is CanvasItem:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("poison_amount", 1.0)
	mat.set_shader_parameter("poison_color", poison_color)
	mat.set_shader_parameter("pulse_speed", pulse_speed)
	target.material = mat
