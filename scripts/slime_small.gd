extends Node2D
class_name Slime

@onready var warning: Sprite2D = $Area2D/warning
@onready var dice: AnimatedSprite2D = $Area2D/dice
@onready var animated_sprite_2d: AnimatedSprite2D = $Area2D/AnimatedSprite2D
@onready var game_manager: Node2D = $"/root/game_manager"

var enemy_grid_index: Vector2:
	get:
		return Tools.position_to_grid_index(position)
var enemy_hp: int = 1
var target_position: Vector2
var enemy_type: int = 1
## 是否为精英史莱姆
var is_elite: bool = false
## 是否为BOSS史莱姆
var is_boss: bool = false
## 骰型门槛类型: "duizi", "shunzi", "tongse", "tongdui", "tongshun"
var gate_type: String = ""
## 骰型门槛所需骰数
var gate_count: int = 0
## 是否为生命史莱姆
var is_life_slime: bool = false
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

var dice_to_frame_dice: Dictionary = {
	1: 2,
	2: 0,
	3: 10,
	4: 6,
	5: 8,
	6: 4
}
## 精英/BOSS史莱姆tooltip标签
var _elite_tooltip_label: Label = null

func _create_elite_tooltip():
	if not is_elite and not is_boss:
		return
	if _elite_tooltip_label != null:
		return
	_elite_tooltip_label = Label.new()
	_elite_tooltip_label.name = "EliteTooltip"
	## Build tooltip text
	var desc = ""
	if is_elite:
		desc = "精英史莱姆\n"
	elif is_boss:
		desc = "BOSS史莱姆\n"
	## Gate type description
	var gate_desc = Current.gate_type_descriptions.get(gate_type, "")
	desc += gate_desc + " (需要" + str(gate_count) + "个)\n"
	## Dice info
	desc += "骰子: " + str(dice_point) + "点"
	_elite_tooltip_label.text = desc
	_elite_tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	## Color: red for elite, purple for boss
	var outline_color = Color(18.892, 0, 0) if is_elite else Color(18.892, 0, 18.892)
	_elite_tooltip_label.add_theme_color_override("font_color", outline_color)
	_elite_tooltip_label.add_theme_font_size_override("font_size", 14)
	## Background
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	stylebox.set_border_width_all(2)
	stylebox.border_color = outline_color
	stylebox.set_content_margin_all(4)
	_elite_tooltip_label.add_theme_stylebox_override("normal", stylebox)
	_elite_tooltip_label.position = Vector2(-80, -40)
	_elite_tooltip_label.visible = false
	_elite_tooltip_label.z_index = 100
	add_child(_elite_tooltip_label)

func _process(delta: float) -> void:
	if target_position:
		if self.position == target_position:
			target_position = Vector2.ZERO
			game_manager.reset_astar_solid()
		else:
			self.position = self.position.move_toward(target_position, 15 * delta)

func _on_animated_sprite_2d_animation_finished() -> void:
	game_manager.add_exp(1)
	if self in Current.transformable_slime_array:
		Current.transformable_slime_array.erase(self)
	## 增加能量
	if self.animated_sprite_2d.material.get_shader_parameter("is_high_light") and \
	self.animated_sprite_2d.material.get_shader_parameter("outline_color") == Color(0.0, 18.892, 18.892):
		Current.killed_power_slime = true
		## 等待攻击动作完成后再加能量
		while "skill_attack" in Current.public_lock_array:
			await Tools.time_sleep(0.1)
		Current.power += 1
	## 增加金币
	if self.animated_sprite_2d.material.get_shader_parameter("is_high_light") and \
	self.animated_sprite_2d.material.get_shader_parameter("outline_color") == Color(18.892, 18.892, 0.0):
		Current.killed_coin_slime = true
		Current.total_coins += 1
	## 生命史莱姆击杀回血
	if is_life_slime:
		Current.player_hp += 3
		var float_number = EffectManager.float_number_effect(3, "green")
		if float_number:
			float_number.get_node("Label").text = "+3HP!"
			Current.hero.add_child(float_number)
	## 精英/BOSS史莱姆击杀反馈
	if is_elite or is_boss:
		var float_number = EffectManager.float_number_effect(1, "green")
		if float_number:
			if is_boss:
				float_number.get_node("Label").text = "BOSS击杀!"
			else:
				float_number.get_node("Label").text = "精英击杀!"
			Current.hero.add_child(float_number)
		print("[elite-slime] %s被击杀: gate=%s count=%d" % ["BOSS" if is_boss else "精英", gate_type, gate_count])
	self.queue_free()

func _on_area_2d_mouse_entered() -> void:
	Current.slime = self
	## 显示精英/BOSS史莱姆tooltip
	if is_elite or is_boss:
		_create_elite_tooltip()
		if _elite_tooltip_label:
			_elite_tooltip_label.visible = true

func _on_area_2d_mouse_exited() -> void:
	Current.slime = null
	## 隐藏精英/BOSS史莱姆tooltip
	if _elite_tooltip_label:
		_elite_tooltip_label.visible = false

func _on_dice_animation_finished() -> void:
	print(dice.frame)
