extends TextureButton

const PRESSED_OFFSET := Vector2(0, 1)  # 下沉像素量

@onready var label: Label = $Label
var _base_pos: Vector2

func _ready() -> void:
	_base_pos = label.position
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_button_down() -> void:
	label.position = _base_pos + PRESSED_OFFSET
	self.offset_transform_scale = Vector2(0.97, 0.97)

func _on_button_up() -> void:
	label.position = _base_pos
	self.offset_transform_scale = Vector2(1, 1)

func _on_mouse_exited() -> void:
	self.offset_transform_scale = Vector2(1, 1)
	self.offset_transform_rotation = 0

func _on_mouse_entered() -> void:
	self.offset_transform_scale = Vector2(1.03, 1.03)
	self.offset_transform_rotation = 0.05
