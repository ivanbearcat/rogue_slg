@tool
class_name FxShieldBreakEffect
extends FxParticleEffect


## FxShieldBreakEffect — 护盾破碎特效。
## 实例化 shield_break.tscn 粒子场景到目标位置。


@export var scene: PackedScene = preload("res://addons/fx/effects/shield_break.tscn")
@export var lifetime: float = 1.0


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	var particle: Node = scene.instantiate()
	engine.add_to_scene(particle, target)
	if target is Node2D:
		particle.global_position = target.global_position
	elif target is Control:
		particle.position = target.position
	setup_particle(particle, params)
	engine.auto_free(particle, lifetime)
