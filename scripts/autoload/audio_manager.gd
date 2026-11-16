extends Node
## 音频管理:BGM 一首；音效并发随便发

var _bgm_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
## 与 _sfx_pool 一一对应：记录每个播放器当前载入的音效键（stop_sfx 反查用）
var _sfx_playing_key: Array[String] = []
## 各音效键最近一次实际播放的时间戳(ms),配合 play_sfx 的去重窗口使用
var _sfx_last_played_ms: Dictionary = {}
const SFX_POOL_SIZE := 8          # 最多 8 个音效同时响
const SFX_DIR := "res://audio/sfx/"
const SOUNDS := {
	"attack": preload("res://audio/sfx/attack.ogg"),
	"slime_die": preload("res://audio/sfx/slime_die.ogg"),
	"footstep": preload("res://audio/sfx/footstep_grass_002.ogg"),
	"button_hover": preload("res://audio/sfx/button_hover.ogg"),
	"dice_shake": preload("res://audio/sfx/dice-shake-1.ogg"),
	"change_scene": preload("res://audio/sfx/change_scene.ogg"),
	"change_scene_reverse": preload("res://audio/sfx/change_scene_reverse.ogg"),
	"click2_press": preload("res://audio/sfx/click2_press.ogg"),
	"click2_release": preload("res://audio/sfx/click2_release.ogg"),
	"coin": preload("res://audio/sfx/coin.tres"),
	"error": preload("res://audio/sfx/error_001.ogg"),
}
## 骰子波回声常量（试听后可调，不改规格语义）
const DICE_WAVE_ECHO_DELAYS: Array[float] = [0.06, 0.12]
const DICE_WAVE_ECHO_VOLUME_DB := -12.0
const DICE_WAVE_ECHO_PITCH_JITTER := 0.04

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # 暂停界面时也能响(按需)
	# BGM 专用播放器,走 Music 总线
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = &"Music"
	add_child(_bgm_player)
	# 音效播放器池,走 Effect 总线
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"Effect"
		add_child(p)
		_sfx_pool.append(p)
		_sfx_playing_key.append("")
	## 按钮音效中央挂钩：场景静态按钮与代码动态生成的按钮同样覆盖
	get_tree().node_added.connect(_on_node_added)
	## 兜底：启动时已在树内的按钮（主场景可能先于本 autoload 的 _ready 装配）
	for node in get_tree().root.find_children("*", "BaseButton", true, false):
		_hook_button(node as BaseButton)

func play_bgm(path: String) -> void:
	var stream := load(path) as AudioStream
	if stream == null or _bgm_player.stream == stream:
		return
	_bgm_player.stream = stream
	_bgm_player.play()

func stop_bgm() -> void:
	_bgm_player.stop()

## 用法:AudioManager.play_sfx("attack")
## 可选参数:pitch_jitter 音高随机抖动幅度(默认0=不抖,标准音高播放);dedup_window 同键去重窗口秒数(默认0=不去重)
## volume_db 本次播放音量(默认0dB);base_pitch 固定基准音高(默认1.0,抖动围绕基准值计算)
func play_sfx(key: String, pitch_jitter := 0.0, dedup_window := 0.0, volume_db := 0.0, base_pitch := 1.0) -> void:
	var stream: AudioStream = SOUNDS.get(key)
	if stream == null:
		push_warning("音效 key 不存在: %s" % key)
		return
	## 去重窗口:窗口内同键重复触发直接丢弃,保证一波多杀只响一层(窗口外正常播放)
	if dedup_window > 0.0:
		var now_ms := Time.get_ticks_msec()
		var last_ms: Variant = _sfx_last_played_ms.get(key)
		if last_ms != null and now_ms - last_ms < int(dedup_window * 1000.0):
			return
		_sfx_last_played_ms[key] = now_ms
	## 从池里挑一个空闲的,没有就抢第一个(最旧的)
	for i in _sfx_pool.size():
		if not _sfx_pool[i].playing:
			_start_sfx_player(i, key, stream, pitch_jitter, volume_db, base_pitch)
			return
	_start_sfx_player(0, key, stream, pitch_jitter, volume_db, base_pitch)

## 在池内指定槽位启动一次播放，并记录该槽位当前音效键
func _start_sfx_player(index: int, key: String, stream: AudioStream, pitch_jitter: float, volume_db: float, base_pitch: float) -> void:
	var p := _sfx_pool[index]
	p.stream = stream
	p.volume_db = volume_db
	_apply_pitch(p, pitch_jitter, base_pitch)
	_sfx_playing_key[index] = key
	p.play()

## 中止某音效键正在播放的所有实例；没有该键在响时无影响
func stop_sfx(key: String) -> void:
	for i in _sfx_pool.size():
		if _sfx_playing_key[i] == key and _sfx_pool[i].playing:
			_sfx_pool[i].stop()
			_sfx_playing_key[i] = ""

## 延迟触发：delay_sec 秒后走常规 play_sfx（回声层用）
func play_sfx_delayed(key: String, delay_sec: float, pitch_jitter := 0.0, dedup_window := 0.0, volume_db := 0.0, base_pitch := 1.0) -> void:
	if delay_sec <= 0.0:
		play_sfx(key, pitch_jitter, dedup_window, volume_db, base_pitch)
		return
	get_tree().create_timer(delay_sec).timeout.connect(
		play_sfx.bind(key, pitch_jitter, dedup_window, volume_db, base_pitch),
		CONNECT_ONE_SHOT
	)

## 骰子波组声：主声 + 固定 2 层轻叠回声，播放层数与波内史莱姆数量无关
func play_dice_shake_wave() -> void:
	play_sfx("dice_shake")
	for delay_sec in DICE_WAVE_ECHO_DELAYS:
		play_sfx_delayed("dice_shake", delay_sec, DICE_WAVE_ECHO_PITCH_JITTER, 0.0, DICE_WAVE_ECHO_VOLUME_DB)

## 按钮中央挂钩：node_added 后连接一次，is_connected 防重复
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_hook_button(node as BaseButton)

func _hook_button(button: BaseButton) -> void:
	var on_mouse_entered := _on_button_mouse_entered.bind(button)
	if not button.mouse_entered.is_connected(on_mouse_entered):
		button.mouse_entered.connect(on_mouse_entered)
	var on_button_down := _on_button_down.bind(button)
	if not button.button_down.is_connected(on_button_down):
		button.button_down.connect(on_button_down)
	var on_button_up := _on_button_up.bind(button)
	if not button.button_up.is_connected(on_button_up):
		button.button_up.connect(on_button_up)

func _on_button_mouse_entered(button: BaseButton) -> void:
	if button.disabled:
		return
	play_sfx("button_hover", 0.0, 0.1)

func _on_button_down(button: BaseButton) -> void:
	if button.disabled:
		return
	play_sfx("click2_press")

func _on_button_up(button: BaseButton) -> void:
	if button.disabled:
		return
	play_sfx("click2_release")

## 设置播放器音高:有抖动取围绕 base_pitch 的随机值;无抖动直接用 base_pitch
## 默认 base_pitch=1.0 时与旧行为逐比特一致（无抖动时强制复位 1.0）
func _apply_pitch(p: AudioStreamPlayer, pitch_jitter: float, base_pitch := 1.0) -> void:
	if pitch_jitter > 0.0:
		p.pitch_scale = base_pitch * randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	else:
		p.pitch_scale = base_pitch
