extends Node

## game_manager节点
@onready var game_manager: Node2D = get_node("/root/game_manager")

func time_sleep(time):
	await get_tree().create_timer(time).timeout

func grid_index_to_position(grid_index: Vector2) -> Vector2:
	return Vector2i(grid_index.x * game_manager.grid_size.x + game_manager.start_pos.x, \
	grid_index.y * game_manager.grid_size.y + game_manager.start_pos.y)

func position_to_grid_index(_position: Vector2) -> Vector2:
	return Vector2i((_position.x - game_manager.start_pos.x) / game_manager.grid_size.x, \
	(_position.y - game_manager.start_pos.y) / game_manager.grid_size.y)

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


## 加载json配置文件
func load_json_file(file_path: String) -> Array:
	## 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		print("JSON 文件不存在:", file_path)
		return []
	## 读取文件内容
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("无法打开文件:", FileAccess.get_open_error())
		return []
	var json_string = file.get_as_text()
	file.close()
	## 解析 JSON
	var parse_result = JSON.parse_string(json_string)
	if not parse_result:
		print("JSON 解析失败！错误代码:", parse_result)
		return []
	return parse_result  # 返回 Dictionary

## 阿拉伯数字转中文数字
var num_to_cnnum: Dictionary = {
	1: "一",
	2: "二",
	3: "三",
	4: "四",
	5: "五",
	6: "六",
	7: "七",
	8: "八",
	9: "九",
	10: "十",
	11: "十一",
	12: "十二"
}
