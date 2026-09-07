class_name ClearStageUI
extends CanvasLayer
## 过关结算界面子场景：内部节点引用集中持有，main 侧 game_manager 经实例根访问
## （% 唯一名仅在本场景内部可解析，子场景化后 main 无法直接 % 引用，故引用下放至此）

@onready var clear_stage_label: Label = %clear_stage_label
@onready var stage_clear_label_1: Label = %stage_clear_label_1
@onready var stage_clear_label_2: Label = %stage_clear_label_2
@onready var stage_clear_label_3: Label = %stage_clear_label_3
@onready var stage_coin_label_1: Label = %stage_coin_label_1
@onready var stage_coin_label_2: Label = %stage_coin_label_2
@onready var stage_coin_label_3: Label = %stage_coin_label_3
@onready var stage_coin_label_4: Label = %stage_coin_label_4
@onready var stage_coin_rlabel_1: RichTextLabel = %stage_coin_rlabel_1
@onready var stage_coin_rlabel_2: RichTextLabel = %stage_coin_rlabel_2
@onready var stage_coin_rlabel_3: RichTextLabel = %stage_coin_rlabel_3
@onready var stage_coin_rlabel_4: RichTextLabel = %stage_coin_rlabel_4
@onready var paper_texture: TextureRect = %paper_texture
@onready var stage_clear_button: TextureButton = %stage_clear_button
