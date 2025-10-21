extends HeroState


func enter():
	print(owner.hero_name, "进入end")
	owner.animated_sprite_2d.play(owner.hero_name + "_end")
