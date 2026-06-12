extends Buff

func set_buff():
	# 领主BUFF不再创建UI，只做逻辑注册
	pass

func process_buff():
	# 生机霸主 - 过关回血+满血成长在外部流程 _check_stage_clear() 中通过 BuffSystem.get_family_count("vitality") >= 4 计算
	pass

func clear_buff():
	pass
