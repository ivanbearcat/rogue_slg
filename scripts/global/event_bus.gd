extends Node

## 事件优先级枚举
enum Priority {
	LOW = 0,			## 低优先级
	NORMAL = 1,		## 普通优先级
	HIGH = 2,		## 高优先级
}

## 事件历史记录
var _event_history: Array[Dictionary] = []
## 事件优先级表 {事件名: {object_id: {priority, once, filter}}}
var _event_metadata: Dictionary = {}
## 是否记录事件历史
@export var enable_history: bool = false
## 历史记录最大长度
@export var max_history_length: int = 100
## 调试模式
@export var debug_mode: bool = false

## 信号：事件被推送时触发
signal event_pushed(event_name: String, payload: Array)
## 信号：事件处理完成时触发
signal event_handled(event_name: String, payload: Array)

## 推送事件
## [param event_name] 事件名
## [param payload] 事件负载
## [param immediate] 是否立即触发事件
func event_emit(event_name: String, param: Array = []) -> void:
	if debug_mode:
		print("[EventBus] Pushing event: %s with param: %s" % [event_name, param])
	param = [event_name] + param
	# 发送事件
	callv("emit_signal", param)
	


## 订阅事件
## [param event_name] 事件名
## [param callback] 回调函数
## [param priority] 优先级
## [param once] 是否只执行一次
## [param filter] 过滤器
func subscribe(event_name: String, callback: Callable, priority: Priority=Priority.NORMAL, once: bool=false,) -> void:
	# 动态添加信号（如果不存在）
	if not has_signal(event_name):
		add_user_signal(event_name)
	# 检查是否已存在相同的回调
	for conn in get_signal_connection_list(event_name):
		if conn["callable"] == callback:
			if debug_mode:
				print("[EventBus] Callback already subscribed to event: %s" % event_name)
			else:
				push_warning("Callback already subscribed to event: %s" % event_name)
			return
	# 连接信号
	connect(event_name, callback)

	
	if debug_mode:
		print("[EventBus] Subscribed to event: %s with priority: %s" % [event_name, priority])

## 取消订阅事件
## [param event_name] 事件名
## [param callback] 回调函数
func unsubscribe(event_name: String, callback: Callable) -> void:
	if not has_signal(event_name):
		return
		
	# 断开连接
	if is_connected(event_name, callback):
		disconnect(event_name, callback)
		
	if debug_mode:
		print("[EventBus] Unsubscribed from event: %s" % event_name)


## 取消订阅所有事件
## [param callback] 回调函数
func unsubscribe_all(callback: Callable) -> void:
	for event_name in _get_all_signals():
		if is_connected(event_name, callback):
			unsubscribe(event_name, callback)

## 清除所有订阅
func clear_subscriptions() -> void:
	for event_name in _get_all_signals():
		for conn in get_signal_connection_list(event_name):
			disconnect(event_name, conn["callable"])
	
	if debug_mode:
		print("[EventBus] All subscriptions cleared")

## 获取事件订阅者数量
## [param event_name] 事件名
func get_subscriber_count(event_name: String) -> int:
	if not has_signal(event_name):
		return 0
	return get_signal_connection_list(event_name).size()

## 获取事件历史记录
## [return] 事件历史记录
func get_event_history() -> Array[Dictionary]:
	return _event_history.duplicate()

## 清除事件历史记录
func clear_event_history() -> void:
	_event_history.clear()


## 获取所有可用信号
func _get_all_signals() -> Array[String]:
	var signal_list: Array[String] = []
	for signal_dict in get_signal_list():
		if signal_dict["name"] != "event_pushed" and signal_dict["name"] != "event_handled":
			signal_list.append(signal_dict["name"])
	return signal_list

		
## 获取订阅数量（测试用）
func get_subscription_counts() -> Dictionary:
	var result = {}
	for event_name in _get_all_signals():
		result[event_name] = get_signal_connection_list(event_name).size()
	return result
