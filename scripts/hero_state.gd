extends Node2D
class_name HeroState

var hero_state_machine: HeroStateMachine
var hero: Hero

func _ready():
	await owner.ready

func unhandled_input(event: InputEvent):
	pass

func input(event: InputEvent):
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func enter():
	pass

func exit():
	pass
