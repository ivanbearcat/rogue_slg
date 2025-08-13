extends MarginContainer

@onready var nine_patch_rect: NinePatchRect = $NinePatchRect
@onready var nine_patch_rect_2: NinePatchRect = $"../skill_2/NinePatchRect2"
@onready var nine_patch_rect_3: NinePatchRect = $"../skill_3/NinePatchRect3"
@onready var mask_1: ColorRect = $hero_ui_1/mask1
@onready var mask_2: ColorRect = $"../skill_2/hero_ui_2/mask2"
@onready var mask_3: ColorRect = $"../skill_3/hero_ui_3/mask3"
@onready var hero_ui_1: TextureRect = %hero_ui_1
@onready var hero_ui_2: TextureRect = %hero_ui_2
@onready var hero_ui_3: TextureRect = %hero_ui_3

## 鼠标进入范围
var is_enterd := false

func _ready() -> void:
	EventBus.subscribe("skill_power_up", _on_skill_power_up)
	EventBus.subscribe("skill_power_reset", _on_skill_power_reset)
	EventBus.subscribe("hide_all_skills", hide_all_skill)

func _input(event: InputEvent) -> void:
	## 点击英雄才显示
	if Current.clicked_hero == null or Current.id_path:
		return
	else:
		## 移动状态才显示
		if ["idle", "move", "skill_1", "skill_2", "skill_3"].has(Current.clicked_hero.hero_state_machine.state.name):
			## 左键点击显示技能被按下的图
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and \
			event.is_pressed() == true and is_enterd == true or event.is_action_pressed("1"):
				## 取消显示其他技能
				mask_2.visible = false
				nine_patch_rect_2.material.set_shader_parameter("is_high_light", false)
				mask_3.visible = false
				nine_patch_rect_3.material.set_shader_parameter("is_high_light", false)
				## 显示技能1
				mask_1.visible = true
				nine_patch_rect.material.set_shader_parameter("is_high_light", true)
				Current.clicked_hero.hero_state_machine.transition_to("skill_1")
		
	## 右键点击恢复
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and \
	event.is_pressed() == true or event.is_action_pressed("esc"):
		if Current.clicked_hero.hero_state_machine.state.name in ["skill_1", "skill_2", "skill_3"]:
			hide_all_skill()
			Current.clicked_hero.hero_state_machine.transition_to("move")

func hide_all_skill():
	mask_1.visible = false
	nine_patch_rect.material.set_shader_parameter("is_high_light", false)
	mask_2.visible = false
	nine_patch_rect_2.material.set_shader_parameter("is_high_light", false)
	mask_3.visible = false
	nine_patch_rect_3.material.set_shader_parameter("is_high_light", false)

func _on_mouse_entered() -> void:
	nine_patch_rect.material.set_shader_parameter("is_high_light", true)
	is_enterd = true

func _on_mouse_exited() -> void:
	if mask_1.visible == false:
		nine_patch_rect.material.set_shader_parameter("is_high_light", false)
	is_enterd = false

func _on_skill_power_up() -> void:
	var skill_ui_list = [hero_ui_1, hero_ui_2, hero_ui_3]
	var skill_ui_tmp = skill_ui_list.pick_random()
	skill_ui_tmp.material.set_shader_parameter("enable", true)
	Current.power_slime = skill_ui_list.find(skill_ui_tmp)
	
func _on_skill_power_reset() -> void:
	var skill_ui_list = [hero_ui_1, hero_ui_2, hero_ui_3]
	for skill in skill_ui_list:
		skill.material.set_shader_parameter("enable", false)
