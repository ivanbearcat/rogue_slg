extends Node

func time_sleep(time):
	await get_tree().create_timer(time).timeout
