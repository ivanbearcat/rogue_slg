@tool
extends Node


## Fx — 通用 FX 库的统一入口（autoload）。
## 提供命令式、声明式、持续型、取消四类 API。


var _engine: FxEngine


func _ready() -> void:
	_engine = FxEngine.new()
	_engine.name = "FxEngine"
	add_child(_engine)
	# 运行时注册为 Engine 单例（覆盖编辑器实例，若存在）
	Engine.register_singleton("Fx", self)


func _exit_tree() -> void:
	# 仅当自己是当前注册的单例时才移除
	if Engine.get_singleton("Fx") == self:
		Engine.unregister_singleton("Fx")


# ============================================================
# 声明式 API
# ============================================================

## 按 profile 内的 Spec 顺序依次应用所有特效到 target。
## [param params] 参数字典，用于占位符替换。
func play(target: Node, profile: FxProfile, params: Dictionary = {}) -> void:
	if not is_instance_valid(target) or not profile:
		return
	if profile.effects.is_empty():
		return
	for effect_spec in profile.effects:
		if not effect_spec:
			continue
		_resolve_placeholders(effect_spec, params)
		_apply_effect(target, effect_spec, params)


## 停止目标节点上的特效。
## 不传 effect_name 时停止所有特效；传入 effect_name 时仅停止匹配名称的特效。
func stop(target: Node, effect_name: String = "") -> void:
	if not is_instance_valid(target):
		return
	for child in target.get_children():
		if not child is FxLayer:
			continue
		if effect_name.is_empty():
			child.finish()
		else:
			var layer_spec: FxEffect = child.get("spec")
			if layer_spec and _matches_effect_name(layer_spec, effect_name):
				child.finish()


# ============================================================
# 命令式 API（语法糖，内部构造 Spec 调用 Fx.play）
# ============================================================

## 抖动特效
func shake(target: Node, intensity: float = 10.0, duration: float = 0.2, axes: Vector2 = Vector2(1, 1)) -> void:
	var spec := FxShakeEffect.new()
	spec.intensity = intensity
	spec.duration = duration
	spec.axes = axes
	_play_single(target, spec)


## 浮动文字
func float_text(target: Node, text: String = "{value}", size: int = 24, color: Color = Color.WHITE, rise: float = 50.0, duration: float = 0.8) -> void:
	var spec := FxFloatTextEffect.new()
	spec.text = text
	spec.size = size
	spec.color = color
	spec.rise = rise
	spec.duration = duration
	_play_single(target, spec, {"value": text})


## 屏幕抖动（操作当前视口的 Camera2D）
func screen_shake(intensity: float = 10.0, duration: float = 0.2) -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return
	var spec := FxScreenShakeEffect.new()
	spec.intensity = intensity
	spec.duration = duration
	_play_single(camera, spec)


## 燃烧特效
func burn(target: Node, duration: float = 2.0, intensity: float = 1.0, color: Color = Color(1, 0.6, 0.2)) -> void:
	var spec := FxBurnEffect.new()
	spec.duration = duration
	spec.intensity = intensity
	spec.color = color
	_play_single(target, spec)


## 描边特效
func outline(target: Node, color: Color = Color.WHITE, width: float = 2.0) -> void:
	var spec := FxOutlineEffect.new()
	spec.color = color
	spec.width = width
	_play_single(target, spec)


## 闪烁特效
func blink(target: Node, color: Color = Color.WHITE, frequency: float = 10.0) -> void:
	var spec := FxBlinkEffect.new()
	spec.color = color
	spec.frequency = frequency
	_play_single(target, spec)


## 闪色特效
func flash(target: Node, color: Color = Color.WHITE, duration: float = 0.1) -> void:
	var spec := FxFlashEffect.new()
	spec.color = color
	spec.duration = duration
	_play_single(target, spec)


## 冻帧特效
func freeze_frame(duration: float = 0.1, time_scale: float = 0.05) -> void:
	var spec := FxFreezeFrameEffect.new()
	spec.duration = duration
	spec.time_scale = time_scale
	# 冻帧操作全局 Engine，target 传自身即可
	_play_single(self, spec)


## 溶解特效
func dissolve(target: Node, duration: float = 1.0, edge_color: Color = Color(1, 0.5, 0.0), edge_width: float = 0.05) -> void:
	var spec := FxDissolveEffect.new()
	spec.duration = duration
	spec.edge_color = edge_color
	spec.edge_width = edge_width
	_play_single(target, spec)


## 弹跳缩放特效
func pop(target: Node, scale_size: float = 1.5, duration: float = 0.07) -> void:
	var spec := FxPopEffect.new()
	spec.scale_size = scale_size
	spec.duration = duration
	_play_single(target, spec)


## 淡入特效
func fade_in(target: Node, duration: float = 0.5) -> void:
	var spec := FxFadeEffect.new()
	spec.duration = duration
	spec.mode = 0
	_play_single(target, spec)


## 淡出特效
func fade_out(target: Node, duration: float = 0.5) -> void:
	var spec := FxFadeEffect.new()
	spec.duration = duration
	spec.mode = 1
	_play_single(target, spec)


## 打字机特效
func typewriter(target: Node, content: String = "", duration: float = 1.0) -> void:
	var spec := FxTypewriterEffect.new()
	spec.content = content
	spec.duration = duration
	_play_single(target, spec)


## 数字滚动特效
func number_roll(target: Node, value: int = 0, duration: float = 0.5) -> void:
	var spec := FxNumberRollEffect.new()
	spec.value = value
	spec.duration = duration
	_play_single(target, spec)


## 受击闪红特效
func hurt(target: Node, color: Color = Color.RED, duration: float = 0.1) -> void:
	var spec := FxHurtEffect.new()
	spec.color = color
	spec.duration = duration
	_play_single(target, spec)


## 治疗特效
func heal(target: Node, color: Color = Color.GREEN, duration: float = 0.5, mix_amount: float = 0.7) -> void:
	var spec := FxHealEffect.new()
	spec.color = color
	spec.duration = duration
	spec.mix_amount = mix_amount
	_play_single(target, spec)


## 中毒特效（持续型，需 Fx.stop 取消）
func poison(target: Node, duration: float = 3.0, poison_color: Color = Color(0.3, 1.0, 0.3), pulse_speed: float = 3.0) -> void:
	var spec := FxPoisonEffect.new()
	spec.duration = duration
	spec.poison_color = poison_color
	spec.pulse_speed = pulse_speed
	_play_single(target, spec)


## 冰冻特效（持续型，需 Fx.stop 取消）
func frozen(target: Node, duration: float = 5.0, ice_color: Color = Color(0.5, 0.8, 1.0), crystal_intensity: float = 0.5) -> void:
	var spec := FxFrozenEffect.new()
	spec.duration = duration
	spec.ice_color = ice_color
	spec.crystal_intensity = crystal_intensity
	_play_single(target, spec)


## 石化特效（持续型，需 Fx.stop 取消）
func petrify(target: Node, duration: float = 10.0, stone_color: Color = Color(0.5, 0.5, 0.5), crack_intensity: float = 0.5) -> void:
	var spec := FxPetrifyEffect.new()
	spec.duration = duration
	spec.stone_color = stone_color
	spec.crack_intensity = crack_intensity
	_play_single(target, spec)


# ============================================================
# 战斗粒子 API（一次性 spawn_* + 持续型 create_*）
# ============================================================

## 血溅特效（一次性）
func spawn_blood_splash(target: Node, color: Color = Color(0.8, 0.1, 0.1), amount: int = 20, velocity_min: float = 80.0, velocity_max: float = 150.0) -> void:
	var spec := FxBloodSplashEffect.new()
	spec.color = color
	spec.amount = amount
	spec.velocity_min = velocity_min
	spec.velocity_max = velocity_max
	_play_single(target, spec)


## 能量爆发特效（一次性）
func spawn_energy_burst(target: Node, amount: int = 30, velocity_min: float = 50.0, velocity_max: float = 120.0) -> void:
	var spec := FxEnergyBurstEffect.new()
	spec.amount = amount
	spec.velocity_min = velocity_min
	spec.velocity_max = velocity_max
	_play_single(target, spec)


## 治疗粒子特效（一次性）
func spawn_heal_particles(target: Node, amount: int = 15) -> void:
	var spec := FxHealParticlesEffect.new()
	spec.amount = amount
	_play_single(target, spec)


## 护盾破碎特效（一次性）
func spawn_shield_break(target: Node) -> void:
	_play_single(target, FxShieldBreakEffect.new())


## 连击环特效（一次性）
func spawn_combo_ring(target: Node) -> void:
	_play_single(target, FxComboRingEffect.new())


## 通用战斗粒子特效（一次性）
func spawn_combat_particle(target: Node) -> void:
	_play_single(target, FxCombatParticleEffect.new())


## 跳跃扬尘特效（一次性）
func spawn_jump_dust(target: Node) -> void:
	_play_single(target, FxJumpDustEffect.new())


## 冲刺拖尾特效（持续型，返回节点）
func create_dash_trail(target: Node) -> Node:
	var spec := FxDashTrailEffect.new()
	var profile := FxProfile.new()
	profile.effects.append(spec)
	play(target, profile)
	# 返回粒子节点供调用方管理
	for child in target.get_children():
		if child is FxParticleLayer and child.spec == spec:
			return child
	return null


## 墙壁滑动火花特效（持续型，返回节点）
func create_wall_slide_spark(target: Node) -> Node:
	var spec := FxWallSlideSparkEffect.new()
	var profile := FxProfile.new()
	profile.effects.append(spec)
	play(target, profile)
	for child in target.get_children():
		if child is FxParticleLayer and child.spec == spec:
			return child
	return null


# ============================================================
# 环境特效 API（持续型，全部返回节点不自动 free）
# ============================================================

## 火把火焰特效（持续型）
func create_torch(target: Node) -> Node:
	return _create_env_effect(target, FxTorchFireEffect.new())


## 萤火虫特效（持续型）
func create_fireflies(target: Node) -> Node:
	return _create_env_effect(target, FxFirefliesEffect.new())


## 蒸汽特效（持续型）
func create_steam(target: Node) -> Node:
	return _create_env_effect(target, FxSteamEffect.new())


## 火花特效（持续型）
func create_sparks(target: Node) -> Node:
	return _create_env_effect(target, FxSparksEffect.new())


## 水花溅射特效（持续型）
func create_water_splash(target: Node) -> Node:
	return _create_env_effect(target, FxWaterSplashEffect.new())


## 尘土云特效（持续型）
func create_dust_cloud(target: Node) -> Node:
	return _create_env_effect(target, FxDustCloudEffect.new())


## 魔法光环特效（持续型）
func create_magic_aura(target: Node) -> Node:
	return _create_env_effect(target, FxMagicAuraEffect.new())


## 毒雾特效（持续型）
func create_poison_cloud(target: Node) -> Node:
	return _create_env_effect(target, FxPoisonCloudEffect.new())


## 落叶特效（持续型）
func create_falling_leaves(target: Node) -> Node:
	return _create_env_effect(target, FxFallingLeavesEffect.new())


## 木屑特效（持续型）
func create_wood_debris(target: Node) -> Node:
	return _create_env_effect(target, FxWoodDebrisEffect.new())


## 传送门漩涡特效（持续型）
func create_portal_vortex(target: Node) -> Node:
	return _create_env_effect(target, FxPortalVortexEffect.new())


## 闪电链特效（持续型）
func create_lightning_chain(target: Node) -> Node:
	return _create_env_effect(target, FxLightningChainEffect.new())


## 冰霜特效（持续型）
func create_ice_frost(target: Node) -> Node:
	return _create_env_effect(target, FxIceFrostEffect.new())


## 火球拖尾特效（持续型）
func create_fireball_trail(target: Node) -> Node:
	return _create_env_effect(target, FxFireballTrailEffect.new())


## 召唤阵特效（持续型）
func create_summon_circle(target: Node) -> Node:
	return _create_env_effect(target, FxSummonCircleEffect.new())


## 雨滴特效（持续型）
func create_rain(target: Node) -> Node:
	return _create_env_effect(target, FxRainDropsEffect.new())


## 雪花特效（持续型）
func create_snow(target: Node) -> Node:
	return _create_env_effect(target, FxSnowFlakesEffect.new())


## 瀑布水雾特效（持续型）
func create_waterfall_mist(target: Node) -> Node:
	return _create_env_effect(target, FxWaterfallMistEffect.new())


## 篝火烟雾特效（持续型）
func create_campfire_smoke(target: Node) -> Node:
	return _create_env_effect(target, FxCampfireSmokeEffect.new())


## 烛光特效（持续型）
func create_candle_flame(target: Node) -> Node:
	return _create_env_effect(target, FxCandleFlameEffect.new())


## 灰烬粒子特效（持续型）
func create_ash_particles(target: Node) -> Node:
	return _create_env_effect(target, FxAshParticlesEffect.new())


## 环境特效统一创建辅助（持续型，返回节点）
func _create_env_effect(target: Node, effect_spec: FxParticleEffect) -> Node:
	var profile := FxProfile.new()
	profile.effects.append(effect_spec)
	play(target, profile)
	for child in target.get_children():
		if child is FxParticleLayer and child.spec == effect_spec:
			return child
	return null
func _play_single(target: Node, effect_spec: FxEffect, params: Dictionary = {}) -> void:
	var profile := FxProfile.new()
	profile.effects.append(effect_spec)
	play(target, profile, params)

## 根据Spec类型创建对应的 FxLayer 并挂载到 target。
func _apply_effect(target: Node, effect_spec: FxEffect, params: Dictionary) -> void:
	var layer: FxLayer = null
	if effect_spec is FxShaderEffect:
		# shader 互斥规则：先移除已有的 FxShaderLayer
		_remove_existing_shader_layers(target)
		layer = FxShaderLayer.new()
	elif effect_spec is FxTweenEffect:
		layer = FxTweenLayer.new()
	elif effect_spec is FxParticleEffect:
		layer = FxParticleLayer.new()
	else:
		# 未知 Spec 类型，直接调用 _apply
		effect_spec._apply(target, _engine, params)
		return
	layer.spec = effect_spec
	layer.engine = _engine
	layer.params = params
	layer.name = "FxLayer_" + effect_spec.get_class()
	target.add_child(layer)


## 移除目标节点上已有的 FxShaderLayer（触发 _on_detach 恢复 material）。
func _remove_existing_shader_layers(target: Node) -> void:
	for child in target.get_children():
		if child is FxShaderLayer:
			child.finish()


## 判断 Spec 是否匹配指定的 effect_name。
func _matches_effect_name(spec: FxEffect, effect_name: String) -> bool:
	var spec_class: String = spec.get_class()
	# FxShakeEffect → "shake"
	var short_name: String = spec_class.replace("Fx", "").replace("Effect", "")
	# camelCase → snake_case
	var snake: String = _to_snake_case(short_name)
	return snake == effect_name or short_name.to_lower() == effect_name


func _to_snake_case(s: String) -> String:
	var result: String = ""
	for i in s.length():
		var ch: String = s[i]
		if ch == ch.to_upper() and ch != ch.to_lower() and i > 0:
			result += "_"
		result += ch.to_lower()
	return result


## 对 Spec 的字符串属性做占位符替换。
func _resolve_placeholders(res: Resource, params: Dictionary) -> void:
	if params.is_empty() or not res:
		return
	for prop in res.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		if prop.usage & PROPERTY_USAGE_EDITOR == 0:
			continue
		var current_val: Variant = res.get(prop.name)
		if current_val is String:
			var replaced: Variant = _engine.resolve_placeholder(current_val, params)
			if replaced != current_val:
				res.set(prop.name, replaced)
