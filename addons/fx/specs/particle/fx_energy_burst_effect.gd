@tool
class_name FxEnergyBurstEffect
extends FxParticleEffect


## FxEnergyBurstEffect — 能量爆发特效。
## 实例化 energy_burst.tscn 粒子场景到目标位置。


@export var scene: PackedScene = preload("res://addons/fx/effects/energy_burst.tscn")
@export var amount: int = 30
@export var velocity_min: float = 50.0
@export var velocity_max: float = 120.0
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
