extends HeroState


func enter():
	print(owner.hero_name, "进入end")
	owner.animated_sprite_2d.set_frame_and_progress(1, 1.0)
	owner.animated_sprite_2d.stop()
