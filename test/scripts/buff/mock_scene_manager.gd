extends Node
## MockSceneManager - 替代 SceneManager autoload 用于测试

func create_scene(scene_type: String) -> MockTextureRect:
	var scene = MockTextureRect.new()
	return scene

## ============================================================
## Mock TextureRect
## ============================================================
class MockTextureRect extends RefCounted:
	var texture = null
	var tooltip_text: String = ""
	var modulate: Color = Color(1, 1, 1, 1)
	var visible: bool = true
	var position: Vector2 = Vector2.ZERO

	func queue_free() -> void:
		visible = false
