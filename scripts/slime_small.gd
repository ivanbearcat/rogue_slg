extends Node2D

@onready var warning: Sprite2D = $Area2D/warning
@onready var dice: AnimatedSprite2D = $Area2D/dice
@onready var animated_sprite_2d: AnimatedSprite2D = $Area2D/AnimatedSprite2D

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
	if self in Current.transformable_slime_array:
		Current.transformable_slime_array.erase(self)
	$Area2D.hide()
	Current.total_score += dice_point
	var float_number_instantiate = SceneManager.create_scene("float_number")
	float_number_instantiate.float_num = dice_point
	float_number_instantiate.velocity = Vector2(0, -10)
	self.add_child(float_number_instantiate)
	await Tools.time_sleep(1.0)
	self.queue_free()
