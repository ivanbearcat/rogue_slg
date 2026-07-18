@tool
class_name FxHurtEffect
extends FxShaderEffect


## FxHurtEffect — 受击闪红特效。
## 挂载 flash_white.gdshader 的 ShaderMaterial 到目标，快速闪红后恢复。


@export var shader: Shader = preload("res://addons/fx/shaders/flash_white.gdshader")
@export var color: Color = Color.RED
@export var duration: float = 0.1


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	if not target is CanvasItem:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("flash_amount", 1.0)
	mat.set_shader_parameter("flash_color", color)
	target.material = mat
	# 动画 flash_amount 从 1 到 0
	var tween: Tween = engine.get_tree().create_tween()
	tween.tween_property(mat, "shader_parameter/flash_amount", 0.0, duration)
