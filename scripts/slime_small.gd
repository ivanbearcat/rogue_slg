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
## 威胁类型: "corrosion", "curse", "plague", "parasite", "swell" 或空字符串
var threat_type: String = ""
## 是否为生命史莱姆
var is_life_slime: bool = false
## 出生回合不触发效果，下一回合开始才生效
var threat_skip_first_turn: bool = false
## 诅咒倒计时（仅诅咒史莱姆使用）
var curse_countdown: int = 0
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
## 威胁史莱姆tooltip标签
var _threat_tooltip_label: Label = null

func _create_threat_tooltip():
	if threat_type == "" or _threat_tooltip_label != null:
		return
	_threat_tooltip_label = Label.new()
	_threat_tooltip_label.name = "ThreatTooltip"
	var desc = Current.threat_type_descriptions.get(threat_type, "")
	## 诅咒类型显示倒计时
	if threat_type == "curse" and curse_countdown > 0:
		desc += " (倒计时: " + str(curse_countdown) + ")"
	_threat_tooltip_label.text = desc
	_threat_tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	## 使用威胁类型对应的颜色
	var threat_color = Current.threat_type_colors.get(threat_type, Color.WHITE)
	_threat_tooltip_label.add_theme_color_override("font_color", threat_color)
	_threat_tooltip_label.add_theme_font_size_override("font_size", 14)
	## 背景
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	stylebox.set_border_width_all(2)
	stylebox.border_color = threat_color
	stylebox.set_content_margin_all(4)
	_threat_tooltip_label.add_theme_stylebox_override("normal", stylebox)
	_threat_tooltip_label.position = Vector2(-60, -35)
	_threat_tooltip_label.visible = false
	_threat_tooltip_label.z_index = 100
	add_child(_threat_tooltip_label)

func _update_threat_tooltip():
	if _threat_tooltip_label == null or threat_type == "":
		return
	var desc = Current.threat_type_descriptions.get(threat_type, "")
	if threat_type == "curse" and curse_countdown > 0:
		desc += " (倒计时: " + str(curse_countdown) + ")"
	_threat_tooltip_label.text = desc

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
	## 威胁史莱姆击杀反馈
	if threat_type != "":
		var float_number = EffectManager.float_number_effect(1, "green")
		if float_number:
			float_number.get_node("Label").text = "威胁消除!"
			Current.hero.add_child(float_number)
		print("[threat-slime] 威胁史莱姆被击杀: %s" % threat_type)
	self.queue_free()

func _on_area_2d_mouse_entered() -> void:
	Current.slime = self
	## 显示威胁史莱姆tooltip
	if threat_type != "":
		_create_threat_tooltip()
		if _threat_tooltip_label:
			_threat_tooltip_label.visible = true

func _on_area_2d_mouse_exited() -> void:
	Current.slime = null
	## 隐藏威胁史莱姆tooltip
	if _threat_tooltip_label:
		_threat_tooltip_label.visible = false

func _on_dice_animation_finished() -> void:
	print(dice.frame)
