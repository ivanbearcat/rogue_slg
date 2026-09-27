extends CanvasLayer

@onready var main_volume_progress: TextureProgressBar = %main_volume_progress
@onready var music_volume_progress: TextureProgressBar = %music_volume_progress
@onready var effect_volume_progress: TextureProgressBar = %effect_volume_progress
@onready var main_volume_label: Label = %main_volume_label
@onready var music_volume_label: Label = %music_volume_label
@onready var effect_volume_label: Label = %effect_volume_label
@onready var language_option: OptionButton = %language_option


func _ready() -> void:
	EventBus.subscribe('setting_ui', setting_ui)
	add_to_group("setting_ui")
	# 用上次保存的值回填 UI(no_signal 避免触发回调又原样写回)
	main_volume_progress.set_value_no_signal(GameSettings.main_volume)
	music_volume_progress.set_value_no_signal(GameSettings.music_volume)
	effect_volume_progress.set_value_no_signal(GameSettings.effect_volume)
	_refresh_labels()
	_init_language_option()

func _refresh_labels() -> void:
	_on_main_volume_progress_value_changed(main_volume_progress.value)
	_on_music_volume_progress_value_changed(music_volume_progress.value)
	_on_effect_volume_progress_value_changed(effect_volume_progress.value)

# ---- 音量:数值 → GameSettings → 落盘 ----
func _on_main_volume_progress_value_changed(value: float) -> void:
	main_volume_label.text = "%d" % roundi(value)
	GameSettings.main_volume = value
	GameSettings.apply_settings()
	GameSettings.save_settings()

func _on_music_volume_progress_value_changed(value: float) -> void:
	music_volume_label.text = "%d" % roundi(value)
	GameSettings.music_volume = value
	GameSettings.apply_settings()
	GameSettings.save_settings()

func _on_effect_volume_progress_value_changed(value: float) -> void:
	effect_volume_label.text = "%d" % roundi(value)
	GameSettings.effect_volume = value
	GameSettings.apply_settings()
	GameSettings.save_settings()

# ±5 按钮改的是 progress.value,value_changed 会自动触发上面的保存,不用动

# ---- 全屏 ----
func _on_fullscreen_check_toggled(toggled_on: bool) -> void:
	GameSettings.fullscreen = toggled_on
	GameSettings.apply_settings()
	GameSettings.save_settings()

# 以下保持你现状即可
func _on_texture_button_pressed() -> void:
	hide()


func setting_ui(ops: String):
	if ops == 'show':
		show()
	elif ops == 'hide':
		hide()


func _on_reduce_main_volume_pressed() -> void:
	main_volume_progress.value -= 5

func _on_increase_main_volume_pressed() -> void:
	main_volume_progress.value += 5

func _on_reduce_music_volume_pressed() -> void:
	music_volume_progress.value -= 5

func _on_increase_music_volume_pressed() -> void:
	music_volume_progress.value += 5

func _on_reduce_effect_volume_pressed() -> void:
	effect_volume_progress.value -= 5

func _on_increase_effect_volume_pressed() -> void:
	effect_volume_progress.value += 5

func _init_language_option() -> void:
	# 语言名不是待翻译文案,禁止自动翻译(别让"中文"被翻成别的东西)
	language_option.auto_translate_mode = Control.AUTO_TRANSLATE_MODE_DISABLED
	language_option.clear()                       # .tscn 里硬编码的 2 项清掉,以后只认代码
	for l: Dictionary in GameSettings.LANGUAGES:
		language_option.add_item(str(l["label"]), int(l["id"]))
	language_option.selected = language_option.get_item_index(GameSettings.language_id)
	language_option.item_selected.connect(_on_language_option_selected)

func _on_language_option_selected(index: int) -> void:
	var id := language_option.get_item_id(index)
	GameSettings.language_id = id
	GameSettings.apply_settings()
	GameSettings.save_settings()
