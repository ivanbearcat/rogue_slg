@tool
class_name FxDissolveEffect
extends FxShaderEffect


## FxDissolveEffect — 溶解特效（死亡/消失）。
## 挂载 dissolve.gdshader 的 ShaderMaterial，dissolve_amount 从 0 到 1 渐变。


@export var shader: Shader = preload("res://addons/fx/shaders/dissolve.gdshader")
@export var duration: float = 1.0
@export var edge_color: Color = Color(1.0, 0.5, 0.0, 1.0)
@export var edge_width: float = 0.05


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not target is CanvasItem:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("dissolve_amount", 0.0)
	mat.set_shader_parameter("edge_color", edge_color)
	mat.set_shader_parameter("edge_width", edge_width)
	target.material = mat
	var tween: Tween = engine.get_tree().create_tween()
	tween.tween_property(mat, "shader_parameter/dissolve_amount", 1.0, duration)
