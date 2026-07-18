extends Node


## Showcase — Fx Library 演示场景控制器。
## 提供按钮回调，点击触发对应特效。


@onready var preview_node: Node = $PreviewNode


# ============================================================
# Tween 特效按钮回调
# ============================================================

func _on_shake_pressed() -> void:
	Fx.shake(preview_node)


func _on_float_text_pressed() -> void:
	Fx.float_text(preview_node, "+999")


func _on_screen_shake_pressed() -> void:
	Fx.screen_shake()


# ============================================================
# Shader 特效按钮回调
# ============================================================

func _on_burn_pressed() -> void:
	Fx.burn(preview_node)


func _on_outline_pressed() -> void:
	Fx.outline(preview_node)


func _on_blink_pressed() -> void:
	Fx.blink(preview_node)


# ============================================================
# 补充 Tween 特效按钮回调
# ============================================================

func _on_flash_pressed() -> void:
	Fx.flash(preview_node)


func _on_freeze_frame_pressed() -> void:
	Fx.freeze_frame()


func _on_pop_pressed() -> void:
	Fx.pop(preview_node)


func _on_fade_in_pressed() -> void:
	Fx.fade_in(preview_node)


func _on_fade_out_pressed() -> void:
	Fx.fade_out(preview_node)


func _on_typewriter_pressed() -> void:
	# 需要一个 Label 目标，临时创建
	var label := Label.new()
	label.text = ""
	label.position = preview_node.position if preview_node is Node2D else Vector2.ZERO
	label.add_theme_font_size_override("font_size", 24)
	preview_node.get_parent().add_child(label)
	Fx.typewriter(label, "Hello, Fx!", 1.0)


func _on_number_roll_pressed() -> void:
	var label := Label.new()
	label.text = "0"
	label.position = preview_node.position if preview_node is Node2D else Vector2.ZERO
	label.add_theme_font_size_override("font_size", 24)
	preview_node.get_parent().add_child(label)
	Fx.number_roll(label, 999, 0.5)


# ============================================================
# 补充 Shader 特效按钮回调
# ============================================================

func _on_dissolve_pressed() -> void:
	Fx.dissolve(preview_node)


func _on_hurt_pressed() -> void:
	Fx.hurt(preview_node)


func _on_heal_pressed() -> void:
	Fx.heal(preview_node)


func _on_poison_pressed() -> void:
	Fx.poison(preview_node)


func _on_frozen_pressed() -> void:
	Fx.frozen(preview_node)


func _on_petrify_pressed() -> void:
	Fx.petrify(preview_node)


# ============================================================
# 战斗粒子按钮回调
# ============================================================

func _on_blood_splash_pressed() -> void:
	Fx.spawn_blood_splash(preview_node)


func _on_energy_burst_pressed() -> void:
	Fx.spawn_energy_burst(preview_node)


func _on_heal_particles_pressed() -> void:
	Fx.spawn_heal_particles(preview_node)


func _on_shield_break_pressed() -> void:
	Fx.spawn_shield_break(preview_node)


func _on_combo_ring_pressed() -> void:
	Fx.spawn_combo_ring(preview_node)


func _on_combat_particle_pressed() -> void:
	Fx.spawn_combat_particle(preview_node)


func _on_jump_dust_pressed() -> void:
	Fx.spawn_jump_dust(preview_node)


func _on_dash_trail_pressed() -> void:
	Fx.create_dash_trail(preview_node)


func _on_wall_slide_spark_pressed() -> void:
	Fx.create_wall_slide_spark(preview_node)


# ============================================================
# 环境特效按钮回调
# ============================================================

func _on_torch_pressed() -> void:
	Fx.create_torch(preview_node)

func _on_fireflies_pressed() -> void:
	Fx.create_fireflies(preview_node)

func _on_steam_pressed() -> void:
	Fx.create_steam(preview_node)

func _on_sparks_pressed() -> void:
	Fx.create_sparks(preview_node)

func _on_rain_pressed() -> void:
	Fx.create_rain(preview_node)

func _on_snow_pressed() -> void:
	Fx.create_snow(preview_node)

func _on_magic_aura_pressed() -> void:
	Fx.create_magic_aura(preview_node)

func _on_poison_cloud_pressed() -> void:
	Fx.create_poison_cloud(preview_node)

func _on_falling_leaves_pressed() -> void:
	Fx.create_falling_leaves(preview_node)

func _on_portal_pressed() -> void:
	Fx.create_portal_vortex(preview_node)

func _on_lightning_pressed() -> void:
	Fx.create_lightning_chain(preview_node)

func _on_ice_frost_pressed() -> void:
	Fx.create_ice_frost(preview_node)

func _on_summon_pressed() -> void:
	Fx.create_summon_circle(preview_node)

func _on_campfire_pressed() -> void:
	Fx.create_campfire_smoke(preview_node)

func _on_candle_pressed() -> void:
	Fx.create_candle_flame(preview_node)

func _on_waterfall_pressed() -> void:
	Fx.create_waterfall_mist(preview_node)

func _on_dust_cloud_pressed() -> void:
	Fx.create_dust_cloud(preview_node)

func _on_water_splash_pressed() -> void:
	Fx.create_water_splash(preview_node)

func _on_wood_debris_pressed() -> void:
	Fx.create_wood_debris(preview_node)

func _on_fireball_pressed() -> void:
	Fx.create_fireball_trail(preview_node)

func _on_ash_pressed() -> void:
	Fx.create_ash_particles(preview_node)
