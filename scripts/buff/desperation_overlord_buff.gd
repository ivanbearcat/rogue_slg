extends Buff

func set_buff():
	# 绝境霸主 - 授予全局免死（仅首次）
	if not Current.has_death_immunity:
		Current.has_death_immunity = true
		Current.death_immunity_used = false
	# 创建自身图标（免死授予之外：注册即常驻图标+脉冲边框，本霸主无触发闪）
	_setup_overlord_icon()

func process_buff():
	pass

func clear_buff():
	pass
