extends Node2D
class_name Hero

signal hero_cmd

@onready var animated_sprite_2d: AnimatedSprite2D = $Area2D/AnimatedSprite2D
@onready var hero_state_machine: HeroStateMachine = $hero_state_machine

var hero_name: String
var hero_grid_index: Vector2i
var hero_move: int

func _ready() -> void:
	animated_sprite_2d.play(hero_name + "_idle")

func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	Current.hero = self
	animated_sprite_2d.material.set_shader_parameter("is_high_light", true)
	if hero_state_machine.state == hero_state_machine.get_node("idle"):
		if Current.clicked_hero == null:
			await get_tree().create_timer(0.01).timeout
			emit_signal("hero_cmd", "show_move_range")


func _on_area_2d_mouse_exited() -> void:
	animated_sprite_2d.material.set_shader_parameter("is_high_light", false)
	if hero_state_machine.state == hero_state_machine.get_node("idle"):
		if Current.clicked_hero == null:
			emit_signal("hero_cmd", "hide_move_range")


func _on_move_show_move_range() -> void:
	emit_signal("hero_cmd", "show_move_range")


func _on_move_hide_move_range() -> void:
	Current.movable_grid_index_array = []
	emit_signal("hero_cmd", "hide_move_range")


func _on_move_hero_move() -> void:
	emit_signal("hero_cmd", "hero_move")
