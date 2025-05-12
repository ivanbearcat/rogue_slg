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
