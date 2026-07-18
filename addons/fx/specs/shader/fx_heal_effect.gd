@tool
class_name FxHealEffect
extends FxShaderEffect


## FxHealEffect — 治疗特效。
## 挂载 color_change.gdshader 的 ShaderMaterial 到目标，呈现绿色治疗光效。


@export var shader: Shader = preload("res://addons/fx/shaders/color_change.gdshader")
@export var color: Color = Color.GREEN
@export var duration: float = 0.5
@export var mix_amount: float = 0.7


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not target is CanvasItem:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("target_color", color)
	mat.set_shader_parameter("mix_amount", mix_amount)
	mat.set_shader_parameter("preserve_luminance", true)
	target.material = mat
	# 动画 mix_amount 从 mix_amount 到 0（恢复原色）
	var tween: Tween = engine.get_tree().create_tween()
	tween.tween_property(mat, "shader_parameter/mix_amount", 0.0, duration)
