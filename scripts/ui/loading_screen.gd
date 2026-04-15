# 加载屏幕
extends Control

signal progress_updated(value: float)

@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var loading_label: Label = $VBoxContainer/LoadingLabel
@onready var tip_label: Label = $VBoxContainer/TipContainer/TipLabel
@onready var tip_title: Label = $VBoxContainer/TipContainer/TipTitle

var tips: Array[String] = [
	"快捷键: 鼠标左键选择单位, 右键移动单位",
	"建造建筑需要足够的资源和对战金",
	"不同的单位有不同的攻击范围和移动速度",
	"善用地形来获得战斗优势",
	"空中单位可以越过障碍物",
	"多个生产建筑可以同时生产单位",
	"升级指挥中心可以解锁更多建筑"
]

var current_tip_index: int = 0

func _ready():
	randomize()
	progress_bar.value = 0
	loading_label.text = "Loading..."
	show_random_tip()

func show_random_tip():
	current_tip_index = randi() % tips.size()
	tip_title.text = "提示"
	tip_label.text = tips[current_tip_index]

func set_progress(value: float) -> void:
	progress_bar.value = clamp(value, 0.0, 100.0)
	progress_updated.emit(progress_bar.value)

func set_loading_text(text: String) -> void:
	loading_label.text = text

func set_tip(tip_text: String) -> void:
	tip_label.text = tip_text

func increment_progress(amount: float = 1.0) -> void:
	set_progress(progress_bar.value + amount)

func reset() -> void:
	progress_bar.value = 0
	loading_label.text = "Loading..."
	show_random_tip()
