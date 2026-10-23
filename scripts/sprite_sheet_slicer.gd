class_name SpriteSheetSlicer
extends RefCounted

## 帧动画切片工具类
## 按等距网格把sprite sheet切成逐帧AtlasTexture，装配成SpriteFrames交给AnimatedSprite2D播放
## 切帧结果按sheet路径(+切片参数)为key静态缓存，避免每次悬浮重复分配

static var _frames_cache: Dictionary = {}  # key -> SpriteFrames

## 从sheet生成帧序列SpriteFrames
## sheet_path: sheet纹理路径（切帧结果按其缓存复用）
## cols/rows: 网格列/行数（frame index按行优先展开）
## frame_begin/frame_end: 1-based闭区间帧序号，可裁掉素材首尾不该出现的帧（如尾部空白帧）
## fps: 播放帧率；loop: 是否循环
## 返回null表示sheet或参数无效（调用方应退化为纯文本占位模式）
static func build_frames(sheet_path: String, cols: int, rows: int,
		frame_begin: int, frame_end: int, fps: float, loop: bool) -> SpriteFrames:
	if sheet_path.is_empty() or cols <= 0 or rows <= 0:
		return null
	var key := "%s#%dx%d#%d-%d#%.1f#%s" % [sheet_path, cols, rows, frame_begin, frame_end, fps, str(loop)]
	if _frames_cache.has(key):
		return _frames_cache[key]
	# 预检避免load()对无效路径刷报错
	if not ResourceLoader.exists(sheet_path, "Texture2D"):
		return null
	var sheet: Texture2D = load(sheet_path)
	if sheet == null:
		return null
	var total_frames := cols * rows
	# 帧范围夹取到有效帧区间
	var begin_i := clampi(frame_begin, 1, total_frames)
	var end_i := clampi(frame_end, 1, total_frames)
	if end_i < begin_i:
		return null
	var cell_size := Vector2(sheet.get_width() / float(cols), sheet.get_height() / float(rows))
	var sprite_frames := SpriteFrames.new()
	sprite_frames.set_animation_loop("default", loop)
	sprite_frames.set_animation_speed("default", fps)
	for i in range(begin_i, end_i + 1):
		var index0 := i - 1
		var col := index0 % cols
		var row := floori(float(index0) / cols)
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(col * cell_size.x, row * cell_size.y), cell_size)
		sprite_frames.add_frame("default", atlas)
	_frames_cache[key] = sprite_frames
	return sprite_frames
