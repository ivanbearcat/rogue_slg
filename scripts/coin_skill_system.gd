extends Node2D
@onready var game_manager: Node2D = $".."

func _ready() -> void:
	EventBus.subscribe("reset_all_button", reset_all_button)
	EventBus.subscribe("reroll", reroll)
	EventBus.subscribe("reroll_clicked", reroll_clicked)
	EventBus.subscribe("reroll_all", reroll_all)
	EventBus.subscribe("reroll_all_clicked", reroll_all_clicked)
	EventBus.subscribe("reroll_dice", reroll_dice)
	EventBus.subscribe("reroll_dice_clicked", reroll_dice_clicked)
	EventBus.subscribe("reroll_color", reroll_color)
	EventBus.subscribe("reroll_color_clicked", reroll_color_clicked)

func reset_all_button():
	for button in [game_manager.coin_skill_1, game_manager.coin_skill_2, game_manager.coin_skill_3]:
		if button.button_pressed == true:
			button.button_pressed = false
	for icon in [game_manager.coin_skill_1_icon, game_manager.coin_skill_1_icon, game_manager.coin_skill_1_icon]:
		if icon.position.y != 3.25:
			icon.position += Vector2(0, -1)
	if game_manager.q_texture.position.y != 2:
		game_manager.q_texture.position += Vector2(0, -1)
	for texture in [game_manager.w_texture, game_manager.e_texture]:
		if texture.position.y != 3:
			texture.position += Vector2(0, -1)

func reroll():
	var all_slime_array = Current.all_enemy_grid_index_array
	for grid in Current.all_grids_array:
		if grid.grid_index in all_slime_array:
			grid.target.show()
	if Current.grid_index in all_slime_array:
		for grid in Current.all_grids_array:
			if Current.grid_index == grid.grid_index:
				grid.attack.show()
			
func reroll_clicked():	
	if Current.slime:
		game_manager.slime_reroll(Current.slime)
		## 恢复鼠标重置状态
		CursorManager.reset_cursor()
		reset_all_button()
		Current.total_coins -= 1
		

func reroll_all():
	for grid in Current.all_grids_array:
		grid.target.show()
	if Current.within_grid_area:
		for grid in Current.all_grids_array:
			grid.attack.show()
			
func reroll_all_clicked():
	if Current.within_grid_area:
		for slime in Current.all_enemy_array:
			game_manager.slime_reroll(slime)
		CursorManager.reset_cursor()
		reset_all_button()
		Current.total_coins -= Current.coin_skill_array_dict[0]["coin_skill_cost"]
		
		
func reroll_dice():
	var all_slime_array = Current.all_enemy_grid_index_array
	for grid in Current.all_grids_array:
		if grid.grid_index in all_slime_array:
			grid.target.show()
	if Current.grid_index in all_slime_array:
		for grid in Current.all_grids_array:
			if Current.grid_index == grid.grid_index:
				grid.attack.show()
	
func reroll_dice_clicked():
	if Current.slime:
		game_manager.slime_reroll(Current.slime, 1, 0)
		## 恢复鼠标重置状态
		CursorManager.reset_cursor()
		reset_all_button()
		Current.total_coins -= 1
		
func reroll_color():
	var all_slime_array = Current.all_enemy_grid_index_array
	for grid in Current.all_grids_array:
		if grid.grid_index in all_slime_array:
			grid.target.show()
	if Current.grid_index in all_slime_array:
		for grid in Current.all_grids_array:
			if Current.grid_index == grid.grid_index:
				grid.attack.show()

func reroll_color_clicked():
	if Current.slime:
		game_manager.slime_reroll(Current.slime, 0, 1)
		## 恢复鼠标重置状态
		CursorManager.reset_cursor()
		reset_all_button()
		Current.total_coins -= 1
