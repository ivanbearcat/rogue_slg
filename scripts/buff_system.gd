extends Node2D

@onready var game_manager: Node2D = $"/root/game_manager"

var before_attack_buff_once: Array
var before_attack_buff: Array
var after_attack_buff_once: Array
var after_attack_buff: Array

func _ready() -> void:
	EventBus.subscribe("do_after_attack_buff_once", do_after_attack_buff_once)
	

func set_after_attack_buff_once(buff: GDScript):
	buff.set_buff()
	after_attack_buff_once.append(buff)

func do_after_attack_buff_once():
	for buff in after_attack_buff_once:
		buff.process_buff()
		buff.drop_buff()
	after_attack_buff_once = []
	
	
## 得分翻倍
func set_double_score():
	Current.hero.buff_icon.texture = load("res://images/coin_skill_icon/double_score.png")
	
func double_score():
	Current.public_lock_array.append("double_score")
	var float_number_instantiate = EffectManager.float_number_effect(Current.once_total_score)
	Current.hero.add_child(float_number_instantiate)
	Current.total_score += Current.once_total_score
	#Current.set_total_score_with_effect(Current.total_score + Current.once_total_score)
	Current.public_lock_array.erase("double_score")
	
func drop_double_score():
	Current.hero.buff_icon.texture = null
