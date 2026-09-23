extends TextureButton

const PRESSED_OFFSET := Vector2(0, 1)  # 下沉像素量

@onready var label: Label = $Label
var _base_pos: Vector2

func _ready() -> void:
	_base_pos = label.position
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_button_down() -> void:
	label.position = _base_pos + PRESSED_OFFSET

func _on_button_up() -> void:
	label.position = _base_pos
