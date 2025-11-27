extends Node2D

@onready var game_manager: Node2D = $"/root/game_manager"

var pre_attack_buff_once: Array
var pre_attack_buff_stage: Array
var pre_attack_buff_always: Array
var post_attack_buff_once: Array
var post_attack_buff_stage: Array
var post_attack_buff_always: Array
var pre_enemy_turn_buff_once: Array
var pre_enemy_turn_buff_stage: Array
var pre_enemy_turn_buff_always: Array
var pre_hero_turn_buff_once: Array
var pre_hero_turn_buff_stage: Array
var pre_hero_turn_buff_always: Array
var post_hero_move_buff_once: Array
var post_hero_move_buff_stage: Array
var post_hero_move_buff_always: Array

func _ready() -> void:
	EventBus.subscribe("clear_stage_buff", clear_stage_buff)
	EventBus.subscribe("do_pre_attack_buff", do_pre_attack_buff)
	EventBus.subscribe("do_post_attack_buff", do_post_attack_buff)
	EventBus.subscribe("do_pre_enemy_turn_buff", do_pre_enemy_turn_buff)
	EventBus.subscribe("do_pre_hero_turn_buff", do_pre_hero_turn_buff)
	EventBus.subscribe("do_post_hero_move_buff", do_post_hero_move_buff)

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
	for buff in pre_enemy_turn_buff_stage:
		buff.clear_buff()
	for buff in pre_hero_turn_buff_stage:
		buff.clear_buff()
	for buff in post_hero_move_buff_stage:
		buff.clear_buff()
	pre_attack_buff_stage.clear()
	post_attack_buff_stage.clear()
	pre_enemy_turn_buff_stage.clear()
	pre_hero_turn_buff_stage.clear()
	post_hero_move_buff_stage.clear()

## 攻击前
#func set_pre_attack_buff(buff: Object, _type: buff_type):
	#pass

func do_pre_attack_buff():
	pass

## 攻击后
func set_post_attack_buff(buff: Object, type: buff_type):
	buff.set_buff()
	match type:
		buff_type.ONCE:
			post_attack_buff_once.append(buff)
		buff_type.STAGE:
			post_attack_buff_stage.append(buff)
		buff_type.ALWAYS:
			post_attack_buff_always.append(buff)

func do_post_attack_buff():
	for buff in post_attack_buff_once:
		buff.process_buff()
		buff.clear_buff()
	post_attack_buff_once = []
	for buff in post_attack_buff_stage:
		buff.process_buff()
	for buff in post_attack_buff_always:
		buff.process_buff()

## 敌人回合前
func set_pre_enemy_turn_buff(buff: Object, type: buff_type):
	buff.set_buff()
	match type:
		buff_type.ONCE:
			pre_enemy_turn_buff_once.append(buff)
		buff_type.STAGE:
			pre_enemy_turn_buff_stage.append(buff)
		buff_type.ALWAYS:
			pre_enemy_turn_buff_always.append(buff)
	
func do_pre_enemy_turn_buff():
	for buff in pre_enemy_turn_buff_once:
		buff.process_buff()
		buff.clear_buff()
	pre_enemy_turn_buff_once = []
	for buff in pre_enemy_turn_buff_stage:
		buff.process_buff()
	for buff in pre_enemy_turn_buff_always:
		buff.process_buff()

## 玩家回合前
func set_pre_hero_turn_buff(buff: Object, type: buff_type):
	buff.set_buff()
	match type:
		buff_type.ONCE:
			pre_hero_turn_buff_once.append(buff)
		buff_type.STAGE:
			pre_hero_turn_buff_stage.append(buff)
		buff_type.ALWAYS:
			pre_hero_turn_buff_always.append(buff)
	
func do_pre_hero_turn_buff():
	for buff in pre_hero_turn_buff_once:
		buff.process_buff()
		buff.clear_buff()
	pre_hero_turn_buff_once = []
	for buff in pre_hero_turn_buff_stage:
		buff.process_buff()
	for buff in pre_hero_turn_buff_always:
		buff.process_buff()

## 玩家移动后
func set_post_hero_move_buff(buff: Object, type: buff_type):
	buff.set_buff()
	match type:
		buff_type.ONCE:
			post_hero_move_buff_once.append(buff)
		buff_type.STAGE:
			post_hero_move_buff_stage.append(buff)
		buff_type.ALWAYS:
			post_hero_move_buff_always.append(buff)

func do_post_hero_move_buff():
	for buff in post_hero_move_buff_once:
		buff.process_buff()
		buff.clear_buff()
	post_hero_move_buff_once = []
	for buff in post_hero_move_buff_stage:
		buff.process_buff()
	for buff in post_hero_move_buff_always:
		buff.process_buff()
