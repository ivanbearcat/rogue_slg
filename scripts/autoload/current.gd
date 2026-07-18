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
var _is_moved: bool = false
var is_moved: bool:
	set(v):
		_is_moved = v
		_update_undo_move_button_state()
	get:
		return _is_moved
## 是否攻击过
var _is_attacked: bool = false
var is_attacked: bool:
	set(v):
		_is_attacked = v
		_update_undo_move_button_state()
	get:
		return _is_attacked
## 移动前的英雄位置（用于撤回移动）
var pre_move_position: Vector2 = Vector2.ZERO
## 移动前的英雄格子索引（用于撤回移动）
var pre_move_grid_index: Vector2 = Vector2.ZERO
## 移动前的总分（用于buff回滚）
var pre_move_total_score: int = 0
## 本回合已移动格数
var grids_moved_this_turn: int = 0
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
## buff购买价格折扣（税吏等一次性折扣）
var _buff_price_discount: int = 0
var buff_price_discount: int:
	set(v):
		_buff_price_discount = v
		## 折扣变化时刷新buff按钮状态（复用total_coins setter逻辑）
		total_coins = total_coins
	get:
		return _buff_price_discount
## 金币总数
var total_coins: int:
	set(v):
		total_coins = v
		game_manager.total_coins_label.text = str(v)
		## 处理按钮和图标的禁用状态
		game_manager.potion_button.disabled = true
		game_manager.coin_skill_1.disabled = true
		game_manager.coin_skill_2.disabled = true
		game_manager.coin_skill_3.disabled = true
		game_manager.potion_button_label.modulate = Color(1.0, 1.0, 1.0, 0.302)
		game_manager.coin_skill_1_icon.self_modulate = Color(1, 1, 1, 0.3)
		game_manager.coin_skill_2_icon.self_modulate = Color(1, 1, 1, 0.3)
		game_manager.coin_skill_3_icon.self_modulate = Color(1, 1, 1, 0.3)
		## 血瓶按钮：有血瓶且未满血时启用
		if _potion_count > 0 and _player_hp < _max_hp:
			game_manager.potion_button.disabled = false
			game_manager.potion_button_label.modulate = Color(1, 1, 1, 1)
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
		var _discounted_price_1 = maxi(0, game_manager.shop_buff_1.get("buff_price", 0) - _buff_price_discount)
		if game_manager.shop_buff_bought[0] or v < _discounted_price_1:
			game_manager.buff_shop_button_1.disabled = true
			game_manager.buff_shop_button_1.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			game_manager.buff_shop_button_1.disabled = false
			game_manager.buff_shop_button_1.modulate = Color(1, 1, 1, 1)
		var _discounted_price_2 = maxi(0, game_manager.shop_buff_2.get("buff_price", 0) - _buff_price_discount)
		if game_manager.shop_buff_bought[1] or v < _discounted_price_2:
			game_manager.buff_shop_button_2.disabled = true
			game_manager.buff_shop_button_2.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			game_manager.buff_shop_button_2.disabled = false
			game_manager.buff_shop_button_2.modulate = Color(1, 1, 1, 1)
		var _discounted_price_3 = maxi(0, game_manager.shop_buff_3.get("buff_price", 0) - _buff_price_discount)
		if game_manager.shop_buff_bought[2] or v < _discounted_price_3:
			game_manager.buff_shop_button_3.disabled = true
			game_manager.buff_shop_button_3.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			game_manager.buff_shop_button_3.disabled = false
			game_manager.buff_shop_button_3.modulate = Color(1, 1, 1, 1)
		## 商店金币技能购买按钮：已购买或金币不足时禁用
		var _coin_skill_cost = int(game_manager.shop_coin_skill_row.get("coin_skill_shop_cost", 0))
		if game_manager.shop_coin_skill_bought or v < _coin_skill_cost:
			game_manager.shop_coin_skill_button.disabled = true
			game_manager.shop_coin_skill_button.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			game_manager.shop_coin_skill_button.disabled = false
			game_manager.shop_coin_skill_button.modulate = Color(1, 1, 1, 1)

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
		if game_manager.one_score:
			game_manager.one_score.text = str(v)
			EffectManager.big_flow_effect(game_manager.one_score)
	get:
		return _one_score
var _two_score: int = 0
var two_score: int:
	set(v):
		_two_score = v
		if game_manager.two_score:
			game_manager.two_score.text = str(v)
			EffectManager.big_flow_effect(game_manager.two_score)
	get:
		return _two_score
var _three_score: int = 0
var three_score: int:
	set(v):
		_three_score = v
		if game_manager.three_score:
			game_manager.three_score.text = str(v)
			EffectManager.big_flow_effect(game_manager.three_score)
	get:
		return _three_score
var _four_score: int = 0
var four_score: int:
	set(v):
		_four_score = v
		if game_manager.four_score:
			game_manager.four_score.text = str(v)
			EffectManager.big_flow_effect(game_manager.four_score)
	get:
		return _four_score
var _five_score: int = 0
var five_score: int:
	set(v):
		_five_score = v
		if game_manager.five_score:
			game_manager.five_score.text = str(v)
			EffectManager.big_flow_effect(game_manager.five_score)
	get:
		return _five_score
var _six_score: int = 0
var six_score: int:
	set(v):
		_six_score = v
		if game_manager.six_score:
			game_manager.six_score.text = str(v)
			EffectManager.big_flow_effect(game_manager.six_score)
	get:
		return _six_score
## 掉落格子骰子是否在本回合攻击中被消耗（参与骰型计分）
var _drop_slot_consumed_this_turn: bool = false
var drop_slot_consumed_this_turn: bool:
	set(v):
		_drop_slot_consumed_this_turn = v
	get:
		return _drop_slot_consumed_this_turn
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
	if game_manager.drop_slot_panel_frame:
		var drop_label = game_manager.drop_slot_panel_frame.get_node("HBoxContainer/Label")
		var drop_point = game_manager.drop_slot_panel_point
		## "掉落"2字永远显示
		drop_label.text = "掉落"
		drop_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		if _drop_slot_dice == null:
			drop_point.text = "-"
			drop_point.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
		else:
			var color_name_map := {"green": "绿", "red": "红", "blue": "蓝", "yellow": "黄"}
			var color_value_map := {"green": Color(0.3, 0.8, 0.3), "red": Color(0.9, 0.3, 0.3), "blue": Color(0.3, 0.5, 0.9), "yellow": Color(0.9, 0.85, 0.2)}
			## 颜色名+点数合并显示在point位置
			drop_point.text = color_name_map[_drop_slot_dice[0]] + str(_drop_slot_dice[1])
			drop_point.add_theme_color_override("font_color", color_value_map[_drop_slot_dice[0]])
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
var max_power := 2:
	set(v):
		max_power = v
		game_manager.power_label.text = str(power) + "/" + str(v)
## 当前能量
var power: int:
	set(v):
		var _clamped = mini(v, max_power)
		power = _clamped
		game_manager.power_label.text = str(_clamped) + "/" + str(Current.max_power)
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
## 被击杀史莱姆的颜色数组（攻击结算时填充，post_attack buff 读取）
var killed_slime_colors: Array
## 凑成骰型的史莱姆击杀数
var pattern_kill_sum: int
## 击杀过能量史莱姆
var killed_power_slime := false
## 刷新buff无花费的最大次数
var zero_coin_refresh_max_times := 0
## 刷新buff无花费的当前次数
var zero_coin_refresh_times := 0
## 上回合是否攻击过（连击风暴用）
var last_turn_attacked := false
## 连续回合得分>0的回合数（连击风暴/连击狂热用）
var consecutive_score_turns := 0
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
		var _old_hp := _player_hp
		_player_hp = mini(v, max_hp)
		if _player_hp < 0:
			_player_hp = 0
		_update_hp_ui()
		_update_potion_button_state()
		if _player_hp != _old_hp:
			EventBus.event_emit("hp_changed", [_player_hp])
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
		_update_potion_button_state()
	get:
		return _max_hp
## 玩家防御值（初始2，公式: damage = max(0, ceil((slime_count - defense) / 3)))
var player_defense: int = 2

## 得分累计回血：累计值（单关内累计得分）
var _score_heal_accumulated: int = 0
var score_heal_accumulated: int:
	set(v):
		_score_heal_accumulated = maxi(v, 0)
		_update_score_heal_ui()
	get:
		return _score_heal_accumulated
## 得分累计回血：当前阈值
var _score_heal_threshold: int = 20
var score_heal_threshold: int:
	set(v):
		_score_heal_threshold = maxi(v, 1)
		_update_score_heal_ui()
	get:
		return _score_heal_threshold
## 得分累计回血：起步阈值（base=35，全局累计不再有关卡系数）
var score_heal_base_threshold: int = 35
## 得分累计回血：每次回血后阈值涨幅
var score_heal_threshold_increase: int = 15
## 血瓶：当前数量
var _potion_count: int = 1
var potion_count: int:
	set(v):
		_potion_count = clampi(v, 0, potion_max)
		_update_potion_ui()
	get:
		return _potion_count
## 血瓶：存储上限
var _potion_max: int = 3
var potion_max: int:
	set(v):
		_potion_max = maxi(v, 1)
		if _potion_count > _potion_max:
			_potion_count = _potion_max
		_update_potion_ui()
	get:
		return _potion_max
## 铁胃减伤值（0=未激活，1=激活铁胃后每回合伤害-1）
var iron_stomach_reduction: int = 0
## 破釜沉舟本回合得分加成比例（0=未激活，0.35=HP>2时激活+35%）
var scorched_earth_bonus: float = 0.0
## 全局免死：是否拥有免死（绝境霸主授予）
var has_death_immunity: bool = false
## 全局免死：是否已消耗（整个run仅1次）
var death_immunity_used: bool = false
## 史莱姆潮待生成数量（slime_tide buff标记）
var slime_tide_pending: int = 0
## 潮涌呼唤待生成数量（swarm_call buff标记）
var swarm_call_pending: int = 0



## 更新得分回血进度UI
func _update_score_heal_ui():
	if game_manager and game_manager.has_node("round_process_bar/score_heal_progress"):
		var label = game_manager.get_node("round_process_bar/score_heal_progress")
		label.text = "回血: " + str(score_heal_accumulated) + "/" + str(_score_heal_threshold) + "  血瓶: " + str(_potion_count) + "/" + str(_potion_max)

## 更新血瓶数量/上限UI及按钮启用状态
func _update_potion_ui():
	if game_manager and game_manager.has_node("round_process_bar/potion_progress"):
		var label = game_manager.get_node("round_process_bar/potion_progress")
		label.text = "血瓶: " + str(_potion_count) + "/" + str(_potion_max)
	# 同时更新 score_heal_progress 中的血瓶数量，确保血瓶数量与实际同步刷新
	if game_manager and game_manager.has_node("round_process_bar/score_heal_progress"):
		var heal_label = game_manager.get_node("round_process_bar/score_heal_progress")
		heal_label.text = "回血: " + str(score_heal_accumulated) + "/" + str(_score_heal_threshold) + "  血瓶: " + str(_potion_count) + "/" + str(_potion_max)
	_update_potion_button_state()

## 更新血瓶按钮的启用/禁用状态
func _update_potion_button_state():
	if not game_manager:
		return
	if _potion_count > 0 and _player_hp < _max_hp:
		game_manager.potion_button.disabled = false
		game_manager.potion_button_label.modulate = Color(1, 1, 1, 1)
	else:
		game_manager.potion_button.disabled = true
		game_manager.potion_button_label.modulate = Color(1.0, 1.0, 1.0, 0.302)

## 更新撤回移动按钮的启用/禁用状态
func _update_undo_move_button_state():
	if not game_manager:
		return
	if not game_manager.has_node("coin_skill_trun_button/HBoxContainer/undo_move_button"):
		return
	var undo_button = game_manager.get_node("coin_skill_trun_button/HBoxContainer/undo_move_button")
	var undo_label = game_manager.get_node("coin_skill_trun_button/HBoxContainer/undo_move_button/undo_move_button_label") if undo_button else null
	if _is_moved == true and _is_attacked == false and turn == "hero_turn":
		undo_button.disabled = false
		if undo_label:
			undo_label.modulate = Color(1, 1, 1, 1)
	else:
		undo_button.disabled = true
		if undo_label:
			undo_label.modulate = Color(1.0, 1.0, 1.0, 0.302)

## 更新HP心形血条UI
func _update_hp_ui():
	if game_manager and game_manager.has_node("round_process_bar/hp_bar"):
		var hp_bar = game_manager.get_node("round_process_bar/hp_bar")
		if hp_bar.has_method("update_hearts"):
			hp_bar.update_hearts(_player_hp, _max_hp)
