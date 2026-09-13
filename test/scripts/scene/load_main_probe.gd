extends SceneTree
## 最小复现：headless -s 上下文直接 load main.tscn 是否 Parse Error

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[t] step1 直接 load")
	var res: Resource = load("res://scenes/main.tscn")
	if res == null:
		printerr("[t] load 返回 null")
		quit(1)
		return
	print("[t] step1 OK")
	print("[t] step2 threaded request")
	ResourceLoader.load_threaded_request("res://scenes/main.tscn")
	for i in 120:
		await process_frame
		if ResourceLoader.load_threaded_get_status("res://scenes/main.tscn") != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			break
	if ResourceLoader.load_threaded_get_status("res://scenes/main.tscn") != ResourceLoader.THREAD_LOAD_LOADED:
		printerr("[t] threaded load 失败: " + str(ResourceLoader.load_threaded_get_status("res://scenes/main.tscn")))
		quit(1)
		return
	print("[t] step2 OK")
	var inst: Node = load("res://scenes/main.tscn").instantiate()
	print("[t] step3 instantiate OK")
	inst.queue_free()
	quit(0)
