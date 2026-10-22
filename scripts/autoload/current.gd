extends Node
#var tween = create_tween()
## game_manager节点（由 game_manager._ready 自注册，场景切换后随新战局自动刷新）
var game_manager: Node2D

## ⚠️ 存档密钥盐片段 B（三段散落常量之一，完整密钥不出现在任何单一文件；
## 其余片段见 save_manager.gd / buff_system.gd。改动任一片段会使现有存档失效 → 走坏档路径）
const _SAVE_SALT_B := "RG|SALT|B|4e8c21d90f7a3562"
## 英雄选择画面选中的英雄类型（对应 game_manager.hero_property 的键）
var selected_hero: String = "soldier"
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
		return game_manager.get_node("heros").get_children()
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
		return game_manager.get_node("enemys").get_children()
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
## 移动前的全量位置快照（[0]为英雄，其余为史莱姆；用于撤回移动）
var undo_snapshot: Array = []
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
## 本局单次最高得分（每次攻击结算后更新，run 结束前不清零）
var max_once_score: int = 0


## ============================================================
## 新局重置链
## ============================================================

## ⚠️ 成对修改纪律：run 级状态字段的增删必须同步修改本文件下方的
## export_run_state() / apply_run_state()（存档快照导出/灌入），
## 否则新字段不被存档、读档后回退默认值。对面位置：
## SaveManager.capture()（scripts/autoload/save_manager.gd）。
## 注意：run 状态三处（reset/export/apply）+ SaveManager.capture 编排
## 是同一个变量簇的四份清单，review 时逐一核对。

## 战局场景重新入场（再玩一次 → 选人 → 战局）时恢复 boot 默认值。
## 只重置 run 级聚合状态与全局标记；场景节点引用由新战局 _ready 自行装配。
## 调用时机：game_manager._ready 开头（game_manager 引用已刷新，setter 安全）。
## 注意：优先直接写 _ 前缀内部变量，避免 setter 触发旧 HUD/演出副作用。
func reset_run_state() -> void:
	## 得分与关卡聚合
	_total_score = 0
	once_total_score = 0
	max_once_score = 0
	count_stage = 1
	count_add_coins = 0
	count_round = 0
	dice_type_add_coin = 0
	_one_score = 0
	_two_score = 0
	_three_score = 0
	_four_score = 0
	_five_score = 0
	_six_score = 0
	dice_type_point = 0
	dice_type_count = 0
	## HP/血瓶/防御/回血
	_player_hp = 5
	_max_hp = 5
	player_defense = 2
	_score_heal_accumulated = 0
	_potion_count = 1
	_potion_max = 3
	iron_stomach_reduction = 0
	scorched_earth_bonus = 0.0
	has_death_immunity = false
	death_immunity_used = false
	## HP重置后主动刷新心形血条：恢复为全部实心爱心
	## （上方直写 _ 前缀内部变量绕过了 setter，需手动刷UI）
	_update_hp_ui()
	_update_potion_button_state()
	## 防御重置为2后主动刷新盾牌防御条
	_update_defense_ui()
	## 骰型板/结算标记
	_drop_slot_consumed_this_turn = false
	_drop_slot_dice = null
	_duizi_percent = 0
	_shunzi_percent = 0
	_tongse_percent = 0
	_tongdui_percent = 0
	_tongshun_percent = 0
	_base_score = 0
	_percent_score = 0.0
	attack_animation_finished = 1
	slime_create_num = 3
	power_slime_num = 1
	## 等级/经验/能量
	level = 0
	hero_exp = 0
	require_exp = 3
	max_power = 2
	power = 0
	power_skill = 0
	## 金币技能
	coin_skill_array_dict = []
	coin_skill_used = []
	zero_coin_refresh_max_times = 0
	zero_coin_refresh_times = 0
	## 击杀/回合计数标记
	slime_die_sum = 0
	killed_slime_colors = []
	pattern_kill_sum = 0
	killed_power_slime = false
	last_turn_attacked = false
	consecutive_score_turns = 0
	dropped_dice_count = 0
	scored_dice_info = []
	active_dice_types = []
	slime_tide_pending = 0
	swarm_call_pending = 0
	## 回合/移动/技能标记与路径
	turn = "hero_turn"
	_is_moved = false
	_is_attacked = false
	grids_moved_this_turn = 0
	pre_move_position = Vector2.ZERO
	pre_move_grid_index = Vector2.ZERO
	pre_move_total_score = 0
	undo_snapshot = []
	id_path = []
	movable_grid_index_array = []
	skill_num = ""
	skill_target_range = []
	skill_attack_range = []
	transformable_slime_array = []
	all_hero_dict = {}
	last_slime_create_array = []
	public_lock_array = []
	action_lock = false
	has_attack_grid = false
	## buff 购买折扣（金币本身由战局 _ready 重新初始化为 15）
	_buff_price_discount = 0
	dice_multiplier_dict = {}
## 当前关卡
var _count_stage: int = 1  ## 直写用内部变量（存档灌入/读档恢复路径专用）
var count_stage: int:
	set(v):
		_count_stage = v
		var stage_icon
		for row in game_manager.stage_info_json_data:
			if row["stage_num"] == Current.count_stage:
				stage_icon = row["stage_type_icon"]
		var stage_text: String = tr("关卡· %s") % tr(Tools.num_to_cnnum[v])
		game_manager.stage_label.text = stage_text
		game_manager.clear_stage_label.text = stage_text
		game_manager.stage_effect_label.text = tr("关卡· %s [img=17]%s[/img]") % [tr(Tools.num_to_cnnum[v]), stage_icon]
	get:
		return _count_stage
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
var _total_coins: int = 0  ## 直写用内部变量（存档灌入/读档恢复路径专用）
var total_coins: int:
	set(v):
		_total_coins = v
		game_manager.total_coins_label.text = str(v)
		## 处理按钮和图标的禁用状态
		game_manager.potion_button.disabled = true
		game_manager.coin_skill_1.disabled = true
		game_manager.coin_skill_2.disabled = true
		game_manager.coin_skill_3.disabled = true
		game_manager.coin_skill_1_icon.self_modulate = Color(1, 1, 1, 0.3)
		game_manager.coin_skill_2_icon.self_modulate = Color(1, 1, 1, 0.3)
		game_manager.coin_skill_3_icon.self_modulate = Color(1, 1, 1, 0.3)
		## 血瓶按钮：有血瓶且未满血时启用
		if _potion_count > 0 and _player_hp < _max_hp:
			game_manager.potion_button.disabled = false
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
		## 商店购买按钮：免刷次数>0时不因金币不足禁用
		if zero_coin_refresh_times <= 0 and v < game_manager.buff_refresh_cost:
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
	get:
		return _total_coins

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
var _count_round: int = 0  ## 直写用内部变量（存档灌入路径专用，绕过船 tween 演出）
var count_round := 0:
	set(v):
		_count_round = v
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
		game_manager.turn_label.text = str(v)
	get:
		return _count_round
## 本关骰型等级金币奖励累计（每次打出骰型按等级累加，关卡开始时清零）
var dice_type_add_coin := 0
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
	if game_manager.drop_slot_panel_icon:
		var icon: TextureRect = game_manager.drop_slot_panel_icon
		if _drop_slot_dice == null:
			icon.texture = null
		else:
			icon.texture = load("res://images/ui_icon/dice_%s_%d.tres" % [_drop_slot_dice[0], _drop_slot_dice[1]])
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
var _level: int = 0  ## 直写用内部变量（存档灌入/读档恢复路径专用）
var level: int:
	set(v):
		_level = v
		game_manager.level_label.text = "Lv." + str(v)
	get:
		return _level
## 当前经验
var hero_exp := 0
## 升级需要的经验
var require_exp := 3
## 持续动作锁
var action_lock := false
## 最大能量
var _max_power: int = 2  ## 直写用内部变量（存档灌入/读档恢复路径专用）
var max_power := 2:
	set(v):
		_max_power = v
		game_manager.power_label.text = str(power) + "/" + str(v)
	get:
		return _max_power
## 当前能量
var _power: int = 0  ## 直写用内部变量（存档灌入/读档恢复路径专用）
var power: int:
	set(v):
		var _clamped = mini(v, _max_power)
		_power = _clamped
		game_manager.power_label.text = str(_clamped) + "/" + str(Current.max_power)
	get:
		return _power
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



## 更新得分回血进度UI（血瓶进度条）
func _update_score_heal_ui():
	if game_manager and game_manager.blood_bottle_progress:
		game_manager.blood_bottle_progress.max_value = float(_score_heal_threshold)
		game_manager.blood_bottle_progress.value = float(_score_heal_accumulated)
	if game_manager and game_manager.blood_bottle_progress_label:
		game_manager.blood_bottle_progress_label.text = str(_score_heal_accumulated) + "/" + str(_score_heal_threshold)

## 更新血瓶数量/上限UI及按钮启用状态
func _update_potion_ui():
	if game_manager and game_manager.blood_bottle_label:
		game_manager.blood_bottle_label.text = str(_potion_count) + "/" + str(_potion_max)
	_update_potion_button_state()

## 更新血瓶按钮的启用/禁用状态
func _update_potion_button_state():
	if not game_manager:
		return
	if _potion_count > 0 and _player_hp < _max_hp:
		game_manager.potion_button.disabled = false
	else:
		game_manager.potion_button.disabled = true

## 更新撤回移动按钮的启用/禁用状态
func _update_undo_move_button_state():
	if not game_manager:
		return
	if not game_manager.has_node("coin_skill_trun_button/HBoxContainer/undo_move_button"):
		return
	var undo_button = game_manager.get_node("coin_skill_trun_button/HBoxContainer/undo_move_button")
	var undo_label = game_manager.get_node("coin_skill_trun_button/HBoxContainer/undo_move_button/scale_wrapper2") if undo_button else null
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

## 更新盾牌防御条UI
func _update_defense_ui():
	if game_manager and game_manager.has_node("round_process_bar/defense_bar"):
		var defense_bar = game_manager.get_node("round_process_bar/defense_bar")
		if defense_bar.has_method("update_shields"):
			defense_bar.update_shields(player_defense)


## ============================================================
## 存档快照导出/灌入（由 SaveManager.capture/apply 调用）
## ============================================================
## ⚠️ 成对修改纪律：run 状态字段增删必须同步修改 reset_run_state()/
## export_run_state()/apply_run_state() 三处（互引注释见 reset_run_state 上方与
## SaveManager.capture）。last_slime_create_array 例外：节点引用不入 run_state，
## 由快照 board.last_created 以格子索引承载。

## 导出 run 级状态（以 reset_run_state 清单为基线，同构逐字段导出）。
## 直读 _ 前缀内部变量与普通变量，避免任何 setter 副作用。
func export_run_state() -> Dictionary:
	return {
		## —— 得分与关卡聚合 ——
		"total_score": _total_score,
		"once_total_score": once_total_score,
		"max_once_score": max_once_score,
		"count_stage": _count_stage,
		"count_add_coins": count_add_coins,
		"count_round": _count_round,
		"dice_type_add_coin": dice_type_add_coin,
		"one_score": _one_score,
		"two_score": _two_score,
		"three_score": _three_score,
		"four_score": _four_score,
		"five_score": _five_score,
		"six_score": _six_score,
		"dice_type_point": dice_type_point,
		"dice_type_count": dice_type_count,
		## —— HP/防御/血瓶/回血 ——
		"player_hp": _player_hp,
		"max_hp": _max_hp,
		"player_defense": player_defense,
		"score_heal_accumulated": _score_heal_accumulated,
		## 清单之外补充：score_heal_threshold 是 run 级演化值（reset_run_state 不重置，
		## 由战局 _ready 重设），回血进度条依赖，必须随存档走
		"score_heal_threshold": _score_heal_threshold,
		"potion_count": _potion_count,
		"potion_max": _potion_max,
		"iron_stomach_reduction": iron_stomach_reduction,
		"scorched_earth_bonus": scorched_earth_bonus,
		"has_death_immunity": has_death_immunity,
		"death_immunity_used": death_immunity_used,
		## —— 骰型板/掉落格/结算标记 ——
		"drop_slot_consumed_this_turn": _drop_slot_consumed_this_turn,
		"drop_slot_dice": _drop_slot_dice,
		"duizi_percent": _duizi_percent,
		"shunzi_percent": _shunzi_percent,
		"tongse_percent": _tongse_percent,
		"tongdui_percent": _tongdui_percent,
		"tongshun_percent": _tongshun_percent,
		"base_score": _base_score,
		"percent_score": _percent_score,
		"attack_animation_finished": attack_animation_finished,
		"slime_create_num": slime_create_num,
		"power_slime_num": power_slime_num,
		## —— 等级/经验/能量 ——
		"level": _level,
		"hero_exp": hero_exp,
		"require_exp": require_exp,
		"max_power": _max_power,
		"power": _power,
		"power_skill": power_skill,
		## —— 金币技能 ——
		"coin_skill_array_dict": coin_skill_array_dict.duplicate(true),
		"coin_skill_used": coin_skill_used.duplicate(),
		"zero_coin_refresh_max_times": zero_coin_refresh_max_times,
		"zero_coin_refresh_times": zero_coin_refresh_times,
		## —— 击杀/回合计数标记 ——
		"slime_die_sum": slime_die_sum,
		"killed_slime_colors": killed_slime_colors.duplicate(),
		"pattern_kill_sum": pattern_kill_sum,
		"killed_power_slime": killed_power_slime,
		"last_turn_attacked": last_turn_attacked,
		"consecutive_score_turns": consecutive_score_turns,
		"dropped_dice_count": dropped_dice_count,
		"scored_dice_info": scored_dice_info.duplicate(true),
		"active_dice_types": active_dice_types.duplicate(),
		"slime_tide_pending": slime_tide_pending,
		"swarm_call_pending": swarm_call_pending,
		## —— 回合/移动/技能标记与路径（回合边界均为已重置状态）——
		"turn": turn,
		"is_moved": _is_moved,
		"is_attacked": _is_attacked,
		"grids_moved_this_turn": grids_moved_this_turn,
		"pre_move_position": [pre_move_position.x, pre_move_position.y],
		"pre_move_grid_index": [pre_move_grid_index.x, pre_move_grid_index.y],
		"pre_move_total_score": pre_move_total_score,
		"id_path": id_path.duplicate(),
		"movable_grid_index_array": movable_grid_index_array.duplicate(),
		"skill_num": skill_num,
		"skill_target_range": skill_target_range.duplicate(),
		"skill_attack_range": skill_attack_range.duplicate(),
		"transformable_slime_array": [],
		"all_hero_dict": {},
		"public_lock_array": public_lock_array.duplicate(),
		"action_lock": action_lock,
		"has_attack_grid": has_attack_grid,
		## —— buff 购买折扣 ——
		"buff_price_discount": _buff_price_discount,
		## —— 骰型倍率表（键为 dice_sum int；apply 侧重建 int 键）——
		"dice_multiplier_dict": dice_multiplier_dict.duplicate(true),
	}

## 灌入 run 级状态：全部直写 _ 前缀内部变量（或普通变量），全程零 setter 触发。
## JSON 往返会把数字变为 float，逐字段显式转换回目标类型（typed 变量不接受 float 赋值）。
## UI 不在此处刷新（含演出副作用的 setter 一律不触发）；统一由 refresh_all_ui 收口。
func apply_run_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	## —— 得分与关卡聚合 ——
	_total_score = int(data.get("total_score", _total_score))
	once_total_score = int(data.get("once_total_score", once_total_score))
	max_once_score = int(data.get("max_once_score", max_once_score))
	_count_stage = int(data.get("count_stage", _count_stage))
	count_add_coins = int(data.get("count_add_coins", count_add_coins))
	_count_round = int(data.get("count_round", _count_round))
	dice_type_add_coin = int(data.get("dice_type_add_coin", dice_type_add_coin))
	_one_score = int(data.get("one_score", _one_score))
	_two_score = int(data.get("two_score", _two_score))
	_three_score = int(data.get("three_score", _three_score))
	_four_score = int(data.get("four_score", _four_score))
	_five_score = int(data.get("five_score", _five_score))
	_six_score = int(data.get("six_score", _six_score))
	dice_type_point = int(data.get("dice_type_point", dice_type_point))
	dice_type_count = int(data.get("dice_type_count", dice_type_count))
	## —— HP/防御/血瓶/回血 ——
	_player_hp = int(data.get("player_hp", _player_hp))
	_max_hp = int(data.get("max_hp", _max_hp))
	player_defense = int(data.get("player_defense", player_defense))
	_score_heal_accumulated = int(data.get("score_heal_accumulated", _score_heal_accumulated))
	_score_heal_threshold = int(data.get("score_heal_threshold", _score_heal_threshold))
	_potion_count = int(data.get("potion_count", _potion_count))
	_potion_max = int(data.get("potion_max", _potion_max))
	iron_stomach_reduction = int(data.get("iron_stomach_reduction", iron_stomach_reduction))
	scorched_earth_bonus = float(data.get("scorched_earth_bonus", scorched_earth_bonus))
	has_death_immunity = bool(data.get("has_death_immunity", has_death_immunity))
	death_immunity_used = bool(data.get("death_immunity_used", death_immunity_used))
	## —— 骰型板/掉落格/结算标记 ——
	_drop_slot_consumed_this_turn = bool(data.get("drop_slot_consumed_this_turn", _drop_slot_consumed_this_turn))
	## 掉落格骰子 [color, point]：point 归一回 int（"%d" 格式化路径依赖 int）
	var slot_dice: Variant = data.get("drop_slot_dice", null)
	if slot_dice is Array and slot_dice.size() >= 2:
		_drop_slot_dice = [str(slot_dice[0]), int(slot_dice[1])]
	else:
		_drop_slot_dice = null
	_duizi_percent = int(data.get("duizi_percent", _duizi_percent))
	_shunzi_percent = int(data.get("shunzi_percent", _shunzi_percent))
	_tongse_percent = int(data.get("tongse_percent", _tongse_percent))
	_tongdui_percent = int(data.get("tongdui_percent", _tongdui_percent))
	_tongshun_percent = int(data.get("tongshun_percent", _tongshun_percent))
	_base_score = int(data.get("base_score", _base_score))
	_percent_score = float(data.get("percent_score", _percent_score))
	attack_animation_finished = int(data.get("attack_animation_finished", attack_animation_finished))
	slime_create_num = int(data.get("slime_create_num", slime_create_num))
	power_slime_num = int(data.get("power_slime_num", power_slime_num))
	## —— 等级/经验/能量 ——
	_level = int(data.get("level", _level))
	hero_exp = int(data.get("hero_exp", hero_exp))
	require_exp = int(data.get("require_exp", require_exp))
	_max_power = int(data.get("max_power", _max_power))
	_power = int(data.get("power", _power))
	power_skill = int(data.get("power_skill", power_skill))
	## —— 金币技能 ——
	coin_skill_array_dict = _as_array(data.get("coin_skill_array_dict", []))
	## 数字字段归一回 int（coin_skill_shop_cost 参与 int 运算）
	for skill_row in coin_skill_array_dict:
		if skill_row is Dictionary and skill_row.has("coin_skill_shop_cost"):
			skill_row["coin_skill_shop_cost"] = int(skill_row["coin_skill_shop_cost"])
	coin_skill_used = _as_array(data.get("coin_skill_used", []))
	zero_coin_refresh_max_times = int(data.get("zero_coin_refresh_max_times", zero_coin_refresh_max_times))
	zero_coin_refresh_times = int(data.get("zero_coin_refresh_times", zero_coin_refresh_times))
	## —— 击杀/回合计数标记 ——
	slime_die_sum = int(data.get("slime_die_sum", slime_die_sum))
	killed_slime_colors = _as_array(data.get("killed_slime_colors", []))
	pattern_kill_sum = int(data.get("pattern_kill_sum", pattern_kill_sum))
	killed_power_slime = bool(data.get("killed_power_slime", killed_power_slime))
	last_turn_attacked = bool(data.get("last_turn_attacked", last_turn_attacked))
	consecutive_score_turns = int(data.get("consecutive_score_turns", consecutive_score_turns))
	dropped_dice_count = int(data.get("dropped_dice_count", dropped_dice_count))
	scored_dice_info = _as_array(data.get("scored_dice_info", []))
	active_dice_types = _as_array(data.get("active_dice_types", []))
	slime_tide_pending = int(data.get("slime_tide_pending", slime_tide_pending))
	swarm_call_pending = int(data.get("swarm_call_pending", swarm_call_pending))
	## —— 回合/移动/技能标记与路径 ——
	turn = str(data.get("turn", "hero_turn"))
	_is_moved = bool(data.get("is_moved", false))
	_is_attacked = bool(data.get("is_attacked", false))
	grids_moved_this_turn = int(data.get("grids_moved_this_turn", 0))
	pre_move_position = _arr_to_vec2(data.get("pre_move_position", [0, 0]))
	pre_move_grid_index = _arr_to_vec2(data.get("pre_move_grid_index", [0, 0]))
	pre_move_total_score = int(data.get("pre_move_total_score", 0))
	id_path = _as_array(data.get("id_path", []))
	movable_grid_index_array = _as_array(data.get("movable_grid_index_array", []))
	skill_num = str(data.get("skill_num", ""))
	skill_target_range = _as_array(data.get("skill_target_range", []))
	skill_attack_range = _as_array(data.get("skill_attack_range", []))
	transformable_slime_array = []
	all_hero_dict = {}
	public_lock_array = _as_array(data.get("public_lock_array", []))
	action_lock = bool(data.get("action_lock", false))
	has_attack_grid = bool(data.get("has_attack_grid", false))
	## —— buff 购买折扣 ——
	_buff_price_discount = int(data.get("buff_price_discount", _buff_price_discount))
	## —— 骰型倍率表：JSON 往返后字典键变字符串，重建为 int 键
	## （ScoringAlgorithm 以 Current.dice_multiplier_dict[骰子数:int] 下标访问，字符串键会查空崩溃）
	var mult: Variant = data.get("dice_multiplier_dict", {})
	dice_multiplier_dict = {}
	if mult is Dictionary:
		for key in mult:
			dice_multiplier_dict[int(key)] = mult[key]

## 读档恢复后的统一 UI 刷新：全部 label 直写，零 setter 触发、无飘字/数字滚动/
## 船 tween 等演出副作用（规格"读档无演出副作用"）。
## 归拢 _update_hp_ui/_update_potion_ui/_update_defense_ui/_update_score_heal_ui/
## _update_drop_slot_ui 与分数板/骰型板/HUD label 直写、商店按钮批刷（total_coins
## setter 即既有批刷入口）、按 count_round 静态计算船位置。
func refresh_all_ui() -> void:
	if not game_manager:
		return
	_update_hp_ui()
	_update_potion_ui()
	_update_defense_ui()
	_update_score_heal_ui()
	_update_drop_slot_ui()
	_update_undo_move_button_state()
	## —— 分数板直写（绕过 setter，避免 big_flow_effect 飘字）——
	game_manager.total_score.text = str(_total_score)
	game_manager.one_score.text = str(_one_score)
	game_manager.two_score.text = str(_two_score)
	game_manager.three_score.text = str(_three_score)
	game_manager.four_score.text = str(_four_score)
	game_manager.five_score.text = str(_five_score)
	game_manager.six_score.text = str(_six_score)
	game_manager.duizi_percent.text = str(_duizi_percent) + "%"
	game_manager.shunzi_percent.text = str(_shunzi_percent) + "%"
	game_manager.tongse_percent.text = str(_tongse_percent) + "%"
	game_manager.tongdui_percent.text = str(_tongdui_percent) + "%"
	game_manager.tongshun_percent.text = str(_tongshun_percent) + "%"
	game_manager.base_score.text = str(_base_score) if _base_score != 0 else ""
	game_manager.percent_score.text = (str(int(_percent_score)) + "%") if _percent_score != 0.0 else ""
	## —— HUD 直写 ——
	game_manager.level_label.text = "Lv." + str(_level)
	game_manager.power_label.text = str(_power) + "/" + str(_max_power)
	game_manager.exp_bar.value = hero_exp
	game_manager.exp_bar.max_value = require_exp
	game_manager._set_exp_bar_scale(hero_exp, require_exp)
	## —— 金币技能栏图标/tooltip/label 直写 ——
	var skill_buttons: Array = [game_manager.coin_skill_1, game_manager.coin_skill_2, game_manager.coin_skill_3]
	var skill_icons: Array = [game_manager.coin_skill_1_icon, game_manager.coin_skill_2_icon, game_manager.coin_skill_3_icon]
	var skill_labels: Array = [game_manager.coin_skill_1_label, game_manager.coin_skill_2_label, game_manager.coin_skill_3_label]
	for i in 3:
		if i < coin_skill_array_dict.size() and coin_skill_array_dict[i] is Dictionary:
			var skill_row: Dictionary = coin_skill_array_dict[i]
			skill_icons[i].texture = load(skill_row["coin_skill_icon"])
			TooltipManager.set_tooltip(skill_buttons[i], TooltipFormatter.format_coin_skill(skill_row))
			## 与 _set_coin_skill 行为对齐：槽位1 不写 label（既有注释掉的路径），槽位2/3 写
			if i >= 1:
				skill_labels[i].text = tr(skill_row["coin_skill_name"])
		else:
			skill_icons[i].texture = null
	refresh_coin_skill_buttons()
	## —— 商店按钮批刷（total_coins setter 即批刷入口，沿用既有 idiom）——
	total_coins = _total_coins
	## —— 商店刷新价格标签直写（与 buff_refresh_cost setter 同款格式）——
	if zero_coin_refresh_times > 0:
		game_manager.buff_refresh_rlabel.text = " [img=24]res://images/ui_icon/refresh.png[/img]   [img=16]res://images/ui_icon/coin.png[/img] %d" % 0
	else:
		game_manager.buff_refresh_rlabel.text = " [img=24]res://images/ui_icon/refresh.png[/img]   [img=16]res://images/ui_icon/coin.png[/img] %d" % game_manager.buff_refresh_cost
	## —— 关卡文本直写（复制 count_stage setter 的文本装配，不走 setter）——
	var stage_icon := ""
	for row in game_manager.stage_info_json_data:
		if row["stage_num"] == _count_stage:
			stage_icon = row["stage_type_icon"]
	var stage_text: String = tr("关卡· %s") % tr(Tools.num_to_cnnum[_count_stage])
	game_manager.stage_label.text = stage_text
	game_manager.clear_stage_label.text = stage_text
	game_manager.stage_effect_label.text = tr("关卡· %s [img=17]%s[/img]") % [tr(Tools.num_to_cnnum[_count_stage]), stage_icon]
	## —— 回合数与船位（count_round setter 的 tween 只属于真实回合推进；
	## 恢复时按 count_round 静态落位，>10 后停在最后格）——
	if _count_round <= 1:
		game_manager.ship.position = Vector2(4, 2)
	elif _count_round < 11:
		game_manager.ship.position = Vector2(4, 2) + ((_count_round - 1) * Vector2(7, 0))
	else:
		game_manager.ship.position = Vector2(4, 2) + (9 * Vector2(7, 0))
	game_manager.turn_label.text = str(_count_round)

## Variant → Array（JSON 往返防御：非数组一律空数组）
func _as_array(v: Variant) -> Array:
	return v if v is Array else []

## [x, y] 数组 → Vector2（JSON 往返后元素为 float，显式 float() 收敛）
func _arr_to_vec2(arr: Variant) -> Vector2:
	if arr is Array and arr.size() >= 2:
		return Vector2(float(arr[0]), float(arr[1]))
	return Vector2.ZERO
