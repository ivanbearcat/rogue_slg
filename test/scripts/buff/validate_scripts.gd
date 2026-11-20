extends SceneTree
## 校验所有修改过的脚本能否被Godot解析（语法错误检查）
## 用法: godot --headless --script res://test/scripts/buff/validate_scripts.gd

var _scripts_to_check: Array = [
	"res://scripts/game_manager.gd",
	"res://scripts/autoload/buff_system.gd",
	"res://scripts/autoload/current.gd",
	"res://scripts/autoload/effect_manager.gd",
	"res://scripts/ui/score_token.gd",
	"res://scripts/ui/score_balloon.gd",
	"res://scripts/ui/score_balloon_orchestrator.gd",
	"res://scripts/buff/swarm_overlord_buff.gd",
	"res://scripts/buff/resonance_overlord_buff.gd",
	"res://scripts/buff/desperation_overlord_buff.gd",
	"res://scripts/buff/hunt_overlord_buff.gd",
	"res://scripts/buff/swift_overlord_buff.gd",
	"res://scripts/buff/evolution_overlord_buff.gd",
	"res://scripts/buff/vitality_overlord_buff.gd",
	"res://scripts/buff/swarm_call_buff.gd",
	"res://scripts/buff/swarm_tithe_buff.gd",
	"res://scripts/buff/tide_crusher_buff.gd",
	"res://scripts/buff/coin_mirror_score_buff.gd",
	"res://scripts/buff/mint_press_buff.gd",
	"res://scripts/buff/full_range_assault_buff.gd",
	"res://scripts/buff/power_slime_bounty_buff.gd",
	"res://scripts/buff/power_surge_buff.gd",
	"res://scripts/buff/drop_hunter_buff.gd",
	"res://scripts/buff/position_master_buff.gd",
	"res://scripts/buff/hunt_pursuit_buff.gd",
	"res://scripts/buff/swift_amplify_buff.gd",
	"res://scripts/buff/rush_strike_buff.gd",
	"res://scripts/buff/dice_mastery_buff.gd",
	"res://scripts/buff/color_brand_buff.gd",
	"res://scripts/buff/rainbow_surge_buff.gd",
	"res://scripts/buff/resonance_chain_buff.gd",
	"res://scripts/buff/four_color_resonance_buff.gd",
	"res://scripts/buff/chromatic_frenzy_buff.gd",
	"res://scripts/buff/late_bloom_buff.gd",
	"res://scripts/buff/curse_burner_buff.gd",
	"res://scripts/buff/last_stand_buff.gd",
	"res://scripts/buff/scorched_earth_buff.gd",
	"res://scripts/buff/gold_overlord_buff.gd",
	"res://scripts/debuff/attack_weaken_buff.gd",
	"res://scripts/debuff/power_backlash_buff.gd",
	"res://scripts/debuff/drop_penalty_buff.gd",
	"res://scripts/debuff/score_ceiling_buff.gd",
	"res://test/scripts/buff/test_buff_system.gd",
	"res://test/scripts/buff/test_resonance_buffs.gd",
	"res://test/scripts/buff/test_hunt_and_evolution_buffs.gd",
	"res://test/scripts/buff/score_declaration_probe.gd",
	"res://test/scripts/buff/score_show_probe.gd",
	"res://test/scripts/buff/test_swarm_buffs.gd",
]

func _init():
	await_frame()

func await_frame():
	await process_frame
	run_validation()
	quit()

func run_validation():
	print("\n==================================================")
	print("  Script Syntax Validation")
	print("==================================================")
	var passed := 0
	var failed := 0
	for script_path in _scripts_to_check:
		var script = load(script_path)
		if script == null:
			print("  FAIL: %s (load returned null — syntax error)" % script_path)
			failed += 1
		else:
			print("  PASS: %s" % script_path)
			passed += 1
	print("--------------------------------------------------")
	print("  Passed: %d | Failed: %d" % [passed, failed])
	print("==================================================\n")
