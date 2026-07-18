@tool
class_name FxBurnEffect
extends FxShaderEffect


## FxBurnEffect — 燃烧特效。
## 挂载 burning.gdshader 的 ShaderMaterial 到目标，呈现燃烧效果。


@export var shader: Shader = preload("res://addons/fx/shaders/burning.gdshader")
@export var duration: float = 2.0
@export var intensity: float = 1.0
@export var color: Color = Color(1, 0.6, 0.2)


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not target is CanvasItem:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("burn_amount", 0.0)
	mat.set_shader_parameter("fire_color1", Color(color.r, color.g * 0.8, color.b * 0.2, 1.0))
	mat.set_shader_parameter("fire_color2", Color(color.r, color.g * 0.3, 0.0, 1.0))
	target.material = mat
	# 动画 burn_amount 从 0 到 intensity
	var tween: Tween = engine.get_tree().create_tween()
	tween.tween_property(mat, "shader_parameter/burn_amount", intensity, duration)
