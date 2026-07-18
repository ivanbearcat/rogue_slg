@tool
class_name FxWallSlideSparkEffect
extends FxParticleEffect


## FxWallSlideSparkEffect — 墙壁滑动火花特效（持续型）。
## 实例化 wall_slide_spark.tscn 粒子场景到目标位置。
## 返回节点不自动 free，由调用方管理。


@export var scene: PackedScene = preload("res://addons/fx/effects/wall_slide_spark.tscn")


func _apply(target: Node, engine: FxEngine, params: Dictionary) -> void:
	var particle: Node = scene.instantiate()
	engine.add_to_scene(particle, target)
	if target is Node2D:
		particle.global_position = target.global_position
	elif target is Control:
		particle.position = target.position
	setup_particle(particle, params)
	# 持续型：不自动 free
