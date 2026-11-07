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
	_setup_skill_tooltips()
	## 触发源区分（design D4）：BaseButton 的 pressed 信号不携带鼠标/快捷键来源信息，
	## 经 gui_input（仅鼠标/聚焦交互经过）记录"该按钮最近一次鼠标左键按下"，
	## 与 SLICEST pressed handler 同帧先后到达 → _skill_power_up 据此分路定位；
	## shortcut（Alt+N）不走 gui_input，不记录 → 归键盘路径
	for btn: TextureButton in [skill_1_button, skill_2_button, skill_3_button]:
		btn.gui_input.connect(_on_power_button_gui_input.bind(btn))

## 能量按钮鼠标按下标记（见上侧注释；普通键盘 focus 触发不标记，也归键盘路径）
func _on_power_button_gui_input(event: InputEvent, btn: TextureButton) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
	and event.is_pressed() == true:
		btn.set_meta("mouse_press_pending", true)

## 三个技能图标区接入技能tooltip（技能1带动画，技能2/3纯文本占位）
## 悬停目标为整个图标框（skill_1/2/3容器，含图标主体）；正下方细条按钮不作为触发目标
## 同时清空按钮原生tooltip_text，避免原生提示窗口双显
## 图标容器自带的mouse_entered/exited高亮连接与tooltip挂接并存（防重连写法只管理本体系连接）
func _setup_skill_tooltips() -> void:
	var rows_by_num := {}
	for row: Dictionary in Tools.load_json_file("res://config/hero_skill.json"):
		if str(row.get("hero_id", "")) == "soldier":
			rows_by_num[int(row.get("skill_num", 0))] = row
	skill_1_button.tooltip_text = ""
	skill_2_button.tooltip_text = ""
	skill_3_button.tooltip_text = ""
	var icon_areas := [self, get_node("../../VBoxContainer2/skill_2"), get_node("../../VBoxContainer3/skill_3")]
	for num in range(1, 4):
		if rows_by_num.has(num):
			TooltipManager.set_skill_tooltip(icon_areas[num - 1], rows_by_num[num])

func _input(event: InputEvent) -> void:
	## 点击英雄才显示
	if Current.clicked_hero == null or Current.id_path:
		return
	else:
		## 移动状态才显示
		if ["idle", "move", "skill_1", "skill_2", "skill_3", "coin_skill_move"].has(Current.clicked_hero.hero_state_machine.state.name):
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
	event.is_pressed() == true:
		if Current.clicked_hero.hero_state_machine.state.name in ["skill_1", "skill_2", "skill_3"]:
			hide_all_skills()
			Current.clicked_hero.hero_state_machine.transition_to("move")

func reset_all_hero_skills():
	if Current.hero.hero_state_machine.state.name in ["move", "skill_1", "skill_2", "skill_3"]:
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
	## 先记录本次事件的按钮按下态（随后 _on_skill_power_reset 的收口同步
	## 会按真相重写按钮；先读后写保证"按下→赋能 / 弹起→取消赋能"语义不变）
	var power_buttons := [null, skill_1_button, skill_2_button, skill_3_button]
	var press_wanted: bool = power_buttons[skill_num].button_pressed
	## 触发源判定（design D4）：gui_input 记录的鼠标按下标记在本 handler 之前到达，
	## 读取后即清除；无标记 → 快捷键（或测试直调）→ 键盘路径
	var mouse_triggered: bool = false
	var power_button: TextureButton = power_buttons[skill_num]
	if power_button.get_meta("mouse_press_pending", false):
		power_button.remove_meta("mouse_press_pending")
		mouse_triggered = true
	## 零能量时产生按入意图 → 弹"需要能量"提示：
	## 鼠标点击带 at_mouse=true（气泡弹在鼠标位置上方），Alt+1/2/3 快捷键省略（保持默认位置）；
	## 取消赋能（弹起意图）不发射；随后既有幂等弹回逻辑不变
	if press_wanted and Current.power <= 0:
		if mouse_triggered:
			EventBus.event_emit("ui_alert", ["需要能量", true])
		else:
			EventBus.event_emit("ui_alert", ["需要能量"])
	_on_skill_power_reset()
	## 有能量且该技能的能量按钮处于按下态（点击/快捷键切换）才占用赋能
	if Current.power > 0 and press_wanted:
		Current.power_skill = skill_num
	_sync_power_ui()

## 赋能 UI 单点同步（design D2）：以 Current.power_skill 为唯一真相，
## 一次性直写全部赋能视觉位；任何触发点（赋能切换/复位/读档恢复刷新）共用本入口。
## 不变式：mask4.visible ⇔ power_skill != 3；hero_ui_1/2 发光 ⇔ power_skill == 1/2；
## 按钮按下态直写不触发 pressed（Engine 只发 toggled，无订阅者，无递归风险）
func _sync_power_ui() -> void:
	hero_ui_1.material.set_shader_parameter("enable", Current.power_skill == 1)
	hero_ui_2.material.set_shader_parameter("enable", Current.power_skill == 2)
	mask_4.visible = Current.power_skill != 3
	skill_1_button.button_pressed = Current.power_skill == 1
	skill_2_button.button_pressed = Current.power_skill == 2
	skill_3_button.button_pressed = Current.power_skill == 3

func _on_skill_power_reset() -> void:
	Current.power_skill = 0
	_sync_power_ui()

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
