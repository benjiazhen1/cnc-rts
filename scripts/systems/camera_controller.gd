## 相机控制器
##
## 管理2D相机的移动和缩放。
## 支持WASD/方向键平移、鼠标边缘滚动和滚轮缩放。
## 移动范围受限于地图边界。
class_name CameraController
extends Camera2D

# === 移动常量 ===

## 键盘平移速度（像素/秒）
const PAN_SPEED: float = 500.0

## 鼠标边缘滚动区域大小（像素）
const EDGE_SCROLL_ZONE: int = 30

## 鼠标边缘滚动速度（像素/秒）
const EDGE_SCROLL_SPEED: float = 400.0

# === 缩放常量 ===

## 最小缩放值
const MIN_ZOOM: float = 0.5

## 最大缩放值
const MAX_ZOOM: float = 2.0

## 每次滚轮缩放增量
const ZOOM_SPEED: float = 0.1

# === 地图边界常量 ===

## 地图边界：左边
const MAP_LIMIT_LEFT: int = 0

## 地图边界：上边
const MAP_LIMIT_TOP: int = 0

## 地图边界：右边
const MAP_LIMIT_RIGHT: int = 4096

## 地图边界：下边
const MAP_LIMIT_BOTTOM: int = 4096

# === 生命周期 ===

func _ready() -> void:
	# 初始化相机位置到地图中心
	position = Vector2(MAP_LIMIT_RIGHT / 2, MAP_LIMIT_BOTTOM / 2)
	# 设置相机边界
	limit_left = MAP_LIMIT_LEFT
	limit_top = MAP_LIMIT_TOP
	limit_right = MAP_LIMIT_RIGHT
	limit_bottom = MAP_LIMIT_BOTTOM


func _process(delta: float) -> void:
	_handle_keyboard_pan(delta)
	_handle_edge_scroll()
	_handle_zoom()
	_clamp_to_bounds()


# === 核心功能 ===

## 处理WASD/方向键平移
func _handle_keyboard_pan(delta: float) -> void:
	var pan_direction := Vector2.ZERO

	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		pan_direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		pan_direction.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		pan_direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		pan_direction.x += 1

	if pan_direction != Vector2.ZERO:
		pan_direction = pan_direction.normalized()
		position += pan_direction * PAN_SPEED * delta


## 处理鼠标边缘滚动
func _handle_edge_scroll() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var viewport_size := get_viewport().get_visible_rect().size
	var scroll_direction := Vector2.ZERO

	# 左边缘
	if mouse_pos.x < EDGE_SCROLL_ZONE:
		scroll_direction.x -= 1
	# 右边缘
	elif mouse_pos.x > viewport_size.x - EDGE_SCROLL_ZONE:
		scroll_direction.x += 1

	# 上边缘
	if mouse_pos.y < EDGE_SCROLL_ZONE:
		scroll_direction.y -= 1
	# 下边缘
	elif mouse_pos.y > viewport_size.y - EDGE_SCROLL_ZONE:
		scroll_direction.y += 1

	if scroll_direction != Vector2.ZERO:
		scroll_direction = scroll_direction.normalized()
		position += scroll_direction * EDGE_SCROLL_SPEED * get_process_delta_time()


## 处理鼠标滚轮缩放
func _handle_zoom() -> void:
	var zoom_delta := Input.get_axis(KEY_MINUS, KEY_EQUAL)
	if zoom_delta != 0:
		var new_zoom := zoom + Vector2(zoom_delta * ZOOM_SPEED, zoom_delta * ZOOM_SPEED)
		new_zoom = new_zoom.clamp(Vector2(MIN_ZOOM, MIN_ZOOM), Vector2(MAX_ZOOM, MAX_ZOOM))
		zoom = new_zoom


## 限制相机位置在地图边界内
func _clamp_to_bounds() -> void:
	position.x = clamp(position.x, MAP_LIMIT_LEFT, MAP_LIMIT_RIGHT)
	position.y = clamp(position.y, MAP_LIMIT_TOP, MAP_LIMIT_BOTTOM)
