extends Buff

func set_buff():
	# 领主BUFF不再创建UI，只做逻辑注册
	# ×1.5乘法逻辑在 buff_system._apply_overlord_multiplier() 中处理
	pass

func process_buff():
	# 族主逻辑在 buff_system._apply_overlord_multiplier() 中处理
	pass

func clear_buff():
	pass
