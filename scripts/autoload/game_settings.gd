extends Node
## 游戏设置持久化

const SETTINGS_PATH := "user://settings.cfg"

## 语言注册表——以后加语言只在往这里加一行，id 顺序保持
## 兼容规则：新语言永远往下追加，禁止插在中间（老玩家的 language_id 序号不能变味）
const LANGUAGES: Array[Dictionary] = [
	{ "id": 0, "locale": "zh_CN", "label": "中文" },   # NO_TRANSLATE 语言名是专有名词
	{ "id": 1, "locale": "en", "label": "English" },   # NO_TRANSLATE 语言名是专有名词
	{ "id": 2, "locale": "ja", "label": "日本語" },     # NO_TRANSLATE 语言名是专有名词
	{ "id": 3, "locale": "ko", "label": "한국어" },
	{ "id": 4, "locale": "zh_TW", "label": "繁體中文" },   # NO_TRANSLATE 语言名是专有名词
	{ "id": 5, "locale": "fr", "label": "Français" },
	{ "id": 6, "locale": "de", "label": "Deutsch" },
	{ "id": 7, "locale": "es", "label": "Español" },
	{ "id": 8, "locale": "pt_BR", "label": "Português (BR)" },
	{ "id": 9, "locale": "it", "label": "Italiano" },
]

## 按语言切换像素字体：主字体 + fallback 链，见 i18n.md 阶段 7
const FONT_BY_LOCALE := {
	"zh_CN": "res://fonts/fusion-pixel-12px-monospaced-zh_hans.otf",
	"zh_TW": "res://fonts/fusion-pixel-12px-monospaced-zh_hant.otf",
	"ja":    "res://fonts/fusion-pixel-12px-monospaced-ja.otf",
	"ko":    "res://fonts/fusion-pixel-12px-monospaced-ko.otf",
}
const FONT_FALLBACK := "res://fonts/fusion-pixel-12px-monospaced-latin.otf"
const FONT_CJK := "res://fonts/fusion-pixel-12px-monospaced-zh_hans.otf"

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
	_apply_font()

## 按当前语言装配字体与 fallback 链，写入根主题与 LabelSettings
func _apply_font() -> void:
	var main_path: String = FONT_BY_LOCALE.get(get_locale(), FONT_FALLBACK)
	var font: FontFile = load(main_path)
	var chain: Array[Font] = []
	for p: String in [FONT_FALLBACK, FONT_CJK]:
		if p != main_path:
			chain.append(load(p))
	font.fallbacks = chain
	var theme := get_tree().root.theme
	if theme == null:
		theme = Theme.new()
		get_tree().root.theme = theme
	theme.default_font = font
	var ls: Resource = load("res://fonts/pixel_cn_label_settings.tres")
	if ls is LabelSettings:
		ls.font = font

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
