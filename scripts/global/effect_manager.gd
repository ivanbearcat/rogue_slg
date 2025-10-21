extends Node

var _content: String
var _object: Object

## 把图片对象快速放大恢复的效果
func big_flow_effect(object, scale_size=1.5, duration=0.07):
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	## 放大
	tween.tween_property(object, "pivot_offset:x", object.size.x/2, 0)
	tween.tween_property(object, "pivot_offset:y", object.size.y/1.5, 0)
	tween.tween_property(object, "scale:x", scale_size, duration)
	tween.parallel().tween_property(object, "scale:y", scale_size, duration)
	## 缩小
	tween.tween_property(object, "scale:x", 1, duration/1.5)
	tween.parallel().tween_property(object, "scale:y", 1, duration/1.5)
	await tween.finished
	tween.tween_property(object, "pivot_offset:x", 0, 0)
	tween.tween_property(object, "pivot_offset:y", 0, 0)
	
## 飘字效果
func float_number_effect(float_num, gravity=Vector2(0, 75), velocity=Vector2(randi_range(-10,10), -50)) -> Node2D:
	var float_number_instantiate = SceneManager.create_scene("float_number")
	float_number_instantiate.float_num = float_num
	float_number_instantiate.gravity = gravity
	float_number_instantiate.velocity = velocity
	return float_number_instantiate

## 设置数字并滚动
func label_num_rolling_effect(object, value, sync=1):
	_object = object
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(label_num_rolling_update_text, int(_object.text), value, 0.5)
	if sync:
		await tween.finished
func label_num_rolling_update_text(value):
	_object.text = str(value)
	EffectManager.big_flow_effect(_object)
	

## 打字机效果
func typewriter_effect(object, content, duration, sync=1):
	_object = object
	_content = content
	_object.text = ""
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(_typewriter_update_text, 0.0, 1.0, duration)
	if sync:
		await tween.finished
func _typewriter_update_text(progress: float):
	var total_chars = _content.length()
	var visible_chars = int(total_chars * progress)
	_object.text = _content.substr(0, visible_chars)
	
## 淡入效果
func fade_in_effect(object, duration, sync=1):
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(object, "modulate:a", 0, 0)
	tween.tween_property(object, "modulate:a", 1, duration)
	if sync:
		await tween.finished

## 上部进入
func top_to_bottom_effect(object, duration, sync=1):
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var size_y = object.size.y
	var postion_y = object.position.y
	tween.tween_property(object, "position:y", -size_y, 0)
	tween.tween_property(object, "position:y", postion_y+postion_y*0.2, duration)
	tween.tween_property(object, "position:y", postion_y, duration*0.2)
	if sync:
		await tween.finished
