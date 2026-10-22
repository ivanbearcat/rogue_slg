extends Control

## 开始画面：一列按钮（开始/继续/设置/历史/退出），基础测试用
const UI_FONT := preload("res://fonts/SourceHanSansCN-Normal.otf")
const TITLE_FONT := preload("res://fonts/SourceHanSansCN-Bold.otf")

## 切换锁：防止重复点击触发多次场景切换
var _is_switching := false

func _ready() -> void:
	## 中文字体（Godot 内置字体不含 CJK 字形）
	$Title.add_theme_font_override("font", TITLE_FONT)
	for button in $ButtonColumn.get_children():
		button.add_theme_font_override("font", UI_FONT)
		button.add_theme_font_size_override("font_size", 24)
	$ButtonColumn/start_button.pressed.connect(_on_start_pressed)
	$ButtonColumn/continue_button.pressed.connect(_on_continue_pressed)
	$ButtonColumn/settings_button.pressed.connect(_on_settings_pressed)
	$ButtonColumn/history_button.pressed.connect(_on_history_pressed)
	$ButtonColumn/quit_button.pressed.connect(_on_quit_pressed)
	_gating_continue_button()

## "继续"门控（design D6）：有可用存档（完整性校验通过）才启用，
## 并在按钮上展示存档进度（关卡/回合）；无档或坏档 → 禁用置灰
func _gating_continue_button() -> void:
	var continue_button: TextureButton = $ButtonColumn/continue_button
	var label: Label = continue_button.get_node("Label")
	if not SaveManager.has_valid_save():
		continue_button.disabled = true
		continue_button.modulate = Color(0.5, 0.5, 0.5, 1)
		label.text = tr("继续游戏")
		return
	var progress := SaveManager.get_save_progress()
	continue_button.disabled = false
	continue_button.modulate = Color(1, 1, 1, 1)
	label.text = "%s\n%s %d · %s %d" % [
		tr("继续游戏"), tr("关卡"), progress["stage"], tr("回合"), progress["round"]]

func _on_start_pressed() -> void:
	if _is_switching:
		return
	_is_switching = true
	SceneManager.change_scene(&"hero_select")

func _on_continue_pressed() -> void:
	## 点击"继续"：重新解码（防御 _ready 后存档被外部改动）→ 挂载读档数据 →
	## 置恢复标记 → 直接进战局（不经过英雄选择等前置画面）
	if _is_switching:
		return
	if not SaveManager.has_valid_save():
		_gating_continue_button()
		return
	var data := SaveManager.read_save_data()
	if data.is_empty():
		## 坏档（极端竞态：校验通过后文件被改）：走失败分支禁用
		_gating_continue_button()
		return
	_is_switching = true
	Current.selected_hero = str(data.get("meta", {}).get("hero", "soldier"))
	SaveManager.begin_restore(data)
	## 战局场景较大，切场前后台预加载
	SceneManager.preload_scene(&"main")
	await SceneTransition.transition_to(&"main", &"stage_start")

func _on_settings_pressed() -> void:
	EventBus.event_emit('setting_ui', ['show'])

func _on_history_pressed() -> void:
	print("历史：尚未实现")

func _on_quit_pressed() -> void:
	get_tree().quit()
