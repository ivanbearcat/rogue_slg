extends Node
## 游戏设置持久化

const SETTINGS_PATH := "user://settings.cfg"

## 语言注册表——以后加语言只在往这里加一行，id 顺序保持
## 兼容规则：新语言永远往下追加，禁止插在中间（老玩家的 language_id 序号不能变味）
const LANGUAGES: Array[Dictionary] = [
	{ "id": 0, "locale": "zh_CN", "label": "中文" },
	{ "id": 1, "locale": "en", "label": "English" },
	# { "id": 2, "locale": "ja", "label": "日本語" },   # 未来追加示例
]

var main_volume := 50.0
var music_volume := 50.0
var effect_volume := 50.0
var fullscreen := false
var language_id := 0   # 与 LANGUAGES[].id 对应的运行时序号

func _ready() -> void:
	load_settings()
	apply_settings()

const BUS_VOLUME := {
	"main_volume":   "Master",
	"music_volume":  "Music",
	"effect_volume": "Effect",
}

func apply_settings() -> void:
	for key: String in BUS_VOLUME:
		var idx := AudioServer.get_bus_index(BUS_VOLUME[key])
		if idx == -1:
			continue
		var linear: float = get(key) / 100.0
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(idx, linear <= 0.0)
	DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED)
	TranslationServer.set_locale(get_locale())   # 翻译表建好后这行自动生效

## id → locale 字符串；id 越界时自动回退中文（挡住任何脏数据）
func get_locale() -> String:
	for l: Dictionary in LANGUAGES:
		if int(l["id"]) == language_id:
			return str(l["locale"])
	language_id = 0
	return str(LANGUAGES[0]["locale"])

func _locale_to_id(locale: String) -> int:
	for l: Dictionary in LANGUAGES:
		if str(l["locale"]) == locale:
			return int(l["id"])
	return 0

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "main_volume", main_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "effect_volume", effect_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	# 新档存字符串，双保险期暂时继续留着旧的序号字段
	cfg.set_value("general", "language", get_locale())
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
	# 读取优先级：字符串字段 → 旧序号字段 → 默认中文
	if cfg.has_section_key("general", "language"):
		language_id = _locale_to_id(str(cfg.get_value("general", "language", "zh_CN")))
	else:
		language_id = int(cfg.get_value("general", "language_id", 0))
