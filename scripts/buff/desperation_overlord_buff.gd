extends Buff

func set_buff():
	# 绝境霸主 - 授予全局免死（仅首次）
	if not Current.has_death_immunity:
		Current.has_death_immunity = true
		Current.death_immunity_used = false

func process_buff():
	pass

func clear_buff():
	pass
