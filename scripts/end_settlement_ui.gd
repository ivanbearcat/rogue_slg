extends CanvasLayer
## 游戏结束结算界面子场景（胜利/失败两态）：内部节点引用集中持有（% 唯一名自持引用）
## 订阅 EventBus run_end 取数显示：buff 列表取 Telemetry 快照，其余取 Current

## 胜利/失败标题文案
const TITLE_WIN := "通关达成"
const TITLE_FAIL := "战败"

@onready var paper_texture: TextureRect = %paper_texture
@onready var end_title_label: Label = %end_title_label
@onready var buff_row: HFlowContainer = %buff_row
@onready var coins_label: Label = %coins_label
@onready var max_once_label: Label = %max_once_label
@onready var total_score_label: Label = %total_score_label
@onready var end_confirm_button: TextureButton = %end_confirm_button
@onready var buff_board: NinePatchRect = %buff_board

## 缓冲的数据快照（run_end 时点取值，动效播放期间 Current 可能变化）
var _stats: Dictionary = {}
## 是否正在播放动效（防重入）
var _is_showing := false


func _ready() -> void:
	EventBus.subscribe("run_end", _on_run_end)
	end_confirm_button.pressed.connect(_on_confirm_pressed)


## ============================================================
## EventBus 事件处理
## ============================================================

## run 结束：缓冲数据快照后显示结算画面（win/fail 两态）
func _on_run_end(result: String) -> void:
	if _is_showing:
		return
	_is_showing = true
	## 缓冲快照：buff 列表取遥测 run 级全量清单，其余取 Current 结束时点值
	_stats = {
		"result": result,
		"buffs": Telemetry.get_run_buffs_snapshot(),
		"coins": Current.total_coins,
		"max_once_score": Current.max_once_score,
		"total_score": Current.total_score,
	}
	_setup_and_show(_stats)


## ============================================================
## 对外接口
## ============================================================

## 注入两态文案并显示（模式对齐 clear_stage_ui：内部自持引用驱动动效）
func setup(result: String, stats: Dictionary) -> void:
	_setup_and_show({"result": result, "stats": stats})


## ============================================================
## 显示与动效（全程 TWEEN_PAUSE_PROCESS，暂停中播放）
## ============================================================

func _setup_and_show(data: Dictionary) -> void:
	## 打开时确认暂停（失败路径已 paused；胜利路径此处暂停收口流程）
	get_tree().paused = true
	var result: String = data.get("result", "fail")
	var stats: Dictionary = data.get("stats", data)
	## 两态标题
	end_title_label.text = TITLE_WIN if result == "win" else TITLE_FAIL
	## buff 图标行：先清空再按快照重建（图标经 config buff/debuff 的 icon 键映射，tooltip 走 rich_tooltip 通路）
	for child in buff_row.get_children():
		child.queue_free()
	for buff_entry in stats.get("buffs", []):
		var icon_item := _create_buff_icon_item(buff_entry)
		if icon_item != null:
			buff_row.add_child(icon_item)
	## 数值行归零（等待滚动动效）
	coins_label.text = "0"
	max_once_label.text = "0"
	total_score_label.text = "0"
	## 重置可见态
	paper_texture.visible = true
	end_title_label.hide()
	buff_row.hide()
	coins_label.get_parent().hide()
	max_once_label.get_parent().hide()
	total_score_label.get_parent().hide()
	end_confirm_button.hide()
	buff_board.hide()
	## 显示整层
	show()
	## 动效序列：面板掉入 → 标题/行打字机 → 数值滚动 → buff 图标逐个 → 确定按钮
	await EffectManager.top_to_bottom_effect(paper_texture, 0.5)
	end_title_label.show()
	await EffectManager.typewriter_effect(end_title_label, end_title_label.text, 0.5)
	var coins_row: Control = coins_label.get_parent()
	coins_row.show()
	await EffectManager.label_num_rolling_effect(coins_label, stats.get("coins", 0))
	var max_once_row: Control = max_once_label.get_parent()
	max_once_row.show()
	await EffectManager.label_num_rolling_effect(max_once_label, stats.get("max_once_score", 0))
	var total_row: Control = total_score_label.get_parent()
	total_row.show()
	await EffectManager.label_num_rolling_effect(total_score_label, stats.get("total_score", 0))
	buff_board.show()
	buff_row.show()
	for icon_item in buff_row.get_children():
		EffectManager.buff_pop_effect(icon_item)
		await Tools.time_sleep(0.08)
	end_confirm_button.disabled = false
	end_confirm_button.show()


## buff 图标条目：PanelContainer+TextureRect（buff_texture.tscn 同款结构）+ buff_meta 元数据
func _create_buff_icon_item(buff_entry: Dictionary) -> Control:
	var item: PanelContainer = load("res://scenes/buff_texture.tscn").instantiate()
	var meta := _lookup_buff_meta(str(buff_entry.get("id", "")))
	if meta.is_empty():
		return null
	item.texture = load(str(meta["icon_path"]))
	item.set_meta("buff_meta", meta["meta"])
	item.set_rich_tooltip(TooltipFormatter.format_buff(meta["meta"]))
	return item


## 按 id 在 buff 配置中查找图标路径与元数据（结算只展示 buff，debuff 不上屏）
func _lookup_buff_meta(buff_id: String) -> Dictionary:
	if buff_id.is_empty():
		return {}
	for row: Dictionary in Tools.load_json_file("res://config/buff.json"):
		if str(row.get("buff_id", "")) == buff_id:
			return {"icon_path": row.get("buff_icon", ""), "meta": row}
	return {}


## ============================================================
## 确定按钮收口
## ============================================================

func _on_confirm_pressed() -> void:
	var result: String = str(_stats.get("result", "fail"))
	_is_showing = false
	hide()
	## 胜利态回到游戏初始选人画面（与既有游戏结束路径一致）；失败态仅恢复运行
	if result == "win":
		## 先恢复运行再切场景，避免暂停树阻塞场景切换
		get_tree().paused = false
		SceneManager.change_scene(&"hero_select")
	else:
		get_tree().paused = false
