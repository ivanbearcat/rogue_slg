extends MarginContainer

@onready var nine_patch_rect: NinePatchRect = %NinePatchRect
@onready var nine_patch_rect_2: NinePatchRect = %NinePatchRect2
@onready var nine_patch_rect_3: NinePatchRect = %NinePatchRect3
@onready var mask_1: ColorRect = %mask1
@onready var mask_2: ColorRect = %mask2
@onready var mask_3: ColorRect = %mask3
@onready var mask_4: ColorRect = %mask4
@onready var hero_ui_1: TextureRect = %hero_ui_1
@onready var hero_ui_2: TextureRect = %hero_ui_2
@onready var hero_ui_3: TextureRect = %hero_ui_3
@onready var skill_1_button: TextureButton = %skill_1_button
@onready var skill_2_button: TextureButton = %skill_2_button
@onready var skill_3_button: TextureButton = %skill_3_button

## 鼠标进入范围
var is_enterd := false

func _ready() -> void:
	EventBus.subscribe("skill_power_reset", _on_skill_power_reset)
	EventBus.subscribe("hide_all_skills", hide_all_skills)
	EventBus.subscribe("skill_button_reset", _on_skill_button_reset)
	EventBus.subscribe("reset_all_hero_skills", reset_all_hero_skills)

func _input(event: InputEvent) -> void:
	## 点击英雄才显示
	if Current.clicked_hero == null or Current.id_path:
		return
	else:
		## 移动状态才显示
		if ["idle", "move", "skill_1", "skill_2", "skill_3"].has(Current.clicked_hero.hero_state_machine.state.name):
			## 避免和alt+1冲突
			if event.is_action_pressed("alt+1"): return
			## 左键点击显示技能被按下的图
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and \
			event.is_pressed() == true and is_enterd == true or event.is_action_pressed("1"):
				EventBus.event_emit("reset_cursor")
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
			hide_all_skills()
			Current.clicked_hero.hero_state_machine.transition_to("move")

func reset_all_hero_skills():
	if Current.clicked_hero.hero_state_machine.state.name in ["skill_1", "skill_2", "skill_3"]:
		hide_all_skills()
		if Current.is_moved == false:
			Current.clicked_hero.hero_state_machine.transition_to("idle")
		else:
			Current.clicked_hero.hero_state_machine.transition_to("move")
		
func hide_all_skills():
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

## 技能赋能
func _skill_power_up(skill_num: int) -> void:
	var skill_dict := {
		1: [skill_1_button, hero_ui_1],
		2: [skill_2_button, hero_ui_2],
		3: [skill_3_button, hero_ui_3]
	}
	_on_skill_power_reset()
	if Current.power > 0:
		if skill_dict[skill_num][0].button_pressed:
			if skill_num == 3:
				mask_4.hide()
			else:
				skill_dict[skill_num][1].material.set_shader_parameter("enable", true)
			Current.power_skill = skill_num
		else:
			if skill_num == 3:
				mask_4.show()
			skill_dict[skill_num][1].material.set_shader_parameter("enable", false)
	else:
		## 没有能量赋能（震屏，弹提示）
		skill_dict[skill_num][0].button_pressed = false
	
func _on_skill_power_reset() -> void:
	var skill_ui_list = [hero_ui_1, hero_ui_2]
	for skill in skill_ui_list:
		skill.material.set_shader_parameter("enable", false)
	Current.power_skill = 0

func _on_skill_button_reset() -> void:
	skill_1_button.button_pressed = false
	skill_2_button.button_pressed = false
	skill_3_button.button_pressed = false
	mask_4.show()

func _on_skill_1_button_pressed() -> void:
	_skill_power_up(1)
	if Current.skill_num == "1":
		EventBus.event_emit("hide_skill_attack")
		EventBus.event_emit("show_skill_attack", [Current.clicked_hero.hero_name, str(1)])
	
func _on_skill_2_button_pressed() -> void:
	_skill_power_up(2)
	if Current.skill_num == "2":
		EventBus.event_emit("hide_skill_attack")
		EventBus.event_emit("show_skill_attack", [Current.clicked_hero.hero_name, str(2)])

func _on_skill_3_button_pressed() -> void:
	_skill_power_up(3)
	if Current.skill_num == "3":
		EventBus.event_emit("hide_skill_attack")
		EventBus.event_emit("show_skill_attack", [Current.clicked_hero.hero_name, str(3)])
	
