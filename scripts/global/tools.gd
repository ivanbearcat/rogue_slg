extends Node

func time_sleep(time):
	await get_tree().create_timer(time).timeout

## 获取史莱姆场景名
func fetch_slime_scene(slime_scene):
	var regex = RegEx.new()
	regex.compile(".*(?<name>slime.*)\\.tscn")
	var result = regex.search(slime_scene.scene_file_path)
	var slime_color = result.get_string("name")
	if slime_color:
		return slime_color
	else:
		return null

## 放大的抖动效果
func big_flow_effect(object):
	var tween = create_tween()
	tween.tween_property(object, "scale:x", 1.5, 0.07)
	tween.parallel().tween_property(object, "pivot_offset:x", 4, 0.07)
	tween.parallel().tween_property(object, "scale:y", 1.5, 0.07)
	tween.parallel().tween_property(object, "pivot_offset:y", 4, 0.07)
	tween.tween_property(object, "scale:x", 1, 0.07)
	tween.parallel().tween_property(object, "pivot_offset:x", 8, 0.07)
	tween.parallel().tween_property(object, "scale:y", 1, 0.07)
	tween.parallel().tween_property(object, "pivot_offset:y", 8, 0.07)
