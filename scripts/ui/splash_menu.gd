extends Control

## 开始画面：一列按钮（开始/继续/设置/历史/退出），基础测试用
const UI_FONT := preload("res://fonts/SourceHanSansCN-Normal.otf")
const TITLE_FONT := preload("res://fonts/SourceHanSansCN-Bold.otf")

## 切换锁：防止重复点击触发多次场景切换
var _is_switching := false

func _ready() -> void:
	## 中文字体（Godot 内置字体不含 CJK 字形）
	$Title.add_theme_font_override("font", TITLE_FONT)
	for button in $CenterContainer/ButtonColumn.get_children():
		button.add_theme_font_override("font", UI_FONT)
		button.add_theme_font_size_override("font_size", 24)
	$CenterContainer/ButtonColumn/start_button.pressed.connect(_on_start_pressed)
	$CenterContainer/ButtonColumn/continue_button.pressed.connect(_on_continue_pressed)
	$CenterContainer/ButtonColumn/settings_button.pressed.connect(_on_settings_pressed)
	$CenterContainer/ButtonColumn/history_button.pressed.connect(_on_history_pressed)
	$CenterContainer/ButtonColumn/quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	if _is_switching:
		return
	_is_switching = true
	SceneManager.change_scene(&"hero_select")

func _on_continue_pressed() -> void:
	print("继续：存档系统尚未实现")

func _on_settings_pressed() -> void:
	print("设置：尚未实现")

func _on_history_pressed() -> void:
	print("历史：尚未实现")

func _on_quit_pressed() -> void:
	get_tree().quit()
