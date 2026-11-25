extends SceneTree
## 特效 autoload 治理看守（effect-library-governance「特效类 autoload 纪律」，
## consolidate-effect-libraries task 4.1）
## 用法: godot --headless --path . --script res://test/scripts/effect/effect_autoload_governance_test.gd
##
## 长期看守目标（design 风险项：未来有人重新启用 fx/vfx_library 插件导致
## autoload 回挂，本断言拦截）：
##  1. project.godot [autoload] 特效入口仅 EffectManager，无 VFX / EnvVFX / Fx
##  2. 运行时 root 的特效单例仅 EffectManager（启动加载面干净，零调用特效库不驻留内存）
##  3. [editor_plugins] enabled 清单无 vfx_library / fx（防插件重启用回挂）
##  4. 游戏代码 scripts/、scenes/ 零外部特效库入口引用（收口断言）

var _total: int = 0
var _passed: int = 0
var _failed: int = 0
var _errors: Array = []

## 特效类 autoload 白名单/黑名单（外部特效库的已知入口名单，新增特效入口
## 应移植进 EffectManager 而非新增 autoload——违反会被断言 1/2 拦截）
const EFFECT_AUTOLOAD_ALLOWED := ["EffectManager"]
const EFFECT_AUTOLOAD_FORBIDDEN := ["VFX", "EnvVFX", "Fx"]
## 黑名单插件的 cfg 路径片段（enabled 清单零匹配）
const FORBIDDEN_PLUGINS := ["addons/vfx_library/plugin.cfg", "addons/fx/plugin.cfg"]

func _init():
	await process_frame
	run_all_tests()
	quit(1 if _failed > 0 else 0)

func run_all_tests() -> void:
	print("\n==================================================")
	print("  Effect Autoload Governance Test (Headless)")
	print("==================================================")

	## 1. 静态：project.godot [autoload] 特效入口仅 EffectManager
	for name in EFFECT_AUTOLOAD_ALLOWED:
		_check("[autoload] 特效入口 %s 存在" % name, ProjectSettings.has_setting("autoload/" + name))
	for name in EFFECT_AUTOLOAD_FORBIDDEN:
		_check("[autoload] 无 %s（外部特效库入口已卸除）" % name,
			not ProjectSettings.has_setting("autoload/" + name))

	## 2. 运行时：root 特效单例仅 EffectManager（启动后加载面干净）
	for name in EFFECT_AUTOLOAD_ALLOWED:
		var node := root.get_node_or_null(name)
		_check("启动后运行时单例 %s 在跑" % name, node != null)
	for name in EFFECT_AUTOLOAD_FORBIDDEN:
		_check("启动后运行时无 %s 实例（零调用特效库不驻留内存）" % name, root.get_node_or_null(name) == null)

	## 3. enabled 插件清单无特效库插件（防重启用回挂）
	var enabled: Variant = ProjectSettings.get_setting("editor_plugins/enabled", PackedStringArray())
	for plugin in FORBIDDEN_PLUGINS:
		var found := false
		for entry in enabled:
			if String(entry).contains(plugin):
				found = true
		_check("enabled 插件清单无 %s" % plugin, not found)

	## 4. 游戏代码零外部特效库入口引用（scripts/ + scenes/ 收口断言）
	var stray: Array = []
	_scan_dir("res://scripts", stray)
	_scan_dir("res://scenes", stray)
	_check("scripts/ 与 scenes/ 零外部特效库入口引用（VFX./EnvVFX./Fx. 调用）", stray.is_empty())
	for s in stray:
		_errors.append("外部特效库引用: %s" % s)

	print("\n==================================================")
	print("  Total: %d | Passed: %d | Failed: %d" % [_total, _passed, _failed])
	if _errors.size() > 0:
		print("  --- Failed ---")
		for err in _errors:
			print("  %s" % err)
	print("==================================================")

## 递归扫描 .gd/.tscn 文件的外部特效库入口调用（VFX./EnvVFX./Fx. 形态）
func _scan_dir(dir_path: String, out: Array) -> void:
	var da := DirAccess.open(dir_path)
	if da == null:
		return
	da.list_dir_begin()
	var name := da.get_next()
	while name != "":
		var full := dir_path + "/" + name
		if da.current_is_dir():
			if not name.begins_with("."):
				_scan_dir(full, out)
		elif name.ends_with(".gd") or name.ends_with(".tscn"):
			var src := FileAccess.get_file_as_string(full)
			## 入口调用形态：VFX. / EnvVFX. / Fx.（如 EnvVFX.create_fireflies）；
			## EffectManager 合法；vfx_library 路径由 uid/路径双口径复扫另行看守
			for entry in ["VFX.", "EnvVFX.", "Fx."]:
				if src.contains(entry):
					out.append("%s [%s]" % [full, entry])
		name = da.get_next()
	da.list_dir_end()

func _check(name: String, ok: bool) -> void:
	_total += 1
	if ok:
		_passed += 1
		print("  PASS: %s" % name)
	else:
		_failed += 1
		_errors.append(name)
		print("  FAIL: %s" % name)
