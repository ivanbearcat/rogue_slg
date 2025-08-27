extends Node2D
class_name Slime

@onready var warning: Sprite2D = $Area2D/warning
@onready var dice: AnimatedSprite2D = $Area2D/dice
@onready var animated_sprite_2d: AnimatedSprite2D = $Area2D/AnimatedSprite2D
@onready var game_manager: Node2D = $"/root/game_manager"

var enemy_grid_index: Vector2i
var enemy_hp: int = 1
var target_position: Vector2
var enemy_type: int = 1
var dice_real_point: Dictionary = {
	0: 2,
	2: 1,
	4: 6,
	6: 4,
	8: 5,
	10: 3
}
var dice_point: int:
	get:
		return dice_real_point[self.dice.frame]


func _process(delta: float) -> void:
	if target_position:
		if self.position == target_position:
			target_position = Vector2.ZERO
		else:
			self.position = self.position.move_toward(target_position, 15 * delta)
			
			
func _on_animated_sprite_2d_animation_finished() -> void:
	game_manager.add_exp(1)
	if self in Current.transformable_slime_array:
		Current.transformable_slime_array.erase(self)
	if self.animated_sprite_2d.material.get_shader_parameter("is_high_light"):
		## 增加能量
		if Current.power < Current.max_power:
			Current.power += 1
	self.queue_free()


func _on_area_2d_mouse_entered() -> void:
	if Current.mouse_status != 'default':
		Current.slime = self


func _on_area_2d_mouse_exited() -> void:
	Current.slime = null
