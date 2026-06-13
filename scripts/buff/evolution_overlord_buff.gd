extends Buff

func set_buff():
	# 领主BUFF不再创建UI，只做逻辑注册
	pass

func process_buff():
	# 进化霸主 - 进化增幅：所有基础分额外+1
	if BuffSystem.get_family_count("evolution") < 4:
		return
	# 进化系目前仅有drop_bonus，进化霸主提供全局基础分+1
	# 基础分+1由Current中的dice_point_score驱动，此处标记激活状态
	pass

func clear_buff():
	pass
