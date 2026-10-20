extends Node2D
## 主菜单鼠标视差：把鼠标偏移当作虚拟相机位移，喂给各 Parallax2D 的 screen_offset

## 虚拟相机最大位移（px）。鼠标移到屏幕边缘时达到该值 × 各层深度
@export var amplitude := Vector2(10.0, 3.0)
## 平滑速度：越大跟得越紧，6~10 手感较好
@export var smooth_speed := 7.0
## true = 相机式（鼠标右移 → 图层左移）；false = 注视式（同向）
@export var invert := false
## 深度系数，远 → 近递增；顺序 = ParallaxRoot 下的子节点顺序
@export var depths: Array[float] = [0.0, 0.0, 0.0, 0.0, 1.0]
## 参与自动漂移的层索引（按 ParallaxRoot 下顺序，云层是第 2 个 → 填 [1]）
@export var drift_layers: Array[int] = [1]

var _layers: Array[Parallax2D] = []
var _current := Vector2.ZERO

func _ready() -> void:
	for child in get_children():
		if child is Parallax2D:
			_layers.append(child)
	assert(_layers.size() == depths.size(), "图层数与 depths 数量不一致")

func _process(delta: float) -> void:
	var vp_size := get_viewport_rect().size
	var mouse := get_viewport().get_mouse_position()
	# 归一化鼠标偏移，范围 (-0.5, 0.5)
	var target := (mouse - vp_size * 0.5) / vp_size
	# 指数平滑，避免抖动
	_current = _current.lerp(target, clampf(smooth_speed * delta, 0.0, 1.0))

	var sign_f := -1.0 if invert else 1.0
	var base := _current * amplitude * sign_f
	for i in _layers.size():
		if i in drift_layers:      # 自动层交给引擎，跳过
			continue
		_layers[i].scroll_offset = base * depths[i]
