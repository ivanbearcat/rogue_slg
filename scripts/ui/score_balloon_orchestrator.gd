extends Node2D
## 攻击后得分演出编排器（post-attack-score-balloon，design D3/D4 + 任务 2.3）
##
## 生命周期：skill_attack 一次攻击一场——new + add_child(game_manager) →
## setup_balloon(骰型得分) 在主飘字位出生气球 → perform(申报列表) 错峰发射 token →
## 气球定格并飞向计分板 → perform 返回（入账时刻由调用方解除静默 + 显示同步 + 脉冲）→
## queue_free。
##
## 配音（progression-sfx）：气球出生无声；token 到达播木琴音阶（第 n 笔正 token 播
## 第 min(n, 9) 阶、封顶第 9 阶，负分低八度不占号）；气球飞入总分入账时刻播
## match_10（MAX）收尾。
##
## token 规则（spec「token 错峰连发与来源归属」）：
##   - 按申报顺序（=管线执行顺序）每 0.2s 发射一枚，贝塞尔弧线约 0.6s 飞入气球；
##   - 连发窗口上限 2.5s：单发上限 MAX_INDIVIDUAL_TOKENS=9 枚
##     （第 i 枚起飞于 i×0.2s、到达于 i×0.2+0.6s，最后一枚到达 2.2s ≤ 窗口），
##     超出部分合并为一条汇总 token（起飞于 1.8s、到达 2.4s ≤ 窗口，纯数值无图标）；
##   - 起飞点为来源效果 BUFF/DEBUFF 栏图标全局坐标，起飞瞬间复用
##     EffectManager.buff_pop_effect 闪烁（纯 modulate，零布局影响）；
##     图标失效（mock/测试环境）时从气球位起飞，不阻断演出。
## 安全兜底：perform 内所有等待段带总时限（任务 4.3）——演出异常/中断时裁剪返回，
## 保证调用方的入账与锁释放逻辑必然执行。

const TOKEN_SCENE := preload("res://scenes/score_token.tscn")
const BALLOON_SCENE := preload("res://scenes/score_balloon.tscn")

## 观感校准常量（任务 5.3 目测定稿已回写）
## ── token 连发三参数（联动公式：上限枚数 = (窗口 − 飞行) ÷ 间隔）──
## TOKEN_INTERVAL：相邻 token 起飞的错峰间隔（读数从容度；5.3 定稿 0.35）
const TOKEN_INTERVAL := 0.35
## TOKEN_FLY_DURATION：单枚 token 弧线飞行时长
const TOKEN_FLY_DURATION := 0.6
## BURST_WINDOW：连发窗口——所有 token（含汇总）的到达时刻 ≤ 此值
##（5.3 定稿 9：owner 目测拍板自草案 2.5 放宽，允许多申报全单发细读；
## 正常满编全程 ≈ 窗口 9 + 定格 0.25 + 飞板 0.4 ≈ 9.65s < 兜底 15s ✓）
const BURST_WINDOW := 9
## MAX_INDIVIDUAL_TOKENS：单发 token 上限——前 N 条申报各发一枚（带来源
## 图标），超出部分合并为一条汇总（纯数值）。由窗口/间隔自动推导，改
## BURST_WINDOW 或 TOKEN_INTERVAL 即自动重算枚数（定稿 9/0.35 → 24 枚；
## 曾为死参数——声明后无逻辑读取，手改无效果，本次联动化）
const MAX_INDIVIDUAL_TOKENS := maxi(1, int((BURST_WINDOW - TOKEN_FLY_DURATION) / TOKEN_INTERVAL))
## 气球水平微调（5.3 定稿入口：英雄帧内角色不完全居中时补偿视觉偏差；
## 负值左移 / 正值右移，单位像素，0 = 文字中心对准 sprite 帧中心。
## 注：旧值 40 是对 _label_pivot 左上角缩放 bug 的补偿（文字中心曾吊在
## 节点左 40px）——bug 修复后归 0，否则反向偏右 40px）
const BALLOON_HERO_X_OFFSET := 0.0
## 气球出生位：英雄 sprite 头顶（5.3 目测定稿：锚点取 AnimatedSprite2D
## 视觉中心（英雄节点原点在格子角落，sprite 以原点 (8,9) 为中心绘制，
## 旧锚点用节点原点导致数字不在头顶）；头顶距离 = 半帧高 + 间隙。
## GAP 5.3 目测定稿：用户校准 6.0（文字底缘悬空于 sprite 顶上方约 12px，
## 观感"浮"于头顶；此前 -6 为底缘贴顶口径，目测反馈偏好上浮）
const BALLOON_HERO_GAP := 6.0
## ── 木琴音阶配音（progression-sfx；任务 4.1 试听校准入口，定稿值回写于此）──
## NEGATIVE_BASE_PITCH：负分低八度基准音高——spec「base_pitch 约 0.5，允许观感校准
## 微调」，design D3 定 0.5~0.7 区间试听；pitch 0.5 时音长约 ×2，若负分音偏"拖"可
## 调向 0.7
const NEGATIVE_BASE_PITCH := 0.5
## NEGATIVE_DEDUP_WINDOW：负 token 同键去重窗口——design 风险项「多枚负 token 连发
## 低八度重复叠放」的现成缓解（0.2s）；0 = 先听默认不去重，违和再启用
const NEGATIVE_DEDUP_WINDOW := 0.0
## 演出总时限兜底（正常全程 ≤3s；异常中断时强制收口，防结算挂起）
const EMERGENCY_TIMEOUT_MSEC := 15000

var _balloon: Node2D = null
var _tokens_in_flight: int = 0
var _deadline_msec: int = 0
## 图标纹理缓存（同来源多 token 复用；load 失败缓存 null 不重试）
var _icon_cache: Dictionary = {}
## 正分到达计数（progression-sfx 木琴音阶）：气球出生无声，第 n 笔正 token 到达播
## 第 min(n, 9) 阶（MAX 阶保留给气球入账收尾，见 perform 的 balloon_arrived）；
## 实例字段随编排器每场 queue_free 消亡，逐次攻击自动从第 1 阶重计（design D4，零显式清理）
var _positive_arrived: int = 0

## 气球出生：种子为骰型得分，悬停英雄头顶（替代旧攻击主飘字，无骰型名称标签）
func setup_balloon(seed: int) -> void:
	_balloon = BALLOON_SCENE.instantiate()
	add_child(_balloon)
	_balloon.setup(seed, _hero_head_position())

## 英雄 sprite 头顶世界坐标：AnimatedSprite2D 以节点原点为中心绘制帧，
## 锚点 = sprite 全局中心上移（半帧高 + 间隙）；sprite/帧缺失时回退英雄节点原点
func _hero_head_position() -> Vector2:
	var hero: Hero = Current.hero
	if hero == null:
		return position
	var sprite: AnimatedSprite2D = hero.get("animated_sprite_2d")
	if sprite == null:
		return hero.global_position
	var half_h: float = 8.0
	if sprite.sprite_frames != null:
		var tex: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		if tex != null:
			half_h = tex.get_height() * sprite.scale.y / 2.0
	return sprite.global_position + Vector2(BALLOON_HERO_X_OFFSET, -half_h - BALLOON_HERO_GAP)

## 演出主体（awaitable）：token 错峰连发 → 气球定格 → 飞向计分板。
## 返回即"气球到达计分板"时刻（含异常裁剪路径），调用方随即入账。
## 返回 bool 而非 void：调用方可保存协程 state 中途插入断言后接回等待
## （void 协程保存返回值会触发 "async function without await" 运行时错误）
func perform(declarations: Array) -> bool:
	_deadline_msec = Time.get_ticks_msec() + EMERGENCY_TIMEOUT_MSEC
	var burst: Array = declarations.duplicate()
	var summary_delta := 0
	if burst.size() > MAX_INDIVIDUAL_TOKENS:
		for d in burst.slice(MAX_INDIVIDUAL_TOKENS):
			summary_delta += int(d["delta"])
		burst.resize(MAX_INDIVIDUAL_TOKENS)
	## 统一发射清单：单发列表 + 可选汇总（汇总为最后一项，同样 0.2s 错峰起飞）
	var launch_list: Array = burst.duplicate()
	if summary_delta != 0:
		launch_list.append({"delta": summary_delta, "buff": null, "icon_path": ""})
	## 发射段内联于 perform（协程上下文）——fly_to/buff_pop_effect 为 void
	## coroutine，同步辅助函数中 fire-and-forget 会触发 GDScript 编译错误
	for i in launch_list.size():
		if i > 0 and not await _wait(TOKEN_INTERVAL):
			break
		var entry: Dictionary = launch_list[i]
		var buff = entry.get("buff", null)
		var token: Node2D = TOKEN_SCENE.instantiate()
		add_child(token)
		token.position = _launch_position(buff)
		token.setup(int(entry["delta"]), _load_icon(str(entry.get("icon_path", ""))))
		var panel := _effect_icon(buff)
		if panel != null:
			EffectManager.buff_pop_effect(panel)
		_tokens_in_flight += 1
		token.token_arrived.connect(_on_token_arrived.bind(token))
		token.fly_to(_balloon.position, TOKEN_FLY_DURATION)
	## 等全部 token 落入气球
	while _tokens_in_flight > 0:
		if not await _wait(0.05):
			break
	## 定格 + 划弧线飞向计分板总分位置
	## （信号轮询而非直 await freeze_and_fly_to：气球 tween 异常中断时
	## 由演出总时限裁剪返回，调用方的入账与锁释放逻辑必然执行——任务 4.3 兜底。
	## ⚠️ lambda 按值捕获局部标量：用 Array 引用穿透闭包，外部轮询才可见）
	if _balloon != null and is_instance_valid(_balloon):
		var board_target := _score_board_position()
		var arrived: Array = []
		## 入账收尾音：气球飞入总分的精确帧播 match_10（MAX，progression-sfx
		##「入账收尾最高阶」）——与 arrival 标记同帧，MAX 阶不参与 token 音阶
		_balloon.balloon_arrived.connect(
			func(_total: int) -> void:
				arrived.append(true)
				AudioManager.play_sfx("match_10"),
			CONNECT_ONE_SHOT)
		_balloon.freeze_and_fly_to(board_target)
		while arrived.is_empty():
			if not await _wait(0.05):
				break
		if is_instance_valid(_balloon):
			_balloon.queue_free()
		_balloon = null
	return true

## ---------- token 发射与吸收 ----------

func _on_token_arrived(delta: int, token: Node2D) -> void:
	_tokens_in_flight -= 1
	if _balloon != null and is_instance_valid(_balloon):
		_balloon.absorb(delta)
	token.queue_free()
	_play_arrival_sfx(delta)

## token 到达配音（progression-sfx 木琴音阶，与 absorb 数字滚动/弹跳脉冲同刻）：
##   正向 token（含超出单发上限的汇总）：计数 +1 后播第 min(n, 9) 阶，第 9 笔起
##     封顶第 9 阶（试听反馈定稿——MAX 阶保留给气球入账收尾，见 perform）；
##     零值申报上游已静默，到达的 token 必有符号
##   负向 token：播 match_1 低八度（NEGATIVE_BASE_PITCH），不推进音阶序号
func _play_arrival_sfx(delta: int) -> void:
	if delta > 0:
		_positive_arrived += 1
		AudioManager.play_sfx("match_%d" % mini(_positive_arrived, 9))
	elif delta < 0:
		AudioManager.play_sfx("match_1", 0.0, NEGATIVE_DEDUP_WINDOW, 0.0, NEGATIVE_BASE_PITCH)

## ---------- 归属定位 ----------

## 起飞点：来源效果图标全局坐标（BUFF 栏 buff_texture 优先 → DEBUFF 栏
## debuff_texture 回退）；图标失效时从气球位起飞（mock/测试环境不阻断）
func _launch_position(buff) -> Vector2:
	var panel := _effect_icon(buff)
	if panel != null:
		return panel.get_global_rect().get_center()
	return _balloon.position if _balloon != null else position

func _effect_icon(buff) -> Control:
	if buff == null:
		return null
	for tex in [buff.get("buff_texture"), buff.get("debuff_texture")]:
		if tex != null and is_instance_valid(tex) and tex.is_inside_tree():
			return tex
	return null

## 来源图标加载（buff_icon → debuff_icon 回退已由申报记录的 icon_path 承载；
## 空路径/加载失败 → null = 纯数值 token，不阻断）。
## 加载成功后按 alpha 内容 bbox 包 AtlasTexture（region = 内容区）：
## 透明边随来源美术漂移（普通图标内容最低仅占画布 53%，领主族满铺），
## token 的排版对齐画布 rect 会致图标-数字间隔随来源漂移；裁到内容区后
## 可见内容统一拉满 36×36 显示 rect，间隔唯一由排版常量决定
##（spec「token 图标与数字排版归一」）。逐 icon_path 扫描一次、缓存复用
func _load_icon(icon_path: String) -> Texture2D:
	if icon_path.is_empty():
		return null
	if not _icon_cache.has(icon_path):
		var tex: Texture2D = load(icon_path) if ResourceLoader.exists(icon_path) else null
		_icon_cache[icon_path] = _crop_to_content(tex)
	return _icon_cache[icon_path]

## 内容区裁剪：逐像素扫 alpha 边界得内容 bbox，AtlasTexture(region=bbox)
## 包装原纹理；扫描不可用/全透明时原样返回（不阻断）
func _crop_to_content(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return tex
	var min_x := img.get_width()
	var min_y := img.get_height()
	var max_x := -1
	var max_y := -1
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.001:
				if x < min_x:
					min_x = x
				if y < min_y:
					min_y = y
				if x > max_x:
					max_x = x
				if y > max_y:
					max_y = y
	if max_x < 0 or max_y < 0:
		return tex
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = tex
	atlas_tex.region = Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	return atlas_tex

## 计分板总分位置（世界坐标）：文字在 label 本地 rect 内的中心，
## 经 get_global_transform 投影到世界——stage_score 下有 0.5/0.5/0.45
## 三层嵌套 scale（有效≈0.11），字体度量值是本地单位，直接与全局 rect 坐标
## 相加会单位错配（位数变化→偏差每次不同，且被缩放比放大）。
## 对齐方式运行时读取（label 默认左对齐/垂直居中，theme 改动自动跟随）。
## mock/测试环境无 label_settings 时回退 rect 中心
func _score_board_position() -> Vector2:
	var gm = Current.game_manager
	if gm == null:
		return position
	var board = gm.get("total_score")
	if board == null:
		return position
	var settings = board.get("label_settings")
	if settings == null or settings.get("font") == null:
		return board.get_global_rect().get_center()
	## 落点按"入账后的新总分"测宽——气球到达时刻计分板即将同步显示的就是它
	##（spec「一次入账脉冲」）。label 当前 text 仍是静默期旧值：旧值位数短时
	## 测出的中心贴着列左缘（目测反馈"落在『分数』标题上"），必须用逻辑值。
	## 非战局 mock 环境（Current 未维护 _total_score 语义）回退 label 当前文字。
	var target_text := str(Current.get("_total_score"))
	if target_text.is_empty():
		target_text = str(board.text)
	var text_size: Vector2 = settings.font.get_string_size(
		target_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, settings.font_size)
	## 文字起点在本地 rect 内的对齐偏移（LEFT/TOP 起点为 0）
	var origin := Vector2.ZERO
	match board.horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			origin.x = (board.size.x - text_size.x) / 2.0
		HORIZONTAL_ALIGNMENT_RIGHT:
			origin.x = board.size.x - text_size.x
	match board.vertical_alignment:
		VERTICAL_ALIGNMENT_CENTER:
			origin.y = (board.size.y - text_size.y) / 2.0
		VERTICAL_ALIGNMENT_BOTTOM:
			origin.y = board.size.y - text_size.y
	## 本地文字中心 → 全局变换投影（祖先 scale 一次算清；
	## 位数变化时文字变宽，落点跟随文字实际中心）
	return board.get_global_transform() * (origin + text_size / 2.0)

## ---------- 安全兜底 ----------

## 分段等待：返回 false = 演出总时限已到（异常/中断裁剪，调用方仍会入账）
func _wait(seconds: float) -> bool:
	if Time.get_ticks_msec() > _deadline_msec:
		return false
	await get_tree().create_timer(seconds).timeout
	return Time.get_ticks_msec() <= _deadline_msec
