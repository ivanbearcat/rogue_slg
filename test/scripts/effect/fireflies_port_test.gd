extends SceneTree
## 萤火虫移植回归（consolidate-effect-libraries task 1.1 / 1.2 / 1.3）
## 用法: godot --headless --path . --script res://test/scripts/effect/fireflies_port_test.gd
##
## 覆盖：
##  1.（1.1）scenes/fireflies.tscn 可独立实例化，粒子参数与移植源场景逐字段一致
##     （期望值自移植源逐字段抄录硬编码，删除插件目录后本测试仍可长期运行）
##  2.（1.2）EffectManager.create_fireflies 等价实现：挂载位置 / 发射区域 / 返回值
##  3.（1.2）怪癖保真：英雄坐标传入 area_size 语义参数 → 发射区域 = 坐标/2
##  4.（1.3）升级演出时序：飘字与萤火虫同刻触发（同帧挂载）、演出结束同刻销毁、
##     锁释放；progression-sfx「升级飘字与萤火虫同刻」视觉保持
##  5.（1.3）收口源码扫描：effect_manager.gd 零外部特效库入口（EnvVFX/VFX/Fx）引用
##
## autoload 编译期不可见（--script 模式）：运行时经 root.get_node 取用

var _total: int = 0
var _passed: int = 0
var _failed: int = 0
var _errors: Array = []

func _init():
	await process_frame
	await run_all_tests()
	quit(1 if _failed > 0 else 0)

func _fx() -> Node:
	return root.get_node("EffectManager")

func run_all_tests() -> void:
	print("\n==================================================")
	print("  Fireflies Port Test (Headless)")
	print("==================================================")

	_test_scene_ported()
	_test_create_fireflies()
	await _test_level_up_effect()
	_test_source_scan()

	print("\n==================================================")
	print("  Total: %d | Passed: %d | Failed: %d" % [_total, _passed, _failed])
	if _errors.size() > 0:
		print("  --- Failed ---")
		for err in _errors:
			print("  %s" % err)
	print("==================================================")

## 1. 场景独立实例化 + 移植源逐字段参数（1.1）
func _test_scene_ported() -> void:
	var packed: PackedScene = load("res://scenes/fireflies.tscn")
	_check("fireflies.tscn 可加载", packed != null)
	if packed == null:
		return
	var particles: CPUParticles2D = packed.instantiate()
	_check("fireflies 场景可独立实例化为 CPUParticles2D", particles != null)
	if particles == null:
		return
	## 纹理有效（images/firefly.png 经导入系统可用）
	_check("纹理引用有效（res://images/firefly.png）", particles.texture != null)
	## 移植源参数逐字段断言（与移植源场景逐字段一致，仅纹理路径差异）
	_check("amount=20", particles.amount == 20)
	_check("lifetime=3.0", is_equal_approx(particles.lifetime, 3.0))
	_check("preprocess=2.0", is_equal_approx(particles.preprocess, 2.0))
	_check("randomness=0.5", is_equal_approx(particles.randomness, 0.5))
	_check("emission_shape=2（移植源原值）", particles.emission_shape == 2)
	_check("emission_sphere_radius=1.0", is_equal_approx(particles.emission_sphere_radius, 1.0))
	_check("direction=(0,0)", particles.direction == Vector2.ZERO)
	_check("spread=180", is_equal_approx(particles.spread, 180.0))
	_check("gravity=(0,0)", particles.gravity == Vector2.ZERO)
	_check("initial_velocity 10..30",
		is_equal_approx(particles.initial_velocity_min, 10.0)
		and is_equal_approx(particles.initial_velocity_max, 30.0))
	_check("scale_amount_min=0.5", is_equal_approx(particles.scale_amount_min, 0.5))
	_check("blend_mode=1（加法混合）",
		particles.material is CanvasItemMaterial
		and (particles.material as CanvasItemMaterial).blend_mode == 1)
	_check("color_ramp 三点黄萤渐变", particles.color_ramp != null and (particles.color_ramp as Gradient).colors.size() == 3)
	particles.queue_free()

## 2. create_fireflies 等价实现：挂载 / 发射区域 / 返回值（1.2）
func _test_create_fireflies() -> void:
	var fx: Node = _fx()
	var parent := Node2D.new()
	root.add_child(parent)
	var fireflies: CPUParticles2D = fx.create_fireflies(parent, Vector2(200, 100))
	_check("create_fireflies 返回 CPUParticles2D", fireflies is CPUParticles2D)
	_check("挂载到传入 parent", fireflies != null and fireflies.get_parent() == parent)
	_check("发射区域 = area_size/2（移植源同款语义）",
		fireflies != null and fireflies.emission_rect_extents == Vector2(100, 50))
	if fireflies != null:
		fireflies.queue_free()

	## 3. 怪癖保真：坐标传入 area_size 语义位 → 发射区域 = 坐标/2（随站位漂移，design D3）
	var hero_pos := Vector2(72, 71)
	var quirk: CPUParticles2D = fx.create_fireflies(parent, hero_pos)
	_check("怪癖保真：坐标传入 area_size → emission_rect_extents = 坐标/2",
		quirk != null and quirk.emission_rect_extents == hero_pos / 2)
	if quirk != null:
		quirk.queue_free()
	parent.queue_free()

## 4. 升级演出时序（1.3）：同刻触发 / 销毁时序 / 锁释放
func _test_level_up_effect() -> void:
	var fx: Node = _fx()
	var current: Node = root.get_node("Current")

	## 真实 hero.tscn 实例（animated_sprite_2d 路径与战局一致）
	var hero: Node2D = (load("res://scenes/hero.tscn") as PackedScene).instantiate()
	if hero == null:
		_check("hero.tscn 实例化", false)
		return
	hero.hero_name = "soldier"
	root.add_child(hero)
	await process_frame
	await process_frame
	var sprite: AnimatedSprite2D = hero.animated_sprite_2d
	_check("hero.tscn 实例化（animated_sprite_2d 就绪）", sprite != null)
	if sprite == null:
		hero.queue_free()
		return
	## 非零站位让怪癖断言不平凡（发射区域随站位漂移）
	sprite.position = Vector2(72, 71)
	current.hero = hero

	fx.level_up_effect(sprite)
	await process_frame
	## 同刻触发：同一帧内飘字与萤火虫均挂到英雄精灵下（progression-sfx 视觉保持）
	var fireflies: CPUParticles2D = null
	var label: Node = null
	for child in sprite.get_children():
		if child is CPUParticles2D:
			fireflies = child
		elif child is Label:
			label = child
	_check("飘字与萤火虫同刻触发（同帧挂载到英雄精灵）", fireflies != null and label != null)
	_check("萤火虫锚定英雄精灵（挂载位置与移植前一致）",
		fireflies != null and fireflies.get_parent() == sprite)
	_check("萤火虫发射区域 = 英雄站位/2（怪癖保真）",
		fireflies != null and fireflies.emission_rect_extents == Vector2(36, 35.5))

	## 销毁时序：0.9s 演出结束后飘字与萤火虫同刻销毁
	await create_timer(1.3, true).timeout
	var fireflies_gone: bool = fireflies == null or not is_instance_valid(fireflies) \
		or fireflies.is_queued_for_deletion() or not fireflies.is_inside_tree()
	var label_gone: bool = label == null or not is_instance_valid(label) \
		or label.is_queued_for_deletion() or not label.is_inside_tree()
	_check("演出结束后萤火虫销毁", fireflies_gone)
	_check("演出结束后飘字销毁", label_gone)
	_check("level_up_effect 锁释放", not ("level_up_effect" in current.public_lock_array))

	current.hero = null
	hero.queue_free()
	await process_frame

## 5. 收口源码扫描：effect_manager 零外部特效库入口引用（1.3 / effect-library-governance）
func _test_source_scan() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/autoload/effect_manager.gd")
	_check("effect_manager.gd 零 EnvVFX 引用", not src.contains("EnvVFX"))
	_check("effect_manager.gd 零 VFX 调用", not src.contains("VFX."))
	_check("effect_manager.gd 零 Fx 调用", not src.contains("Fx."))

func _check(name: String, ok: bool) -> void:
	_total += 1
	if ok:
		_passed += 1
		print("  PASS: %s" % name)
	else:
		_failed += 1
		_errors.append(name)
		print("  FAIL: %s" % name)
