extends TextureRect

## RichTooltip脚本组件
## 挂载到Control节点上，提供set_rich_tooltip()方法
## 自动监听mouse_enter/mouse_exit信号调用TooltipManager显示/隐藏BBCode tooltip

var _rich_tooltip_text: String = ""

## 设置BBCode tooltip内容
func set_rich_tooltip(bbcode_text: String) -> void:
	_rich_tooltip_text = bbcode_text

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if not _rich_tooltip_text.is_empty():
		TooltipManager.show_tooltip(self, _rich_tooltip_text)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()
