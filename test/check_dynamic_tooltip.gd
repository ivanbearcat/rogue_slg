extends SceneTree

## 自检：set_dynamic_tooltip 懒格式化语义——悬停时刻（模拟 _on_node_mouse_entered 动态分支）才查表翻译。
## 注意：--script 主脚本在 autoload 全局标识注册前编译，禁止在编译期引用
## 全局类（如 TooltipFormatter/BuffSystem），一律运行时 load() 解析；
## Callable 对 RefCounted 持弱引用，实例须存局部变量保活（生产路径绑定 Script 资源无此问题）。

## family 留空：避开 BuffSystem 运行时状态（裸 headless 未开局，pre_attack 未初始化）
const FAKE_BUFF := {"buff_name": "潮涌", "buff_tooltip": "测试描述", "family": "", "tags": []}

func _initialize() -> void:
	var tm: Node = root.get_node_or_null("TooltipManager")
	if tm == null:
		print("RESULT: FAIL (autoload TooltipManager not found)")
		quit(1)
		return
	var tf: RefCounted = load("res://scripts/tooltip_formatter.gd").new()  # 保活引用
	var formatter: Callable = Callable(tf, "format_buff")
	var node := Control.new()
	root.add_child(node)
	tm.set_dynamic_tooltip(node, FAKE_BUFF, formatter)
	var data: Dictionary = tm._tooltip_data[node]
	if not data.has("formatter"):
		print("RESULT: FAIL (no formatter in _tooltip_data)")
		quit(1)
		return
	TranslationServer.set_locale("en")
	var text_en: String = data["formatter"].call(data["source"])
	if not text_en.contains("Tide"):
		print("RESULT: FAIL en → ", text_en.left(60))
		quit(1)
		return
	TranslationServer.set_locale("ja")
	var text_ja: String = data["formatter"].call(data["source"])
	if not text_ja.contains("潮流"):
		print("RESULT: FAIL ja → ", text_ja.left(60))
		quit(1)
		return
	## 旧 set_tooltip(String) 静态形态行为不变
	tm.set_tooltip(node, "静态文本")
	var static_data: Dictionary = tm._tooltip_data[node]
	if static_data.get("text", "") != "静态文本" or static_data.has("formatter"):
		print("RESULT: FAIL static form")
		quit(1)
		return
	## _colorize_numbers 正则缓存路径：+5 仍被绿色包裹（缓存命中，行为不变）
	var colored: String = tf._colorize_numbers("攻击+5", "buff")
	if not colored.contains("[color=#0fff5b]"):
		print("RESULT: FAIL colorize → ", colored)
		quit(1)
		return
	print("RESULT: PASS")
	quit(0)
