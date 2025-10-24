extends Node2D

@onready var game_manager: Node2D = $"/root/game_manager"

var pre_attack_buff_once: Array
var pre_attack_buff_stage: Array
var pre_attack_buff_always: Array
var post_attack_buff_once: Array
var post_attack_buff_stage: Array
var post_attack_buff_always: Array
var pre_turn_buff_once: Array
var pre_turn_buff_stage: Array
var pre_turn_buff_always: Array

func _ready() -> void:
	EventBus.subscribe("clear_stage_buff", clear_stage_buff)
	EventBus.subscribe("do_pre_attack_buff", do_pre_attack_buff)
	EventBus.subscribe("do_post_attack_buff", do_post_attack_buff)
	EventBus.subscribe("do_pre_turn_buff", do_pre_turn_buff)

enum buff_type{
	ONCE,
	STAGE,
	ALWAYS
}
	
## 清理关卡buff
func clear_stage_buff():
	for buff in pre_attack_buff_stage:
		buff.clear_buff()
	for buff in post_attack_buff_stage:
		buff.clear_buff()
	for buff in pre_turn_buff_stage:
		buff.clear_buff()

## 攻击前
func set_pre_attack_buff(buff: Object, _type: buff_type):
	pass

func do_pre_attack_buff():
	pass

## 攻击后
func set_post_attack_buff(buff: Object, type: buff_type):
	buff.set_buff()
	match type:
		buff_type.ONCE:
			post_attack_buff_once.append(buff)
		buff_type.STAGE:
			pass
		buff_type.ALWAYS:
			pass

func do_post_attack_buff():
	for buff in post_attack_buff_once:
		buff.process_buff()
		buff.clear_buff()
	post_attack_buff_once = []
	for buff in post_attack_buff_stage:
		buff.process_buff()
	for buff in post_attack_buff_always:
		buff.process_buff()

## 回合前
func set_pre_turn_buff(buff: Object, type: buff_type):
	buff.set_buff()
	match type:
		buff_type.ONCE:
			post_attack_buff_once.append(buff)
		buff_type.STAGE:
			post_attack_buff_stage.append(buff)
		buff_type.ALWAYS:
			pass
	
func do_pre_turn_buff():
	for buff in pre_turn_buff_once:
		buff.process_buff()
		buff.clear_buff()
	pre_turn_buff_once = []
	for buff in pre_turn_buff_stage:
		buff.process_buff()
	for buff in pre_turn_buff_always:
		buff.process_buff()
	
