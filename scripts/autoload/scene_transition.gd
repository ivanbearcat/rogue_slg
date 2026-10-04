extends CanvasLayer

## 场景切换转场（autoload：SceneTransition）
## 马赛克帘子铺满屏幕 → 黑幕中央骰子无限跳动 + 底部"加载中..." → 帘子从中间向两侧拉开露出新场景
## 用法：await SceneTransition.transition_to(&"main", &"stage_start")

const UI_FONT := preload("res://fonts/SourceHanSansCN-Normal.otf")
const DICE_TEXTURE := preload("res://images/ui_icon/PixelDice_White.png")
const MOSAIC_SHADER := preload("res://shaders/mosaic_curtain.gdshader")

## 与 slime_small.tscn 史莱姆身上骰子 "roll" 动画完全一致的 12 帧图集区域（28x28）
const DICE_FRAME_REGIONS: Array[Vector2] = [
	Vector2(28, 0), Vector2(0, 140), Vector2(0, 0), Vector2(28, 140),
	Vector2(140, 0), Vector2(84, 140), Vector2(84, 0), Vector2(56, 140),
	Vector2(112, 0), Vector2(112, 140), Vector2(56, 0), Vector2(140, 140),
]

const COVER_TIME := 0.6     ## 帘子铺满耗时（秒）
const REVEAL_TIME := 0.8    ## 帘子拉开耗时（秒）
const REVEAL_DELAY := 0.3   ## 就绪后拉开前的停顿（秒）
const MAX_WAIT_TIME := 8.0  ## 等待就绪信号最长时间（超时强制拉开）
const DICE_SCALE := 3.0     ## 加载骰子放大倍数（原图 28x28）
const TILE_PX := 24.0       ## 马赛克块尺寸（像素）

var _is_transitioning := false
var _stage_ready := false

var _mosaic_rect: ColorRect
var _material: ShaderMaterial
var _loading_root: Control
var _dice: AnimatedSprite2D
var _label: Label
var _dice_home_y := 0.0
var _hop_tween: Tween
var _dots_tween: Tween

func _ready() -> void:
	layer = 128
	visible = false
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()

## 铺帘 → 加载 → 切场景 → 等就绪信号 → 拉帘；返回新场景实例
func transition_to(view_name: StringName, ready_event: StringName = &"") -> Node:
	if _is_transitioning:
		push_warning("转场进行中，忽略本次切换： " + view_name)
		return null
	_is_transitioning = true
	var scene_path := "res://scenes/%s.tscn" % view_name

	## 1) 马赛克帘子自上而下铺满屏幕（帘面逐步变黑）
	_material.set_shader_parameter("opening", 0.0)
	_material.set_shader_parameter("tile_px", TILE_PX)
	visible = true
	var cover_tween := create_tween()
	cover_tween.tween_method(_set_amount, 0.0, 1.0, COVER_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await cover_tween.finished

	## 2) 黑屏中央：骰子无限跳动 + 底部"加载中..."
	_show_loading(true)

	## 3) 等待目标场景预加载完成（复用调用方已发起的线程预加载）
	var status := ResourceLoader.load_threaded_get_status(scene_path)
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		SceneManager.preload_scene(view_name)
	while ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame

	## 4) 切换场景（资源已入缓存，实例化很快；转场层在 autoload 上不受场景释放影响）
	var new_scene := SceneManager.change_scene(view_name)

	## 5) 等待"战局就绪"信号（stage_start 在 game_manager 初始化链末尾发出）
	if ready_event != &"":
		_stage_ready = false
		EventBus.subscribe(ready_event, _on_stage_ready)
		var deadline := Time.get_ticks_msec() + int(MAX_WAIT_TIME * 1000.0)
		while not _stage_ready and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
		EventBus.unsubscribe(ready_event, _on_stage_ready)
	await get_tree().create_timer(REVEAL_DELAY).timeout

	## 6) 收起加载 UI，帘子从中间向两侧拉开露出新场景
	_show_loading(false)
	_material.set_shader_parameter("opening", 1.0)
	var reveal_tween := create_tween()
	reveal_tween.tween_method(_set_amount, 1.0, 0.0, REVEAL_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await reveal_tween.finished
	visible = false
	_is_transitioning = false
	return new_scene

func _on_stage_ready() -> void:
	_stage_ready = true

func _set_amount(value: float) -> void:
	_material.set_shader_parameter("amount", value)

## ---------- UI 构建 ----------

func _build_ui() -> void:
	## 马赛克帘子：全屏 ColorRect + shader（鼠标 STOP 同时挡住下层点击）
	_material = ShaderMaterial.new()
	_material.shader = MOSAIC_SHADER
	_mosaic_rect = ColorRect.new()
	_mosaic_rect.material = _material
	_mosaic_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_mosaic_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_mosaic_rect)

	## 加载层：中央骰子 + 底部"加载中..."
	_loading_root = Control.new()
	_loading_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_loading_root)

	_dice = _build_dice()
	_loading_root.add_child(_dice)

	_label = Label.new()
	_label.text = "加载中..."
	_label.add_theme_font_override("font", UI_FONT)
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(0.85, 0.88, 1.0))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_label.offset_left = -150
	_label.offset_right = 150
	_label.offset_top = -110
	_label.offset_bottom = -70
	_loading_root.add_child(_label)

## 与史莱姆身上完全相同的骰子 roll 动画（同图集、同 12 帧、同 15fps 循环）
func _build_dice() -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.add_animation(&"roll")
	frames.set_animation_speed(&"roll", 15.0)
	frames.set_animation_loop(&"roll", true)
	for region in DICE_FRAME_REGIONS:
		var atlas := AtlasTexture.new()
		atlas.atlas = DICE_TEXTURE
		atlas.region = Rect2(region.x, region.y, 28.0, 28.0)
		frames.add_frame(&"roll", atlas)
	var dice := AnimatedSprite2D.new()
	dice.sprite_frames = frames
	dice.scale = Vector2(DICE_SCALE, DICE_SCALE)
	return dice

func _layout() -> void:
	var center := get_viewport().get_visible_rect().size * 0.5
	_dice_home_y = center.y - 40.0
	_dice.position = Vector2(center.x, _dice_home_y)
	if _hop_tween != null and _hop_tween.is_running():
		_start_hop()  ## 窗口尺寸变化后以新基准重启跳动

## ---------- 加载 UI 显隐与动画 ----------

func _show_loading(shown: bool) -> void:
	if shown:
		_loading_root.visible = true
		_loading_root.modulate.a = 0.0
		_dice.play(&"roll")
		_start_hop()
		_start_dots()
		create_tween().tween_property(_loading_root, "modulate:a", 1.0, 0.25)
	else:
		## 淡出后再停动画；不 await，让帘子拉开与淡出并行
		var tween := create_tween()
		tween.tween_property(_loading_root, "modulate:a", 0.0, 0.2)
		tween.tween_callback(_stop_loading)

func _stop_loading() -> void:
	_stop_hop()
	_stop_dots()
	_dice.stop()
	_loading_root.visible = false

## 骰子跳动：起跳 → 落地压扁 → 回弹，无限循环
func _start_hop() -> void:
	_stop_hop()
	_hop_tween = create_tween().set_loops()
	_hop_tween.tween_property(_dice, "position:y", _dice_home_y - 30.0, 0.26) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop_tween.tween_property(_dice, "position:y", _dice_home_y, 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_hop_tween.tween_property(_dice, "scale", Vector2(DICE_SCALE * 1.2, DICE_SCALE * 0.8), 0.06)
	_hop_tween.tween_property(_dice, "scale", Vector2(DICE_SCALE * 0.94, DICE_SCALE * 1.06), 0.08)
	_hop_tween.tween_property(_dice, "scale", Vector2(DICE_SCALE, DICE_SCALE), 0.1)
	_hop_tween.tween_interval(0.05)

func _stop_hop() -> void:
	if _hop_tween != null:
		_hop_tween.kill()
		_hop_tween = null
	_dice.scale = Vector2(DICE_SCALE, DICE_SCALE)

## 底部"加载中"点点点循环
func _start_dots() -> void:
	_stop_dots()
	_dots_tween = create_tween().set_loops()
	for i in 4:
		_dots_tween.tween_callback(_set_dots.bind(i))
		_dots_tween.tween_interval(0.35)

func _stop_dots() -> void:
	if _dots_tween != null:
		_dots_tween.kill()
		_dots_tween = null

func _set_dots(count: int) -> void:
	_label.text = "加载中" + ".".repeat(count)
