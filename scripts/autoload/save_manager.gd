extends Node

## SaveManager —— 单槽 run 存档 autoload
##
## 职责（design D1/D3/D4/D6）：
##   1) 回合边界快照：capture() 由战局流程在"敌方回合完全结束、pre_hero_turn 时序
##      尚未执行"的干净点调用，只刷新内存快照，不落盘
##   2) 退出即保存：flush_to_disk() 只把最近一次内存快照写盘——不拍新快照、不等演出
##      （覆盖三个出口：暂停菜单"返回主菜单"/"退出游戏"、窗口关闭按钮 X）
##   3) 编解码：JSON → gzip → AES-256-CBC（FileAccess.open_encrypted），
##      密文头 = [magic "RGSAVE1"][HMAC-SHA256(密文body)]
##   4) 原子写：save.tmp 写入并校验字节完整后 rename → save.bin；坏档转存 save.corrupt
##   5) 读档挂载：restoring_run 标记 + pending_save_data，由 game_manager._ready 恢复分支消费
##   6) 窗口关闭拦截：_ready 设 set_auto_accept_quit(false)，WM_CLOSE_REQUEST 收口为退出即保存
##
## ⚠️ 成对修改纪律：run 级状态字段的新增/删除必须同时修改 Current 的
## reset_run_state() / export_run_state() / apply_run_state() 三处
## （scripts/autoload/current.gd），否则新字段不被存档、读档后回退默认值。
## 本文件的 capture() 是快照编排入口（与 current.gd 的三处互为对照清单）。

const SAVE_PATH := "user://save.bin"
const STAGING_PATH := "user://save.tmp"
const CORRUPT_PATH := "user://save.corrupt"
const _CODEC_TMP_PATH := "user://.save_codec.tmp"
## 密文头：[magic "RGSAVE1"][HMAC-SHA256(密文body)]，头长 = 7 + 32 字节
const MAGIC := "RGSAVE1"
const SAVE_VERSION := 1

## ⚠️ 存档密钥盐片段 A（三段散落常量之一，完整密钥不出现在任何单一文件；
## 其余片段见 current.gd / buff_system.gd。改动任一片段会使现有存档失效 → 走坏档路径）
const _SAVE_SALT_A := "RG|SALT|A|9d13f2ab7c40e516"

## 内存快照：最近一次回合边界的完整 run 状态（退出落盘只写这份）
var _snapshot: Dictionary = {}
## 读档挂载：splash"继续"成功解码后挂入；game_manager._ready 恢复分支消费后由 finish_restore 清空
var pending_save_data: Dictionary = {}
## 恢复标记：game_manager._ready 依此分叉，跳过新开 run 的初始化链
var restoring_run: bool = false

var _derived_key := PackedByteArray()
## 最近一次 has_valid_save() 成功解码出的 meta（供主菜单展示进度）
var _cached_meta: Dictionary = {}
## 窗口关闭请求只收口一次（连点 X 防重入）
var _close_requested := false


func _ready() -> void:
	## 拦截窗口关闭按钮（X / Alt+F4）：系统关闭请求不再直接杀进程，
	## 改由 _notification 收口为"退出即保存"（task 4.3）
	get_tree().set_auto_accept_quit(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_close_on_window_request()


## ============================================================
## 编解码层（design D3）
## ============================================================

## 密钥派生：三段散落盐 + 版本号，哈希为 32 字节 AES-256 密钥。
## 版本号参与派生 → save_version 变更天然弃置旧格式档。
func _get_key() -> PackedByteArray:
	if _derived_key.is_empty():
		var material := "%s|%s|%s|%d" % [
			_SAVE_SALT_A,
			Current._SAVE_SALT_B,
			BuffSystem._SAVE_SALT_C,
			SAVE_VERSION
		]
		_derived_key = material.sha256_buffer()
	return _derived_key

## encode(Dictionary)：JSON.stringify → gzip → AES-256-CBC → 附加 magic + HMAC 头。
## 任何一步失败返回空 PackedByteArray（失败标记），不抛异常。
func encode(data: Dictionary) -> PackedByteArray:
	var json_text := JSON.stringify(data)
	var compressed: PackedByteArray = json_text.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
	if compressed.is_empty():
		push_warning("[SaveManager] encode 失败：gzip 压缩输出为空")
		return PackedByteArray()
	var cipher := _aes_encrypt_bytes(compressed)
	if cipher.is_empty():
		push_warning("[SaveManager] encode 失败：AES 加密输出为空")
		return PackedByteArray()
	var hmac := Crypto.new().hmac_digest(HashingContext.HASH_SHA256, _get_key(), cipher)
	var payload := PackedByteArray()
	payload.append_array(MAGIC.to_ascii_buffer())
	payload.append_array(hmac)
	payload.append_array(cipher)
	return payload

## decode(bytes)：验 HMAC → 解密 → 解压 → JSON.parse。
## 任何一步失败返回 null（失败标记），成功返回解析后的 Dictionary。
func decode(bytes: PackedByteArray) -> Variant:
	var header_len := MAGIC.to_ascii_buffer().size() + 32
	if bytes.size() <= header_len:
		return null
	## magic 校验
	var magic_buf := MAGIC.to_ascii_buffer()
	for i in magic_buf.size():
		if bytes[i] != magic_buf[i]:
			return null
	## HMAC 校验（密文 body 任一字节被改即拒绝；常数时间比较防时序侧信道）
	var expected_hmac := bytes.slice(magic_buf.size(), header_len)
	var body := bytes.slice(header_len)
	var actual_hmac := Crypto.new().hmac_digest(HashingContext.HASH_SHA256, _get_key(), body)
	if not Crypto.new().constant_time_compare(actual_hmac, expected_hmac):
		return null
	var compressed := _aes_decrypt_bytes(body)
	if compressed.is_empty():
		return null
	## max_output_size=-1：不设上限（本作 JSON 载荷量级远小于攻击面场景）
	var json_bytes := compressed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	if json_bytes.is_empty():
		return null
	return JSON.parse_string(json_bytes.get_string_from_utf8())

## AES-256-CBC 加密：经 FileAccess.open_encrypted 落临时密文文件再读回原始密文字节。
## （Godot 未暴露内存态 AES，open_encrypted 是引擎内唯一的对称加密通路）
func _aes_encrypt_bytes(plain: PackedByteArray) -> PackedByteArray:
	var f := FileAccess.open_encrypted(_CODEC_TMP_PATH, FileAccess.WRITE, _get_key())
	if f == null:
		push_warning("[SaveManager] 编解码临时文件打开失败: %s" % _CODEC_TMP_PATH)
		return PackedByteArray()
	f.store_buffer(plain)
	f = null
	var cipher := _read_file_bytes(_CODEC_TMP_PATH)
	_remove_file(_CODEC_TMP_PATH)
	return cipher

## AES-256-CBC 解密：密文字节写临时文件后以 open_encrypted 读回明文。
func _aes_decrypt_bytes(cipher: PackedByteArray) -> PackedByteArray:
	var f := FileAccess.open(_CODEC_TMP_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("[SaveManager] 编解码临时文件写入失败: %s" % _CODEC_TMP_PATH)
		return PackedByteArray()
	f.store_buffer(cipher)
	f = null
	var ef := FileAccess.open_encrypted(_CODEC_TMP_PATH, FileAccess.READ, _get_key())
	if ef == null:
		_remove_file(_CODEC_TMP_PATH)
		push_warning("[SaveManager] 解密失败：open_encrypted 打不开密文")
		return PackedByteArray()
	var plain := ef.get_buffer(ef.get_length())
	ef = null
	_remove_file(_CODEC_TMP_PATH)
	return plain


## ============================================================
## 快照（capture）与灌入（apply）
## ============================================================

## 回合边界快照：由战局流程在确定位置调用（见 game_manager._capture_turn_boundary）。
## 快照只进内存不落盘；中途锁定期不会被调用（调用点本身就在锁释放之后）。
func capture() -> void:
	if not _can_capture():
		return
	_snapshot = _build_snapshot(Current.game_manager)
	print("[SaveManager] 回合边界快照：关卡 %d · 回合 %d" % [
		int(_snapshot["meta"]["stage"]), int(_snapshot["meta"]["round"])])


func _can_capture() -> bool:
	if Current.game_manager == null or not is_instance_valid(Current.game_manager):
		return false
	if Current.hero == null or not is_instance_valid(Current.hero):
		return false
	return true

func _build_snapshot(gm: Node) -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"meta": {
			"hero": Current.selected_hero,
			"stage": Current._count_stage,
			"round": Current._count_round,
			"saved_at": Time.get_datetime_string_from_system(),
		},
		"run_state": Current.export_run_state(),
		"board": _export_board(gm),
		"shop": _export_shop(gm),
		"buffs": {"rows": BuffSystem.save_buff_rows()},
		## 顶层常驻字段：BuffSystem.resonance_ramp 是唯一活在 BuffSystem 上的
		## 跨关卡数值，reset_run_state 清单覆盖不到（design D5）
		"resonance_ramp": BuffSystem.resonance_ramp,
	}

## 棋盘实体展平（design D2）：节点 → 数据行，Vector2 一律存 [x, y]。
## pending = 预生成待入场的史莱姆（未入树，点数在入场掷骰时才决定，故不存点数）。
func _export_board(gm: Node) -> Dictionary:
	var slimes: Array = []
	for slime in gm.enemys.get_children():
		if not is_instance_valid(slime):
			continue
		slimes.append(_export_slime_row(slime, true))
	var pending: Array = []
	for slime in gm._slime_create_array:
		if not is_instance_valid(slime):
			continue
		pending.append(_export_slime_row(slime, false))
	var last_created: Array = []
	for slime in Current.last_slime_create_array:
		if is_instance_valid(slime):
			last_created.append(_vec_to_int_arr(slime.enemy_grid_index))
	return {
		"hero": {
			"hero_grid_index": _vec_to_int_arr(Current.hero.hero_grid_index),
			"hero_movement": int(Current.hero.hero_movement),
		},
		"slimes": slimes,
		"pending": pending,
		"last_created": last_created,
	}

## 史莱姆数据行：颜色（场景名映射）/点数/HP/精英/BOSS/能量/门槛。
## with_point=false 用于未入树的预生成史莱姆（dice 未初始化，点数入场时才随机决定）。
func _export_slime_row(slime: Node, with_point: bool) -> Dictionary:
	var color: String = Tools.SLIME_COLOR_DICT.get(Tools.fetch_slime_scene(slime), "green")
	var row := {
		"grid": _vec_to_int_arr(slime.enemy_grid_index),
		"color": color,
		"hp": int(slime.enemy_hp),
		"enemy_type": int(slime.enemy_type),
		"elite": slime.is_elite,
		"boss": slime.is_boss,
		"power": _is_power_slime(slime),
		"gate_type": str(slime.gate_type),
		"gate_count": int(slime.gate_count),
	}
	if with_point:
		row["point"] = int(slime.dice_point)
	return row

## 能量史莱姆判定（口径与 Current.power_slime_array 一致：高光 + 青色描边）
func _is_power_slime(slime: Node) -> bool:
	## 未入树的预生成史莱姆（pending）其 @onready 引用尚未解析，材质判定在此无效；
	## 能量史莱姆只以入树节点存在（_create_power_slime），未入树一律按普通史莱姆导出
	var sprite = slime.get("animated_sprite_2d")
	if sprite == null or sprite.material == null:
		return false
	return sprite.material.get_shader_parameter("is_high_light") == true and \
		sprite.material.get_shader_parameter("outline_color") == Color(0.0, 18.892, 18.892)

## 商店与关卡状态（task 2.2）
func _export_shop(gm: Node) -> Dictionary:
	return {
		"buff_rows": [gm.shop_buff_1, gm.shop_buff_2, gm.shop_buff_3],
		"bought": gm.shop_buff_bought.duplicate(),
		"lock_states": [
			gm.buff_lock_button_1.button_pressed,
			gm.buff_lock_button_2.button_pressed,
			gm.buff_lock_button_3.button_pressed,
		],
		"refresh_cost": int(gm.buff_refresh_cost),
		"coin_skill_row": gm.shop_coin_skill_row.duplicate(true),
		"coin_skill_bought": gm.shop_coin_skill_bought,
		"appeared_coin_skill_ids": gm.appeared_coin_skill_ids.duplicate(),
		"pending_shop_skill": gm.pending_shop_skill.duplicate(true),
		"used_debuff_ids": gm._used_debuff_ids.duplicate(),
	}

## 读档灌入编排：Current 状态直写（零 setter）→ resonance_ramp → 统一 UI 刷新。
## 由 game_manager._ready 恢复分支在棋盘/buff/商店重建完成后调用。
func apply(data: Dictionary) -> void:
	Current.apply_run_state(data.get("run_state", {}))
	BuffSystem.resonance_ramp = float(data.get("resonance_ramp", 0.0))
	Current.refresh_all_ui()

## 供测试/检查读取最近一次快照（只读）
func get_last_snapshot() -> Dictionary:
	return _snapshot


## ============================================================
## 落盘 / 坏档处置 / 读档入口（task 1.3 / 1.4 / 4.1）
## ============================================================

## 退出即保存：把最近一次回合边界内存快照落盘。
## 只写盘：不拍新快照、不等待演出（规格"退出动作即保存"）。
## 可选参数仅用于测试注入目标路径；返回是否落盘成功。
func flush_to_disk(snapshot: Dictionary = {}) -> bool:
	var snap := _snapshot if snapshot.is_empty() else snapshot
	if snap.is_empty():
		print("[SaveManager] flush_to_disk：无可用回合边界快照，跳过落盘")
		return false
	var payload := encode(snap)
	if payload.is_empty():
		return false
	return _atomic_write(payload, SAVE_PATH)

## 原子写：写入 save.tmp → 回读校验字节完整 → rename 覆盖 save.bin。
## 任一步失败保留旧 save.bin 原样（主菜单"继续"反映最后成功存档状态）。
func _atomic_write(payload: PackedByteArray, target_path: String) -> bool:
	var staging := target_path.get_basename() + ".tmp"
	var f := FileAccess.open(staging, FileAccess.WRITE)
	if f == null:
		push_warning("[SaveManager] 落盘失败：无法打开暂存文件 %s (err=%d)" % [staging, FileAccess.get_open_error()])
		return false
	f.store_buffer(payload)
	f = null
	var readback := _read_file_bytes(staging)
	if readback != payload:
		push_warning("[SaveManager] 落盘失败：暂存文件字节校验不完整 (%s)" % staging)
		_remove_file(staging)
		return false
	## 本类所有路径均为 user:// 根路径，统一在 user:// DirAccess 内操作
	## （get_base_dir 对 "user://save.bin" 会截出无效的 "user:/"，不使用）
	var da := DirAccess.open("user://")
	if da == null or da.rename(staging.get_file(), target_path.get_file()) != OK:
		push_warning("[SaveManager] 落盘失败：暂存文件改名失败 %s → %s" % [staging, target_path])
		return false
	return true

## 坏档隔离：保留原字节转存诊断文件 save.corrupt，并删除主存档槽
func _quarantine(bytes: PackedByteArray) -> void:
	var f := FileAccess.open(CORRUPT_PATH, FileAccess.WRITE)
	if f != null:
		f.store_buffer(bytes)
		f = null
	_remove_file(SAVE_PATH)
	print("[SaveManager] 坏档已隔离：原字节转存 %s" % CORRUPT_PATH)

## 门控查询（design D6）：文件存在 + 完整性校验通过 + 版本可识别。
## 校验失败（含坏档）时同时执行坏档隔离，主菜单"继续"据此保持禁用态。
func has_valid_save() -> bool:
	_cached_meta = {}
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var data := read_save_data()
	if data.is_empty():
		return false
	_cached_meta = data.get("meta", {})
	return true

## 进度展示（splash"继续"按钮文案）：{stage, round}；无有效档返回空 Dictionary
func get_save_progress() -> Dictionary:
	if _cached_meta.is_empty() and not has_valid_save():
		return {}
	return {
		"stage": int(_cached_meta.get("stage", 0)),
		"round": int(_cached_meta.get("round", 0)),
	}

## 读取并解码主存档槽；解码失败或版本不可识别时执行坏档隔离并返回空 Dictionary
func read_save_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var bytes := _read_file_bytes(SAVE_PATH)
	var data: Variant = decode(bytes)
	if typeof(data) != TYPE_DICTIONARY:
		_quarantine(bytes)
		return {}
	if int(data.get("save_version", -1)) != SAVE_VERSION:
		_quarantine(bytes)
		print("[SaveManager] 存档版本不可识别（%s ≠ %d），按坏档处置" % [
			str(data.get("save_version")), SAVE_VERSION])
		return {}
	return data

## splash"继续"入口：挂载读档数据 + 置恢复标记（随后 change_scene 进战局，
## game_manager._ready 恢复分支消费）
func begin_restore(data: Dictionary) -> void:
	pending_save_data = data
	restoring_run = true

## 恢复收口：清除恢复标记与挂载数据（规格：无 restoring 残留标记）
func finish_restore() -> void:
	restoring_run = false
	pending_save_data = {}

## run 结束清档（结算画面两个出口调用）：删除主存档槽
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		_remove_file(SAVE_PATH)
		print("[SaveManager] run 结束：存档槽已清空")


## 窗口关闭收口：落盘最近一次回合边界快照后退出进程。
## 与暂停菜单"退出游戏"同语义、同纪律：只写盘、不拍新快照、不等演出；
## 无可用快照（如主菜单直关）则跳过落盘直接退出。
func _close_on_window_request() -> void:
	if _close_requested:
		return
	_close_requested = true
	_save_on_window_close()
	get_tree().quit()

## 落盘收口（测试可直接调用，验证快照内容）；返回是否落盘成功
func _save_on_window_close() -> bool:
	if not flush_to_disk():
		print("[SaveManager] 窗口关闭：无可用回合边界快照或落盘失败，跳过保存")
		return false
	print("[SaveManager] 窗口关闭：最近回合边界快照已落盘（关卡 %d · 回合 %d）" % [
		int(_snapshot["meta"]["stage"]), int(_snapshot["meta"]["round"])])
	return true

## ============================================================
## 内部文件辅助
## ============================================================

func _read_file_bytes(path: String) -> PackedByteArray:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return PackedByteArray()
	var bytes := f.get_buffer(f.get_length())
	f = null
	return bytes

func _remove_file(path: String) -> void:
	var da := DirAccess.open("user://")
	if da != null:
		da.remove(path.get_file())

func _vec_to_int_arr(v: Vector2) -> Array:
	return [int(v.x), int(v.y)]
