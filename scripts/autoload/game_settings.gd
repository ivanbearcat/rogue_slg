extends Node
## 游戏设置持久化

const SETTINGS_PATH := "user://settings.cfg"

var main_volume := 50.0
var music_volume := 50.0
var effect_volume := 50.0
var fullscreen := false          # 场景里 CheckBox 默认 button_pressed = true,保持一致
var language_id := 0            # OptionButton item id: 0=中文 1=English

func _ready() -> void:
	load_settings()
	apply_settings()

const BUS_VOLUME := {           # 设置项 → 音频总线
	"main_volume":   "Master",
	"music_volume":  "Music",     # 没有"Music"总线时需在 Audio 面板新建
	"effect_volume": "Effect",    # 同上
}

func apply_settings() -> void:
	for key: String in BUS_VOLUME:
		var idx := AudioServer.get_bus_index(BUS_VOLUME[key])
		if idx == -1:
			continue              # 总线不存在就跳过,避免 set_(-1) 误改 Master
		var linear: float = get(key) / 100.0
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(idx, linear <= 0.0)
	DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED)
	# 目前项目还没有翻译资源,先存起来;以后加 .csv/.po 后这两行直接生效
	TranslationServer.set_locale(["zh_CN", "en"][language_id])

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "main_volume", main_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "effect_volume", effect_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("general", "language_id", language_id)
	var err := cfg.save(SETTINGS_PATH)
	if err != OK:
		push_warning("保存设置失败: %s" % error_string(err))

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	main_volume = cfg.get_value("audio", "main_volume", 50.0)
	music_volume = cfg.get_value("audio", "music_volume", 50.0)
	effect_volume = cfg.get_value("audio", "effect_volume", 50.0)
	fullscreen = cfg.get_value("display", "fullscreen", false)
	language_id = cfg.get_value("general", "language_id", 0)
