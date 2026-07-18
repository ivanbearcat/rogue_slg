@tool
class_name FxParticleEffect
extends FxEffect


## FxParticleEffect — 基于粒子场景的特效基类。
## 提供粒子场景 preload 路径的 @export 与参数注入逻辑（粒子数、初速、颜色等）。


## 设置粒子节点参数的通用辅助。
## 子类可覆盖以注入特定参数。
func setup_particle(particle_node: Node, _params: Dictionary) -> void:
	if particle_node is CPUParticles2D:
		particle_node.emitting = true
	elif particle_node is GPUParticles2D:
		particle_node.emitting = true
