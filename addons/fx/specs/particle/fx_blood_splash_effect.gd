@tool
class_name FxBloodSplashEffect
extends FxParticleEffect


## FxBloodSplashEffect — 血溅特效。
## 实例化 blood_splash.tscn 粒子场景到目标位置。


@export var scene: PackedScene = preload("res://addons/fx/effects/blood_splash.tscn")
@export var color: Color = Color(0.8, 0.1, 0.1)
@export var amount: int = 20
@export var velocity_min: float = 80.0
@export var velocity_max: float = 150.0
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
