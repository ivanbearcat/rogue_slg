extends Node
## 音频管理:BGM 一首；音效并发随便发

var _bgm_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8          # 最多 8 个音效同时响
const SFX_DIR := "res://audio/sfx/"
const SOUNDS := {
	"attack": preload("res://audio/sfx/attack.tres"),
	"hit": preload("res://audio/sfx/hit.tres"),
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
func play_sfx(key: String) -> void:
	var stream: AudioStream = SOUNDS.get(key)
	if stream == null:
		push_warning("音效 key 不存在: %s" % key)
		return
	# 从池里挑一个空闲的,没有就抢第一个(最旧的)
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	_sfx_pool[0].stream = stream
	_sfx_pool[0].play()
