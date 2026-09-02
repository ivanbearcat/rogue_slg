extends Node2D
## 棋子格节点：仅承载悬停/技能视觉状态引用。
## 悬停行为（cursor 白框、attack 红框、Current 状态写入）已迁移至
## hover_tracker.gd（渲染帧数学换算），本脚本不再处理 Area2D 鼠标事件。

@onready var range: Sprite2D = $Area2D/range
@onready var cursor: Sprite2D = $Area2D/cursor
@onready var warning: Sprite2D = $Area2D/warning
@onready var target: Sprite2D = $Area2D/target
@onready var attack: Sprite2D = $Area2D/attack
@onready var select: Sprite2D = $Area2D/select

var grid_index: Vector2
