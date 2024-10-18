extends Node2D
class_name HeroStateMachine

@export var initial_state := NodePath()
@onready var state: HeroState = get_node(initial_state)

func _ready():
	await owner.ready
	for child in get_children():
		if child is HeroState:
			child.hero_state_machine = self
	state.enter()

func _unhandled_input(event: InputEvent)->void:
	if is_selected_hero():
		state.unhandled_input(event)

func _input(event: InputEvent)->void:
	if is_selected_hero():
		state.input(event)

func _process(delta):
	if is_selected_hero():
		state.update(delta)

func _physics_process(delta):
	if is_selected_hero():
		state.physics_update(delta)

func transition_to(target_state_name :String):
	if not has_node(target_state_name):
		return
	state.exit()
	state = get_node(target_state_name)
	state.enter()
	
func is_selected_hero():
	if Current.clicked_hero != null:
		return Current.clicked_hero.hero_name == owner.hero_name
	if Current.hero != null:
		return Current.hero.hero_name == owner.hero_name
	



			
