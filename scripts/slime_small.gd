extends Node2D
class_name Slime

@onready var warning: Sprite2D = $Area2D/warning
@onready var dice: AnimatedSprite2D = $Area2D/dice
@onready var animated_sprite_2d: AnimatedSprite2D = $Area2D/AnimatedSprite2D
@onready var selected_marker: Sprite2D = $Area2D/selected_marker
## game_manager引用（跟随 Current 注册状态，场景切换后自动指向新战局）
var game_manager: Node2D:
	get:
		return Current.game_manager

var enemy_grid_index: Vector2:
	get:
		return Tools.position_to_grid_index(position)
var enemy_hp: int = 1
## 移动速度(px/s)
const MOVE_SPEED: float = 25.0
## 当前移动插值Tween(到达时触发到达处理;移动中被重定向时kill旧Tween并从当前位置重启)
var _move_tween: Tween
## 移动目标格:赋值即启动/重启移动Tween(置零仅清空目标,不触发移动)
var target_position: Vector2:
	set(value):
		# Godot 4属性setter不会自动赋值,需显式存回backing字段
		target_position = value
		if value != Vector2.ZERO:
			_start_move_tween(value)
var enemy_type: int = 1
## 是否为精英史莱姆
var is_elite: bool = false
## 是否为BOSS史莱姆
var is_boss: bool = false
## 骰型门槛类型: "duizi", "shunzi", "tongse", "tongdui", "tongshun"
var gate_type: String = ""
## 骰型门槛所需骰数
var gate_count: int = 0
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

func show_selected_marker() -> void:
	animated_sprite_2d.material.set_shader_parameter("is_selected", true)

func hide_selected_marker() -> void:
	animated_sprite_2d.material.set_shader_parameter("is_selected", false)

func _start_move_tween(to: Vector2) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	_move_tween = create_tween()
	## 时长按速度实时计算(移动中改道后速度恒定);下限防止"目标即当前位置"时0时长Tween的边界行为
	var duration := maxf(position.distance_to(to) / MOVE_SPEED, 0.001)
	_move_tween.tween_property(self, "position", to, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_move_tween.finished.connect(_on_move_finished)


func _on_move_finished() -> void:
	target_position = Vector2.ZERO
	game_manager.reset_astar_solid()

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
		Current.power = mini(Current.power + 1, Current.max_power)
	## 精英/BOSS史莱姆击杀反馈
	if is_elite or is_boss:
		var float_number = EffectManager.float_number_effect(1, "green")
		if float_number:
			if is_boss:
				float_number.get_node("Label").text = tr("BOSS击杀!")
			else:
				float_number.get_node("Label").text = tr("精英击杀!")
			Current.hero.add_child(float_number)
		print("[elite-slime] %s被击杀: gate=%s count=%d" % ["BOSS" if is_boss else "精英", gate_type, gate_count])
	self.queue_free()

func _on_dice_animation_finished() -> void:
	print(dice.frame)
