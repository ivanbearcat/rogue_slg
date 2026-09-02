extends Control

## 英雄选择画面：展示英雄图，确认后进入战局
const UI_FONT := preload("res://fonts/SourceHanSansCN-Normal.otf")
const TITLE_FONT := preload("res://fonts/SourceHanSansCN-Bold.otf")
## 本期仅 soldier 一个可选英雄（对应 game_manager.hero_property 的键）
const HERO_ID := "soldier"

## 切换锁：防止等待预加载期间重复点击触发多次场景切换
var _is_switching := false

func _ready() -> void:
	## 战局场景较大，进入本画面时后台预加载，确认切换不卡帧
	SceneManager.preload_scene(&"main")
	$Title.add_theme_font_override("font", TITLE_FONT)
	$CenterContainer/HeroCard/hero_name.add_theme_font_override("font", UI_FONT)
	$CenterContainer/HeroCard/confirm_button.add_theme_font_override("font", UI_FONT)
	$CenterContainer/HeroCard/confirm_button.add_theme_font_size_override("font_size", 24)
	$CenterContainer/HeroCard/confirm_button.pressed.connect(_on_confirm_pressed)

func _on_confirm_pressed() -> void:
	if _is_switching:
		return
	_is_switching = true
	Current.selected_hero = HERO_ID
	print("选定英雄： " + HERO_ID)
	## 遥测:run 生命周期起点(英雄确认进入战局)
	EventBus.event_emit("run_start", [HERO_ID])
	## 即时反馈：禁用按钮并显示加载状态（等待预加载期间无响应的问题由此消除）
	var confirm_button: Button = $CenterContainer/HeroCard/confirm_button
	confirm_button.disabled = true
	confirm_button.text = "加载中..."
	await SceneManager.change_scene_preloaded(&"main")
