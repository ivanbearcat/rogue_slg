extends Buff

func set_buff():
	# 生机霸主：创建自身图标（购买激活与读档重建共用此路径）
	_setup_overlord_icon()

func process_buff():
	# 生机霸主 - 过关回血+满血成长在外部流程 _check_stage_clear() 中通过 BuffSystem.get_family_count("vitality") >= 4 计算
	pass

func clear_buff():
	pass
