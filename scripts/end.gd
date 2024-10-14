extends HeroState


func enter():
	print(Current.hero.hero_name, "进入end")
	Current.move_state_hero = null
	Current.hero.animated_sprite_2d.set_frame_and_progress(1, 1.0)
	Current.hero.animated_sprite_2d.stop()
