extends Node2D
class_name Hero

signal hero_cmd(cmd_name: String, event: InputEvent)

@onready var animated_sprite_2d: AnimatedSprite2D = $Area2D/AnimatedSprite2D
@onready var hero_state_machine: HeroStateMachine = $hero_state_machine
@onready var skill_1: Node2D = $hero_state_machine/skill_1
@onready var skill_2: Node2D = $hero_state_machine/skill_2
@onready var skill_3: Node2D = $hero_state_machine/skill_3
@onready var buff_icon: TextureRect = $buff_icon

var hero_name: String
var hero_grid_index: Vector2:
	get:
		for hero in Current.all_hero_array:
			if hero_name == hero.hero_name:
				return Tools.game_manager.position_to_grid_index(position)
		return Vector2.ZERO
## 英雄移动力
var hero_movement: int

## 动画帧音效注册表:完整动画名 → {帧下标: 音效键}
## 帧下标是几何事实,只要帧序不变即与触发时刻无关;新英雄只需补表项,处理函数零改动
const FRAME_SFX := {
	"soldier_skill_1": {2: "attack"},
	"soldier_skill_2": {3: "attack"},
}

func _ready() -> void:
	animated_sprite_2d.play(hero_name + "_idle")
	skill_1.show_skill_range.connect(_on_show_skill_range)
	skill_1.hide_skill_range.connect(_on_hide_skill_range)
	skill_1.skill_attack.connect(_on_skill_attack)
	skill_2.show_skill_range.connect(_on_show_skill_range)
	skill_2.hide_skill_range.connect(_on_hide_skill_range)
	skill_2.skill_attack.connect(_on_skill_attack)
	skill_3.show_skill_range.connect(_on_show_skill_range)
	skill_3.hide_skill_range.connect(_on_hide_skill_range)
	skill_3.skill_attack.connect(_on_skill_attack)
	skill_3.show_move_range.connect(_on_move_show_move_range)
	skill_3.hide_move_range.connect(_on_move_hide_move_range)
	skill_3.hero_move.connect(_on_move_hero_move)

func _on_area_2d_mouse_entered() -> void:
	#Current.hero = self
	if hero_state_machine.state == hero_state_machine.get_node("idle"):
		animated_sprite_2d.material.set_shader_parameter("is_high_light", true)

func _on_area_2d_mouse_exited() -> void:
	animated_sprite_2d.material.set_shader_parameter("is_high_light", false)

func _on_move_show_move_range() -> void:
	emit_signal("hero_cmd", "show_move_range", null)

func _on_move_hide_move_range() -> void:
	Current.movable_grid_index_array = []
	emit_signal("hero_cmd", "hide_move_range", null)

func _on_move_hero_move(event: InputEvent) -> void:
	emit_signal("hero_cmd", "hero_move", event)

func _on_show_skill_range() -> void:
	emit_signal("hero_cmd", "show_skill_range", null)

func _on_hide_skill_range() -> void:
	emit_signal("hero_cmd", "hide_skill_range", null)

func _on_skill_attack():
	emit_signal("hero_cmd", "skill_attack", null)

func _on_animated_sprite_2d_animation_finished() -> void:
	Current.attack_animation_finished = 1
	#self.hero_state_machine.transition_to("end")

## 帧事件音效:动画名未在表中注册(idle/move/dice等常驻动画)静默返回;命中配置帧播对应音效
func _on_animated_sprite_2d_frame_changed() -> void:
	var frame_sfx: Variant = FRAME_SFX.get(animated_sprite_2d.animation)
	if frame_sfx == null:
		return
	var sfx_key: Variant = frame_sfx.get(animated_sprite_2d.frame)
	if sfx_key == null:
		return
	AudioManager.play_sfx(sfx_key)
