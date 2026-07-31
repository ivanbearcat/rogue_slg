@tool
class_name FxAshParticlesEffect
extends FxParticleEffect


## FxAshParticlesEffect — 灰烬粒子 环境特效（持续型）。
## 实例化 ash_particles.tscn 粒子场景到目标位置。
## 返回节点不自动 free，由调用方管理。


@export var scene: PackedScene = preload("res://addons/fx/effects/ash_particles.tscn")


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	var particle: Node = scene.instantiate()
	engine.add_to_scene(particle, target)
	if target is Node2D:
		particle.global_position = target.global_position
	elif target is Control:
		particle.position = target.position
	setup_particle(particle, params)
	# 持续型：不自动 free
