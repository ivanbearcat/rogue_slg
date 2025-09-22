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
	EventBus.subscribe("add_power", add_power)
	EventBus.subscribe("add_power_clicked", add_power_clicked)

func _on_timer_timeout():
	## 重掷按钮
	if game_manager.reroll_button.button_pressed == true:
		game_manager.reroll_button_label.position.y = 1
	else:
		game_manager.reroll_button_label.position.y = 0
	## 按钮1
	if game_manager.coin_skill_1.button_pressed == true:
		game_manager.coin_skill_1_icon.position.y = 4.25
		game_manager.q_texture.position.y = 3
	else:
		game_manager.coin_skill_1_icon.position.y = 3.25
		game_manager.q_texture.position.y = 2
	## 按钮2
	if game_manager.coin_skill_2.button_pressed == true:
		game_manager.coin_skill_2_icon.position.y = 4.25
		game_manager.w_texture.position.y = 4
	else:
		game_manager.coin_skill_2_icon.position.y = 3.25
		game_manager.w_texture.position.y = 3
	## 按钮3
	if game_manager.coin_skill_3.button_pressed == true:
		game_manager.coin_skill_3_icon.position.y = 4.25
		game_manager.e_texture.position.y = 4
	else:
		game_manager.coin_skill_3_icon.position.y = 3.25
		game_manager.e_texture.position.y = 3

func _clicked_public_action(coin_skill_name):
	## 扣除费用
	for row in Current.coin_skill_array_dict:
		if row["coin_skill_id"] == coin_skill_name:
			Current.total_coins -= row["coin_skill_cost"]
	## 恢复所有UI初始状态
	CursorManager.reset_cursor()

func reset_all_button():
	for button in [
		game_manager.reroll_button,
		game_manager.coin_skill_1, 
		game_manager.coin_skill_2, 
		game_manager.coin_skill_3
		]:
		if button.button_pressed == true:
			button.button_pressed = false
	if game_manager.reroll_button_label.position.y != 0:
		game_manager.reroll_button_label.position.y = 0
	for icon in [game_manager.coin_skill_1_icon, game_manager.coin_skill_2_icon, game_manager.coin_skill_3_icon]:
		if icon.position.y != 3.25:
			icon.position.y = 3.25
	if game_manager.q_texture.position.y != 2:
		game_manager.q_texture.position.y = 2
	for texture in [game_manager.w_texture, game_manager.e_texture]:
		if texture.position.y != 3:
			texture.position.y = 3

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
		_clicked_public_action("reroll_all")
		
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
		_clicked_public_action("reroll_dice")
		
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
		_clicked_public_action("reroll_color")
		
func add_power():
	for grid in Current.all_grids_array:
		if Current.hero.hero_grid_index == grid.grid_index:
			grid.target.show()

func add_power_clicked():
	if Current.grid_index == Current.hero.hero_grid_index and Current.power < Current.max_power:
		Current.power += 1
		_clicked_public_action("add_power")
	else:
		CursorManager.reset_cursor()
