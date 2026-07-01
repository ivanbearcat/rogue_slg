extends Node

## game_manager节点
@onready var game_manager: Node2D = get_node("/root/game_manager")

## 缓存编译后的正则（D5：避免每次调用重新编译）
var _slime_regex: RegEx

## 史莱姆场景名→颜色映射
const SLIME_COLOR_DICT := {
	"slime_small": "green",
	"slime_small_red": "red",
	"slime_small_yellow": "yellow",
	"slime_small_blue": "blue",
}

func time_sleep(time):
	await get_tree().create_timer(time).timeout

func grid_index_to_position(grid_index: Vector2) -> Vector2:
	return Vector2i(grid_index.x * game_manager.grid_size.x + game_manager.start_pos.x, \
	grid_index.y * game_manager.grid_size.y + game_manager.start_pos.y)

func position_to_grid_index(_position: Vector2) -> Vector2:
	return Vector2i((_position.x - game_manager.start_pos.x) / game_manager.grid_size.x, \
	(_position.y - game_manager.start_pos.y) / game_manager.grid_size.y)

## 获取史莱姆场景名（首次调用编译并缓存正则，后续复用）
func fetch_slime_scene(slime_scene):
	if _slime_regex == null:
		_slime_regex = RegEx.new()
		_slime_regex.compile(".*(?<name>slime.*)\\.tscn")
	var result = _slime_regex.search(slime_scene.scene_file_path)
	if result:
		return result.get_string("name")
	else:
		return null

## 获取攻击范围内被击杀史莱姆的颜色数组（D1：统一颜色判定范围）
## 在 skill_system.gd 攻击结算时填充，post_attack buff 读取
func get_colors_in_attack_range() -> Array:
	return Current.killed_slime_colors

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
