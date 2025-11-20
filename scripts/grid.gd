extends Node2D

signal grid_cmd

@onready var range: Sprite2D = $Area2D/range
@onready var cursor: Sprite2D = $Area2D/cursor
@onready var warning: Sprite2D = $Area2D/warning
@onready var target: Sprite2D = $Area2D/target
@onready var attack: Sprite2D = $Area2D/attack

var grid_index: Vector2


func _on_area_2d_mouse_entered() -> void:
	#print(Current.grid_index)
	#print(self.position)
	Current.within_grid_area = true
	Current.grid_index = self.grid_index
	cursor.show()
	match Current.mouse_status:
		"default":
			## 目标区域框出现且没有在播放攻击动画
			if target.visible == true and Current.attack_animation_finished == 1:
				EventBus.event_emit("show_skill_attack", [Current.hero.hero_name, Current.skill_num])
				Current.has_attack_grid = true
		"reroll", "reroll_dice", "reroll_color", "dice_add_1", "dice_sub_1":
			## 设置延迟保证当前史莱姆被设置完成
			await Tools.time_sleep(0.05)
			if Current.slime:
				if Current.slime.enemy_grid_index == self.grid_index:
					self.attack.show()
		"reroll_all", "mouse_up", "mouse_left", "mouse_right", "mouse_down":
			for grid in Current.all_grids_array:
				grid.attack.show()
		"add_power":
			if Current.hero.hero_grid_index == self.grid_index:
				self.attack.show()

func _on_area_2d_mouse_exited() -> void:
	cursor.hide()
	match Current.mouse_status:
		"default":
			if Current.has_attack_grid:
				## 等待分数结算动画和计分完成
				while Current.action_lock:
					await Tools.time_sleep(0.05)
				emit_signal("grid_cmd", "hide_skill_attack")
				Current.has_attack_grid = false
		"reroll_all", "mouse_up", "mouse_left", "mouse_right", "mouse_down":
			## 移出格子区域不显示红框
			await Tools.time_sleep(0.05)
			if not Current.within_grid_area:
				for grid in Current.all_grids_array:
					grid.attack.hide()
		_:
			EventBus.event_emit("hide_skill_attack")
			

			
	
	
