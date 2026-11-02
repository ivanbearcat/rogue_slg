shader_type canvas_item;

// 霸主图标家族色轮廓呼吸光：
// 沿 sprite 的 alpha 轮廓（图形外侧）画一圈细发光线，TIME 驱动明暗呼吸。
// 仅在 sprite 画布的透明区域绘制，不占用任何布局空间；sprite 本体绘制不变。

// 轮廓光颜色（传入 TooltipFormatter.FAMILY_COLORS[family]）
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// 轮廓半径（源像素，2 = 11px 显示下约 0.7px 细线）
uniform float thickness : hint_range(0.0, 6.0) = 2.0;
// 呼吸 alpha 下限/上限/周期
uniform float glow_alpha_min : hint_range(0.0, 1.0) = 0.25;
uniform float glow_alpha_max : hint_range(0.0, 1.0) = 0.80;
uniform float pulse_period : hint_range(0.1, 10.0) = 1.5;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	// 判定是否邻近图形（半径 thickness 内任一方向存在不透明像素）
	float has_solid = 0.0;
	for (int i = 0; i < 16; i++) {
		float ang = float(i) * 0.1963495408; // 2π/16
		vec2 dir = vec2(cos(ang), sin(ang));
		for (int r_i = 1; r_i <= int(thickness); r_i++) {
			has_solid = max(has_solid, texture(TEXTURE, UV + dir * TEXTURE_PIXEL_SIZE * float(r_i)).a);
		}
	}
	// 轮廓带 = 本像素非实体 且 邻近图形（sprite 画布边缘全透明，环不会顶到面板边界）
	float outline = (1.0 - step(0.5, base.a)) * step(0.001, has_solid);
	// 呼吸 alpha（TIME 驱动，周期 pulse_period）
	float breath = 0.5 + 0.5 * sin(TIME * 6.2831853 / pulse_period);
	float glow = outline * mix(glow_alpha_min, glow_alpha_max, breath);
	// 环区域向家族色混合；sprite 本体保持原样
	COLOR = vec4(mix(base.rgb, glow_color.rgb, glow), max(base.a, glow));
}
