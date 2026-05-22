extends Node
#var tween = create_tween()
## game_manager节点
@onready var game_manager: Node2D = get_node("/root/game_manager")
## 鼠标指向的英雄
var hero: Hero
## 鼠标指向的史莱姆
var slime: Slime
## 鼠标点击英雄
var clicked_hero: Hero
## 选中的格子索引
var grid_index: Vector2
## 鼠标在格子范围里
var within_grid_area := false
## 包含所有英雄字典
var all_hero_dict: Dictionary
## 包含所有英雄的数组:
var all_hero_array: Array:
	get:
		return $"/root/game_manager/heros".get_children()
## 包含所有英雄位置的数组
@onready var all_hero_grid_index_array: Array:
	get:
		var grid_index_array: Array
		for _hero in all_hero_array:
			grid_index_array.append(_hero.hero_grid_index)
		return grid_index_array
## 包含所有史莱姆的字典
var all_enemy_array: Array:
	get:
		return $"/root/game_manager/enemys".get_children()
## 包含所有敌人格子的数组
@onready var all_enemy_grid_index_array: Array:
	get:
		var grid_index_array: Array
		for enemy in all_enemy_array:
			grid_index_array.append(enemy.enemy_grid_index)
		return grid_index_array
## 包含所有敌人位置的数组
@onready var all_enemy_position_array: Array:
	get:
		var position_array: Array
		for enemy in all_enemy_array:
			position_array.append(enemy.position)
		return position_array
## 当前可移动的数组
var movable_grid_index_array: Array
## 当前是移动状态英雄
var move_state_hero: Hero:
	get:
		for _hero in all_hero_array:
			if _hero.hero_state_machine.state.name == "move":
				return _hero
		return null
## Astar计算的移动路径
var id_path: Array
## 敌我回合
var turn: String = "hero_turn"
## 正在移动的史莱姆
var has_move_slime: bool:
	get:
		for _slime in all_enemy_array:
			if _slime.target_position != Vector2.ZERO:
				return true
		return false
## 是否移动过
var is_moved: bool
## 是否攻击过
var is_attacked: bool
## 选中的技能编号
var skill_num: String
## 技能选择范围
var skill_target_range: Array
## 技能伤害范围
var skill_attack_range: Array
## 将要变化的史莱姆列表
var transformable_slime_array: Array
## 目标分数
var target_score: int:
	set(v):
		game_manager.target_score.text = str(v)
	get:
		return int(game_manager.target_score.text)
## 当前总分
var _total_score: int = 0
var total_score: int:
	set(v):
		if v < 0:
			v = 0
		_total_score = v
		game_manager.total_score.text = str(v)
		EffectManager.big_flow_effect(game_manager.total_score)
	get:
		return _total_score
## 单次总分
var once_total_score: int
## 当前关卡
var count_stage := 1:
	set(v):
		count_stage = v
		var stage_icon
		for row in game_manager.stage_info_json_data:
			if row["stage_num"] == Current.count_stage:
				stage_icon = row["stage_type_icon"]
		game_manager.stage_label.text = "关卡 " + Tools.num_to_cnnum[v]
		game_manager.clear_stage_label.text = "关卡 " + Tools.num_to_cnnum[v]
		game_manager.stage_effect_label.text = "关卡 " + Tools.num_to_cnnum[v] + \
		" [img=17]" + stage_icon + "[/img]"
	get:
		return count_stage
## 关卡奖励金币数
var count_add_coins := 0
## 金币总数
var total_coins: int:
	set(v):
		total_coins = v
		game_manager.total_coins_label.text = str(v)
		## 处理按钮和图标的禁用状态
		game_manager.reroll_button.disabled = true
		game_manager.coin_skill_1.disabled = true
		game_manager.coin_skill_2.disabled = true
		game_manager.coin_skill_3.disabled = true
		game_manager.reroll_button_label.modulate = Color(1.0, 1.0, 1.0, 0.302)
		game_manager.coin_skill_1_icon.self_modulate = Color(1, 1, 1, 0.3)
		game_manager.coin_skill_2_icon.self_modulate = Color(1, 1, 1, 0.3)
		game_manager.coin_skill_3_icon.self_modulate = Color(1, 1, 1, 0.3)
		if v > 0:
			game_manager.reroll_button.disabled = false
			game_manager.reroll_button_label.modulate = Color(1, 1, 1, 1)
		## 技能按钮：根据本关是否已使用来判断
		## 技能1：存在且本关未使用时启用
		if coin_skill_array_dict.size() > 0 and coin_skill_used.size() > 0 and coin_skill_used[0] == false:
			game_manager.coin_skill_1.disabled = false
			game_manager.coin_skill_1_icon.self_modulate = Color(1, 1, 1, 1)
		## 技能2：存在且本关未使用时启用
		if coin_skill_array_dict.size() > 1 and coin_skill_used.size() > 1 and coin_skill_used[1] == false:
			game_manager.coin_skill_2.disabled = false
			game_manager.coin_skill_2_icon.self_modulate = Color(1, 1, 1, 1)
		## 技能3：存在且本关未使用时启用
		if coin_skill_array_dict.size() > 2 and coin_skill_used.size() > 2 and coin_skill_used[2] == false:
			game_manager.coin_skill_3.disabled = false
			game_manager.coin_skill_3_icon.self_modulate = Color(1, 1, 1, 1)
		## 商店购买按钮
		if v < game_manager.buff_refresh_cost:
			game_manager.buff_refresh_button.disabled = true
			game_manager.buff_refresh_button.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			game_manager.buff_refresh_button.disabled = false
			game_manager.buff_refresh_button.modulate = Color(1, 1, 1, 1)
		if v < 2 or power == max_power:
			game_manager.power_bottle_button.disabled = true
			game_manager.power_bottle_button.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			game_manager.power_bottle_button.disabled = false
			game_manager.power_bottle_button.modulate = Color(1, 1, 1, 1)
		if v < 1:
			game_manager.exp_bottle_button.disabled = true
			game_manager.exp_bottle_button.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			game_manager.exp_bottle_button.disabled = false
			game_manager.exp_bottle_button.modulate = Color(1, 1, 1, 1)
		## 生命药水按钮：3金币且HP未满时启用
		if v < 3 or _player_hp >= _max_hp:
			game_manager.hp_bottle_button.disabled = true
			game_manager.hp_bottle_button.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			game_manager.hp_bottle_button.disabled = false
			game_manager.hp_bottle_button.modulate = Color(1, 1, 1, 1)
		if v < game_manager.shop_buff_1.get("buff_price", 0):
			game_manager.buff_shop_button_1.disabled = true
			game_manager.buff_shop_button_1.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			game_manager.buff_shop_button_1.disabled = false
			game_manager.buff_shop_button_1.modulate = Color(1, 1, 1, 1)
		if v < game_manager.shop_buff_2.get("buff_price", 0):
			game_manager.buff_shop_button_2.disabled = true
			game_manager.buff_shop_button_2.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			game_manager.buff_shop_button_2.disabled = false
			game_manager.buff_shop_button_2.modulate = Color(1, 1, 1, 1)
		if v < game_manager.shop_buff_3.get("buff_price", 0):
			game_manager.buff_shop_button_3.disabled = true
			game_manager.buff_shop_button_3.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			game_manager.buff_shop_button_3.disabled = false
			game_manager.buff_shop_button_3.modulate = Color(1, 1, 1, 1)

## 刷新金币技能按钮的启用/禁用状态（根据coin_skill_used数组）
func refresh_coin_skill_buttons():
	## 先禁用所有技能按钮和图标
	game_manager.coin_skill_1.disabled = true
	game_manager.coin_skill_2.disabled = true
	game_manager.coin_skill_3.disabled = true
	game_manager.coin_skill_1_icon.self_modulate = Color(1, 1, 1, 0.3)
	game_manager.coin_skill_2_icon.self_modulate = Color(1, 1, 1, 0.3)
	game_manager.coin_skill_3_icon.self_modulate = Color(1, 1, 1, 0.3)
	## 技能1：存在且本关未使用时启用
	if coin_skill_array_dict.size() > 0 and coin_skill_used.size() > 0 and coin_skill_used[0] == false:
		game_manager.coin_skill_1.disabled = false
		game_manager.coin_skill_1_icon.self_modulate = Color(1, 1, 1, 1)
	## 技能2：存在且本关未使用时启用
	if coin_skill_array_dict.size() > 1 and coin_skill_used.size() > 1 and coin_skill_used[1] == false:
		game_manager.coin_skill_2.disabled = false
		game_manager.coin_skill_2_icon.self_modulate = Color(1, 1, 1, 1)
	## 技能3：存在且本关未使用时启用
	if coin_skill_array_dict.size() > 2 and coin_skill_used.size() > 2 and coin_skill_used[2] == false:
		game_manager.coin_skill_3.disabled = false
		game_manager.coin_skill_3_icon.self_modulate = Color(1, 1, 1, 1)

## 回合计数
var count_round := 0:
	set(v):
		count_round = v
		if v == 0 or v == 1:
			game_manager.ship.position = Vector2(4, 2)
		if v > 1 and v < 11:
			#game_manager.ship.position = Vector2(4, 2) + ((v - 1) * Vector2(7, 0))
			var position = Vector2(4, 2) + ((v - 1) * Vector2(7, 0))
			Current.public_lock_array.append("turn_ship_animation")
			var tween = create_tween()
			tween.tween_property(game_manager.ship, "position:x", position.x, 0.4)
			tween.tween_property(game_manager.ship, "position:y", position.y, 0.4)
			await tween.finished
			Current.public_lock_array.erase("turn_ship_animation")
		## 回合数>10时不触发船动画，但继续显示回合数
		game_manager.turn_label.text = "回合: " + str(v)
	get:
		#return int(game_manager.turn_label.text)
		return count_round
## 最高骰子数
var highest_dice_num := 1
## 骰型板基础分数
var _one_score: int = 0
var one_score: int:
	set(v):
		_one_score = v
		game_manager.one_score.text = str(v)
		EffectManager.big_flow_effect(game_manager.one_score)
	get:
		return _one_score
var _two_score: int = 0
var two_score: int:
	set(v):
		_two_score = v
		game_manager.two_score.text = str(v)
		EffectManager.big_flow_effect(game_manager.two_score)
	get:
		return _two_score
var _three_score: int = 0
var three_score: int:
	set(v):
		_three_score = v
		game_manager.three_score.text = str(v)
		EffectManager.big_flow_effect(game_manager.three_score)
	get:
		return _three_score
var _four_score: int = 0
var four_score: int:
	set(v):
		_four_score = v
		game_manager.four_score.text = str(v)
		EffectManager.big_flow_effect(game_manager.four_score)
	get:
		return _four_score
var _five_score: int = 0
var five_score: int:
	set(v):
		_five_score = v
		game_manager.five_score.text = str(v)
		EffectManager.big_flow_effect(game_manager.five_score)
	get:
		return _five_score
var _six_score: int = 0
var six_score: int:
	set(v):
		_six_score = v
		game_manager.six_score.text = str(v)
		EffectManager.big_flow_effect(game_manager.six_score)
	get:
		return _six_score
## 掉落格子骰子 [color, point] 或 null
var _drop_slot_dice = null
var drop_slot_dice:
	set(v):
		_drop_slot_dice = v
		_update_drop_slot_ui()
	get:
		return _drop_slot_dice

## 更新掉落格子UI显示
func _update_drop_slot_ui():
	if game_manager.has_node("stage_score/drop_slot_container"):
		var drop_slot_container = game_manager.get_node("stage_score/drop_slot_container")
		var drop_slot_color_label = drop_slot_container.get_node("drop_slot_color_label")
		var drop_slot_point_label = drop_slot_container.get_node("drop_slot_point_label")
		if _drop_slot_dice == null:
			drop_slot_color_label.text = ""
			drop_slot_color_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
			drop_slot_point_label.text = ""
		else:
			var color_name_map := {"green": "绿", "red": "红", "blue": "蓝", "yellow": "黄"}
			var color_value_map := {"green": Color(0.3, 0.8, 0.3), "red": Color(0.9, 0.3, 0.3), "blue": Color(0.3, 0.5, 0.9), "yellow": Color(0.9, 0.85, 0.2)}
			drop_slot_color_label.text = color_name_map[_drop_slot_dice[0]]
			drop_slot_color_label.add_theme_color_override("font_color", color_value_map[_drop_slot_dice[0]])
			drop_slot_point_label.text = str(_drop_slot_dice[1])
var _duizi_percent: int = 0
var duizi_percent: int:
	set(v):
		_duizi_percent = v
		game_manager.duizi_percent.text = str(v) + "%"
		EffectManager.big_flow_effect(game_manager.duizi_percent)
	get:
		return _duizi_percent
var _shunzi_percent: int = 0
var shunzi_percent: int:
	set(v):
		_shunzi_percent = v
		game_manager.shunzi_percent.text = str(v) + "%"
		EffectManager.big_flow_effect(game_manager.shunzi_percent)
	get:
		return _shunzi_percent
var _tongse_percent: int = 0
var tongse_percent: int:
	set(v):
		_tongse_percent = v
		game_manager.tongse_percent.text = str(v) + "%"
		EffectManager.big_flow_effect(game_manager.tongse_percent)
	get:
		return _tongse_percent
var _tongdui_percent: int = 0
var tongdui_percent: int:
	set(v):
		_tongdui_percent = v
		game_manager.tongdui_percent.text = str(v) + "%"
		EffectManager.big_flow_effect(game_manager.tongdui_percent)
	get:
		return _tongdui_percent
var _tongshun_percent: int = 0
var tongshun_percent: int:
	set(v):
		_tongshun_percent = v
		game_manager.tongshun_percent.text = str(v) + "%"
		EffectManager.big_flow_effect(game_manager.tongshun_percent)
	get:
		return _tongshun_percent
## 实时基础和倍率
var _base_score: int = 0
var base_score: int:
	set(v):
		_base_score = v
		if v != 0:
			game_manager.base_score.text = str(v)
		else:
			game_manager.base_score.text = ''
	get:
		return _base_score
var _percent_score: float = 0.0
var percent_score: float:
	set(v):
		_percent_score = v
		if v != 0:
			game_manager.percent_score.text = str(int(v)) + "%"
		else:
			game_manager.percent_score.text = ''
	get:
		return _percent_score
## 单次骰型的分数
var dice_type_point: int
## 攻击动画是否完成
var attack_animation_finished = 1
## 史莱姆生成数量
var slime_create_num := 3
## 能量史莱姆数组
var power_slime_array: Array:
	get:
		var _power_slime_array = []
		for _slime in all_enemy_array:
			if _slime.animated_sprite_2d.material.get_shader_parameter("is_high_light") == true and \
			_slime.animated_sprite_2d.material.get_shader_parameter("outline_color") == Color(0.0, 18.892, 18.892):
				_power_slime_array.append(_slime)
		return _power_slime_array
## 能量史莱姆总数
var power_slime_num := 1
## 金币史莱姆数组
var coin_slime_array: Array:
	get:
		var _coin_slime_array = []
		for _slime in all_enemy_array:
			if _slime.animated_sprite_2d.material.get_shader_parameter("is_high_light") == true and \
			_slime.animated_sprite_2d.material.get_shader_parameter("outline_color") == Color(18.892, 18.892, 0.0):
				_coin_slime_array.append(_slime)
		return _coin_slime_array
## 金币史莱姆总数
var coin_slime_num := 1
## 普通史莱姆（非能量和金币）
var normal_slime_array: Array:
	get:
		var _normal_slime_array = []
		for _slime in all_enemy_array:
			if _slime.animated_sprite_2d.material.get_shader_parameter("is_high_light") == false:
				_normal_slime_array.append(_slime)
		return _normal_slime_array
## 鼠标状态
var mouse_status := 'default'
## 重掷次数
#var reroll_times: int:
	#set(v):
		#game_manager.reroll_label.text = "重掷: " + str(v)
	#get:
		#return int(game_manager.reroll_label.text)
## 当前等级
var level: int:
	set(v):
		level = v
		game_manager.level_label.text = "Lv." + str(v)
## 当前经验
var hero_exp := 0
## 升级需要的经验
var require_exp := 3
## 持续动作锁
var action_lock := false
## 最大能量
var max_power := 2
## 当前能量
var power: int:
	set(v):
		power = v
		game_manager.power_label.text = str(v) + "/" + str(Current.max_power)
		if v == max_power:
			game_manager.power_bottle_button.disabled = true
			game_manager.power_bottle_button.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			game_manager.power_bottle_button.disabled = false
			game_manager.power_bottle_button.modulate = Color(1, 1, 1, 1)
## 能量技能
var power_skill := 0
## 存在红框
var has_attack_grid := false
## 金币技能
var coin_skill_array_dict: Array
## 金币技能本关是否已使用（索引对应coin_skill_array_dict，true=已使用）
var coin_skill_used: Array = []
## 所有格子
var all_grids_array: Array
## 公共锁
var public_lock_array := []
## 含有buff的锁
var buff_lock_array: Array:
	get:
		var _buff_lock_array := []
		for lock_name in public_lock_array:
			if "buff" in lock_name:
				_buff_lock_array.append(lock_name)
		return _buff_lock_array
## 上回合生成史莱姆
var last_slime_create_array: Array
## 史莱姆死亡数组
var slime_die_sum: int
## 击杀过能量史莱姆
var killed_power_slime := false
## 击杀过金币史莱姆
var killed_coin_slime := false
## 刷新buff无花费的最大次数
var zero_coin_refresh_max_times := 0
## 刷新buff无花费的当前次数
var zero_coin_refresh_times := 0
## 上回合是否攻击过（连击风暴用）
var last_turn_attacked := false
## 本次攻击骰型数量（骰型大师用）
var dice_type_count := 0
## 本次掉落骰子数量（掉落奖励/掉落惩罚用）
var dropped_dice_count := 0
## 本次攻击参与计分的骰子信息（击杀特化/颜色对应骰型用）
var scored_dice_info: Array = []
## 本次攻击触发的骰型名称数组（击杀倍率用）
var active_dice_types: Array = []
## 骰型倍率表
var dice_multiplier_dict: Dictionary
## 精英史莱姆数组
var elite_slime_array: Array:
	get:
		var _elite_slime_array = []
		for _slime in all_enemy_array:
			if is_instance_valid(_slime) and _slime.is_elite:
				_elite_slime_array.append(_slime)
		return _elite_slime_array
## BOSS史莱姆数组
var boss_slime_array: Array:
	get:
		var _boss_slime_array = []
		for _slime in all_enemy_array:
			if is_instance_valid(_slime) and _slime.is_boss:
				_boss_slime_array.append(_slime)
		return _boss_slime_array
## 精英门槛配置
var ELITE_GATE_TYPES: Array = ["duizi", "shunzi", "tongse", "tongdui", "tongshun"]
var ELITE_GATE_COUNTS: Dictionary = {
	"duizi": 3,
	"shunzi": 3,
	"tongse": 3,
	"tongdui": 2,
	"tongshun": 2
}
## 门槛类型对应的描述
var gate_type_descriptions: Dictionary = {
	"duizi": "对子：相同点数的骰子",
	"shunzi": "顺子：连续点数的骰子",
	"tongse": "同色：相同颜色的骰子",
	"tongdui": "同对：同色+同点数的骰子",
	"tongshun": "同顺：同色+连续点数的骰子"
}
## BOSS门槛配置
var BOSS_GATE_TYPES: Array = ["tongdui", "tongshun"]
var BOSS_GATE_COUNT: int = 3
## 玩家HP
var _player_hp: int = 5
var player_hp: int:
	set(v):
		_player_hp = mini(v, max_hp)
		if _player_hp < 0:
			_player_hp = 0
		_update_hp_ui()
	get:
		return _player_hp
## HP上限
var _max_hp: int = 5
var max_hp: int:
	set(v):
		_max_hp = v
		if _player_hp > _max_hp:
			_player_hp = _max_hp
		_update_hp_ui()
	get:
		return _max_hp
## 本关是否已生成生命史莱姆
var life_slime_spawned_this_stage: bool = false
## HP扣血跳过标记（turn_plus_one_buff第一回合不扣血用）
var skip_hp_damage_this_turn: bool = false
## 玩家防御值（初始2，公式: damage = max(0, ceil((slime_count - defense) / 3)))
var player_defense: int = 2

## 更新HP心形血条UI
func _update_hp_ui():
	if game_manager and game_manager.has_node("round_process_bar/hp_bar"):
		var hp_bar = game_manager.get_node("round_process_bar/hp_bar")
		if hp_bar.has_method("update_hearts"):
			hp_bar.update_hearts(_player_hp, _max_hp)
