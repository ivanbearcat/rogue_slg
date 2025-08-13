extends Node2D
class_name Hero

signal hero_cmd

@onready var animated_sprite_2d: AnimatedSprite2D = $Area2D/AnimatedSprite2D
@onready var hero_state_machine: HeroStateMachine = $hero_state_machine
@onready var skill_1: Node2D = $hero_state_machine/skill_1
@onready var skill_2: Node2D = $hero_state_machine/skill_2
@onready var skill_3: Node2D = $hero_state_machine/skill_3


var hero_name: String
var hero_grid_index: Vector2i:
	get:
		for hero in Current.all_hero_array:
			if hero_name == hero.hero_name:
				return get_node("/root/game_manager")._position_to_grid_index(position)
		return Vector2i.ZERO
## 英雄移动力
var hero_movement: int

func _ready() -> void:
	animated_sprite_2d.play(hero_name + "_idle")
	skill_1.show_skill_range.connect(_on_show_skill_range)
	skill_1.hide_skill_range.connect(_on_hide_skill_range)
	skill_1.skill_attack.connect(_on_skill_attack)
	skill_2.show_skill_range.connect(_on_show_skill_range)
	skill_2.hide_skill_range.connect(_on_hide_skill_range)
	skill_2.skill_attack.connect(_on_skill_attack)
	#skill_3.show_skill_range.connect(_on_show_skill_range)
	#skill_3.hide_skill_range.connect(_on_hide_skill_range)
	#skill_3.skill_attack.connect(_on_skill_attack)
	skill_3.show_move_range.connect(_on_move_show_move_range)
	skill_3.hide_move_range.connect(_on_move_hide_move_range)
	skill_3.hero_move.connect(_on_move_hero_move)

	


func _on_area_2d_mouse_entered() -> void:
	Current.hero = self
	if hero_state_machine.state == hero_state_machine.get_node("idle"):
		animated_sprite_2d.material.set_shader_parameter("is_high_light", true)

func _on_area_2d_mouse_exited() -> void:
	animated_sprite_2d.material.set_shader_parameter("is_high_light", false)

func _on_move_show_move_range() -> void:
	emit_signal("hero_cmd", "show_move_range")

func _on_move_hide_move_range() -> void:
	Current.movable_grid_index_array = []
	emit_signal("hero_cmd", "hide_move_range")

func _on_move_hero_move() -> void:
	emit_signal("hero_cmd", "hero_move")

func _on_show_skill_range() -> void:
	emit_signal("hero_cmd", "show_skill_range")
	
func _on_hide_skill_range() -> void:
	emit_signal("hero_cmd", "hide_skill_range")

func _on_skill_attack():
	emit_signal("hero_cmd", "skill_attack")


func _on_animated_sprite_2d_animation_finished() -> void:
	Current.attack_animation_finished = 1
	#self.hero_state_machine.transition_to("end")
