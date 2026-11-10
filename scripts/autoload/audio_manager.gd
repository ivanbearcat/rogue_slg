extends Node
## 音频管理:BGM 一首；音效并发随便发

var _bgm_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
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
	"click2": preload("res://audio/sfx/click2.ogg"),
	"coin": preload("res://audio/sfx/coin.tres"),
	"error": preload("res://audio/sfx/error_001.ogg"),
}

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
func play_sfx(key: String, pitch_jitter := 0.0, dedup_window := 0.0) -> void:
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
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			_apply_pitch(p, pitch_jitter)
			p.play()
			return
	_sfx_pool[0].stream = stream
	_apply_pitch(_sfx_pool[0], pitch_jitter)
	_sfx_pool[0].play()

## 设置播放器音高:有抖动取随机值;无抖动强制复位 1.0,清除上一次抖动的音高残留
func _apply_pitch(p: AudioStreamPlayer, pitch_jitter: float) -> void:
	if pitch_jitter > 0.0:
		p.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	else:
		p.pitch_scale = 1.0
