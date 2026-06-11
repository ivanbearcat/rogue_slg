extends Node
## MockTools - 替代 Tools autoload 用于测试
## time_sleep 在测试中立即返回，不等待

func time_sleep(_time: float) -> void:
	# 测试中跳过等待，直接返回
	pass
