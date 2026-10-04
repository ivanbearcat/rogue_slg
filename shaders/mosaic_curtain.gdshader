shader_type canvas_item;

// 马赛克帘子转场
// amount  : 0=完全透出下层画面, 1=完全黑幕
// opening : 0=铺帘阶段(块按"行"自上而下铺), 1=拉帘阶段(块按"列"从中间向两侧拉开)
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float opening : hint_range(0.0, 1.0) = 0.0;
uniform float tile_px = 24.0;
uniform vec4 curtain_color : source_color = vec4(0.03, 0.03, 0.06, 1.0);

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 screen_px = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 tile_id = floor(SCREEN_UV / SCREEN_PIXEL_SIZE / tile_px);
	vec2 tile_count = max(floor(screen_px / tile_px), vec2(1.0));
	float rnd1 = hash12(tile_id);
	float rnd2 = hash12(tile_id + vec2(37.17, 61.7));

	// 帘子铺开顺序：铺帘=按行自上而下；拉帘=按列从中间向两侧；均带少量随机抖动
	float row_norm = tile_id.y / tile_count.y;
	float center_norm = abs(tile_id.x + 0.5 - tile_count.x * 0.5) / max(tile_count.x * 0.5, 1.0);
	float order = mix(row_norm, center_norm, opening);
	order = mix(order, rnd1, 0.25);

	float arrive = order * 0.6;                               // 该块变为马赛克的时刻
	float cover_at = min(arrive + 0.32 + rnd2 * 0.08, 0.995); // 该块完全变黑的时刻
	float local = clamp((amount - arrive) / max(cover_at - arrive, 0.001), 0.0, 1.0);

	if (local <= 0.0) {
		// 帘子未到：直接透出下层画面
		COLOR = vec4(0.0);
	} else if (local >= 1.0) {
		// 已铺满：黑幕（保留极轻微静噪闪烁，避免死黑）
		float shimmer = 1.0 - 0.03 * hash12(tile_id + vec2(floor(TIME * 6.0)));
		COLOR = vec4(curtain_color.rgb * shimmer, 1.0);
	} else {
		// 过渡带：以马赛克块取样下层画面并随机闪烁，随进度渐变成黑
		vec2 tile_center = (tile_id + 0.5) * tile_px * SCREEN_PIXEL_SIZE;
		vec3 mosaic = texture(screen_tex, tile_center).rgb;
		float flicker = 0.35 + 0.65 * hash12(tile_id + vec2(floor(TIME * 10.0)) * 7.31);
		vec3 c = mix(mosaic * flicker, curtain_color.rgb, smoothstep(0.2, 1.0, local));
		COLOR = vec4(c, 1.0);
	}
}
