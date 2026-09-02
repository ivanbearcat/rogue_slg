extends Node2D
## 悬停追踪器（HoverTracker）：每个渲染帧用 floori 数学换算解析鼠标所在格子，
## 替代 Area2D 物理拾取（13x13 碰撞盒死区 / 60Hz 采样延迟 / 快速扫动丢格）。
## 独家维护悬停状态契约：Current.grid_index / within_grid_area / slime / has_attack_grid，
## 以及 cursor 白框、attack 红框（按 Current.mouse_status 行为矩阵分派）、精英/BOSS tooltip。
## 挂载：game_manager._ready() 中创建并 add_child；通过 get_parent() 引用 game_manager，
## 子节点随战局销毁，生命周期与战局一致。

## 当前悬停格子索引（Vector2i）；棋盘外 / 窗口外为 null
var _hovered_index = null
## default 模式攻击预览代数：每次 show 预览 +1；
## 结算锁等待恢复后仅代数未变才隐藏，防止误杀等待期间新格子的预览
var _preview_generation: int = 0
## 当前 tooltip 显示中的史莱姆引用（仅用于内容去重）
var _tooltip_slime = null
## tooltip 是否正由本 tracker 显示。
## freed 引用与 null 的比较结果为 true，无法用 != null 检出失效，
## 故用 bool 记忆显示状态，配合 is_instance_valid 直判史莱姆有效性。
var _tooltip_active: bool = false
## Current.slime 当前是否为有效悬停引用（bool 记忆，检出 freed 残留）
var _slime_is_set: bool = false
## 鼠标是否在游戏窗口内（Viewport mouse_entered/exited 维护，离开窗口视为棋盘外）
var _mouse_in_window: bool = true

@onready var game_manager: Node2D = get_parent()

func _ready() -> void:
	get_viewport().mouse_entered.connect(_on_viewport_mouse_entered)
	get_viewport().mouse_exited.connect(_on_viewport_mouse_exited)

func _on_viewport_mouse_entered() -> void:
	_mouse_in_window = true

func _on_viewport_mouse_exited() -> void:
	_mouse_in_window = false

func _process(_delta: float) -> void:
	var index = _resolve_hover_index()
	if index == _hovered_index:
		## 常态自愈：悬停的史莱姆死亡时清理悬挂引用与 tooltip。
		## freed 引用与 null 的比较结果为 true（无法用 != null 检出），
		## 故用 _slime_is_set bool 记忆作入口，is_instance_valid 直判失效。
		if _slime_is_set and not is_instance_valid(Current.slime):
			Current.slime = null
			_slime_is_set = false
			_hide_tooltip_if_shown()
		return
	_apply_transition(_hovered_index, index)
	_hovered_index = index

## floori 数学换算：鼠标世界坐标 → 格子索引（不依赖物理帧、无格间死区）。
## 棋盘范围外（0 <= i < _removable_map_vec）或鼠标离开游戏窗口时返回 null。
## 不用 Tools.position_to_grid_index：其内部 Vector2i() 向零截断，
## 棋盘外负坐标会错误折回 0 而判为合法格。
func _resolve_hover_index():
	if not _mouse_in_window:
		return null
	var offset: Vector2 = get_global_mouse_position() - game_manager.start_pos
	var x: int = floori(offset.x / game_manager.grid_size.x)
	var y: int = floori(offset.y / game_manager.grid_size.y)
	if x < 0 or x >= game_manager._removable_map_vec.x \
			or y < 0 or y >= game_manager._removable_map_vec.y:
		return null
	return Vector2i(x, y)

## 悬停状态迁移：先应用旧格退出语义，再应用新格进入语义（与旧 enter/exit 事件顺序一致）。
## 无论哪种迁移都同步刷新 cursor 白框与 Current 状态，全部同帧完成、无 await 事件延迟。
func _apply_transition(old_index, new_index) -> void:
	if old_index == null and new_index == null:
		return
	## ---- 退出语义（旧格）----
	if old_index != null:
		var old_grid: Node2D = _grid_at(old_index)
		if old_grid:
			old_grid.cursor.hide()
		Current.grid_index = Vector2.ZERO
		_apply_exit_semantics(new_index)
	## ---- 进入语义（新格）----
	if new_index != null:
		var new_grid: Node2D = _grid_at(new_index)
		if new_grid:
			new_grid.cursor.show()
		Current.grid_index = Vector2(new_index)
		Current.within_grid_area = true
		## 悬停史莱姆同步解析（替代旧 slime Area2D 事件 + 0.05s 延迟）
		Current.slime = _resolve_slime_at(new_index)
		_slime_is_set = Current.slime != null
		_apply_enter_semantics(new_index)
		_update_tooltip()
	else:
		Current.within_grid_area = false
		Current.slime = null
		_slime_is_set = false
		_hide_tooltip_if_shown()

## 按格子索引取格子节点（all_grid_dict 键为 Vector2，需从 Vector2i 转换）
func _grid_at(index: Vector2i) -> Node2D:
	var key := Vector2(index)
	if game_manager.all_grid_dict.has(key):
		return game_manager.all_grid_dict[key]
	return null

## 在敌方数组中按 enemy_grid_index 解析悬停格上的史莱姆；
## 已失效实例（死亡移除中）跳过，找不到返回 null
func _resolve_slime_at(index: Vector2i):
	for enemy in Current.all_enemy_array:
		if is_instance_valid(enemy) and enemy.enemy_grid_index == Vector2(index):
			return enemy
	return null

## 进入语义：按 Current.mouse_status 分派红框（attack）行为，与旧 grid.gd enter 分支一致
func _apply_enter_semantics(index: Vector2i) -> void:
	match Current.mouse_status:
		"default":
			var grid: Node2D = _grid_at(index)
			## 目标区域框出现且没有在播放攻击动画
			if grid and grid.target.visible and Current.attack_animation_finished == 1:
				EventBus.event_emit("show_skill_attack", [Current.hero.hero_name, Current.skill_num])
				Current.has_attack_grid = true
				_preview_generation += 1
		"reroll_dice", "reroll_color", "dice_adjust", "swap":
			var grid: Node2D = _grid_at(index)
			## 同步判定：悬停格上有史莱姆即显示红框（无延迟等待史莱姆事件）
			if grid and Current.slime != null \
					and Current.slime.enemy_grid_index == Vector2(index):
				grid.attack.show()
		"reroll_all", "mouse_up", "mouse_down", "mouse_left", "mouse_right":
			for grid in Current.all_grids_array:
				grid.attack.show()
		"add_power":
			var grid: Node2D = _grid_at(index)
			if grid and Current.hero.hero_grid_index == Vector2(index):
				grid.attack.show()

## 退出语义：与旧 grid.gd exit 分支一致
## new_index 为本次迁移后的悬停结果（null = 已离开棋盘/窗口）
func _apply_exit_semantics(new_index) -> void:
	match Current.mouse_status:
		"default":
			if Current.has_attack_grid:
				_default_exit_guarded()
		"reroll_all", "mouse_up", "mouse_down", "mouse_left", "mouse_right":
			## 移出格子区域不显示红框：仅迁移后悬停为 null（离开棋盘）时清除全部
			if new_index == null:
				for grid in Current.all_grids_array:
					grid.attack.hide()
		_:
			## reroll_dice / reroll_color / dice_adjust / swap / add_power
			EventBus.event_emit("hide_skill_attack")

## default 退出：等待结算锁（action_lock）清除后隐藏攻击预览，带代数守卫。
## 等待期间若新格子已重新 show 预览（generation 变化），放弃隐藏以免误杀新预览。
func _default_exit_guarded() -> void:
	var generation: int = _preview_generation
	## 等待分数结算动画和计分完成
	while Current.action_lock:
		await Tools.time_sleep(0.05)
	if generation != _preview_generation:
		return
	EventBus.event_emit("hide_skill_attack")
	Current.has_attack_grid = false

## 精英/BOSS tooltip 迁移：悬停格上有该类史莱姆时在其上方显示，离开隐藏
func _update_tooltip() -> void:
	var slime = Current.slime
	if slime != null and is_instance_valid(slime) and (slime.is_elite or slime.is_boss):
		if _tooltip_slime != slime:
			TooltipManager.show_tooltip_at(
					slime.global_position + Vector2(-80, -40),
					TooltipFormatter.format_elite_slime(
							slime.is_boss, slime.gate_type, slime.gate_count, slime.dice_point))
			_tooltip_slime = slime
			_tooltip_active = true
	elif _tooltip_active:
		TooltipManager.hide_tooltip()
		_tooltip_active = false
		_tooltip_slime = null

func _hide_tooltip_if_shown() -> void:
	if _tooltip_active:
		TooltipManager.hide_tooltip()
		_tooltip_active = false
		_tooltip_slime = null
