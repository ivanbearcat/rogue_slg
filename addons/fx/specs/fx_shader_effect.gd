@tool
class_name FxShaderEffect
extends FxEffect


## FxShaderEffect — 基于 ShaderMaterial 的特效基类。
## 提供 shader 资源的 @export 与 shader 参数注入辅助。


## 创建 ShaderMaterial 并设置 shader。
func create_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	return mat


## 设置 shader 参数到 ShaderMaterial。
func set_shader_param(mat: ShaderMaterial, param_name: String, value: Variant) -> void:
	mat.set_shader_parameter(param_name, value)
