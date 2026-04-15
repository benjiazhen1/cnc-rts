## Settings Manager
## Manages graphics, audio, and gameplay settings with save/load functionality.
class_name SettingsManager
extends Node

# ──────────────────────────────── Constants ────────────────────────────────

const SETTINGS_FILE_PATH := "user://settings.json"

# Graphics defaults
const DEFAULT_RESOLUTION := Vector2i(1920, 1080)
const DEFAULT_FULLSCREEN := false
const DEFAULT_VSYNC := true

# Audio defaults
const DEFAULT_MASTER_VOLUME := 1.0
const DEFAULT_MUSIC_VOLUME := 0.8
const DEFAULT_SFX_VOLUME := 0.8
const DEFAULT_UI_VOLUME := 0.7

# Gameplay defaults
const DEFAULT_GAME_SPEED := 1.0
const DEFAULT_TOOLTIP_DELAY := 0.5

# ──────────────────────────────── Signals ────────────────────────────────

signal settings_changed
signal settings_loaded

# ──────────────────────────────── Settings Data ────────────────────────────────

var _graphics := {
	"resolution": DEFAULT_RESOLUTION,
	"fullscreen": DEFAULT_FULLSCREEN,
	"vsync": DEFAULT_VSYNC
}

var _audio := {
	"master_volume": DEFAULT_MASTER_VOLUME,
	"music_volume": DEFAULT_MUSIC_VOLUME,
	"sfx_volume": DEFAULT_SFX_VOLUME,
	"ui_volume": DEFAULT_UI_VOLUME
}

var _gameplay := {
	"game_speed": DEFAULT_GAME_SPEED,
	"tooltip_delay": DEFAULT_TOOLTIP_DELAY
}

# ──────────────────────────────── Graphics ────────────────────────────────

var resolution: Vector2i:
	get: return _graphics["resolution"]
	set(value): _graphics["resolution"] = value; _apply_graphics(); settings_changed.emit()

var fullscreen: bool:
	get: return _graphics["fullscreen"]
	set(value): _graphics["fullscreen"] = value; _apply_graphics(); settings_changed.emit()

var vsync: bool:
	get: return _graphics["vsync"]
	set(value): _graphics["vsync"] = value; _apply_graphics(); settings_changed.emit()

# ──────────────────────────────── Audio ────────────────────────────────

var master_volume: float:
	get: return _audio["master_volume"]
	set(value): _audio["master_volume"] = clampf(value, 0.0, 1.0); _apply_audio(); settings_changed.emit()

var music_volume: float:
	get: return _audio["music_volume"]
	set(value): _audio["music_volume"] = clampf(value, 0.0, 1.0); _apply_audio(); settings_changed.emit()

var sfx_volume: float:
	get: return _audio["sfx_volume"]
	set(value): _audio["sfx_volume"] = clampf(value, 0.0, 1.0); _apply_audio(); settings_changed.emit()

var ui_volume: float:
	get: return _audio["ui_volume"]
	set(value): _audio["ui_volume"] = clampf(value, 0.0, 1.0); _apply_audio(); settings_changed.emit()

# ──────────────────────────────── Gameplay ────────────────────────────────

var game_speed: float:
	get: return _gameplay["game_speed"]
	set(value): _gameplay["game_speed"] = clampf(value, 0.25, 4.0); settings_changed.emit()

var tooltip_delay: float:
	get: return _gameplay["tooltip_delay"]
	set(value): _gameplay["tooltip_delay"] = maxf(0.0, value); settings_changed.emit()

# ──────────────────────────────── Lifecycle ────────────────────────────────

func _ready() -> void:
	load_settings()


func _apply_graphics() -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_FULLSCREEN, _graphics["fullscreen"])
		DisplayServer.window_set_size(_graphics["resolution"])
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if _graphics["vsync"] else DisplayServer.VSYNC_DISABLED)


func _apply_audio() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(_audio["master_volume"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(_audio["music_volume"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(_audio["sfx_volume"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), linear_to_db(_audio["ui_volume"]))


# ──────────────────────────────── Save / Load ────────────────────────────────

func save_settings() -> Error:
	var data := {
		"graphics": _graphics,
		"audio": _audio,
		"gameplay": _gameplay
	}
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(json_string)
	file.close()
	return OK


func load_settings() -> Error:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		reset_to_defaults()
		return ERR_FILE_NOT_FOUND

	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()

	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_string) != OK:
		reset_to_defaults()
		return ERR_PARSE_ERROR

	var data: Dictionary = json.get_data()
	if data.is_empty():
		reset_to_defaults()
		return ERR_FILE_CORRUPT

	_graphics = data.get("graphics", _graphics.duplicate(true))
	_audio = data.get("audio", _audio.duplicate(true))
	_gameplay = data.get("gameplay", _gameplay.duplicate(true))

	_apply_graphics()
	_apply_audio()
	settings_loaded.emit()
	return OK


func reset_to_defaults() -> void:
	_graphics = {
		"resolution": DEFAULT_RESOLUTION,
		"fullscreen": DEFAULT_FULLSCREEN,
		"vsync": DEFAULT_VSYNC
	}
	_audio = {
		"master_volume": DEFAULT_MASTER_VOLUME,
		"music_volume": DEFAULT_MUSIC_VOLUME,
		"sfx_volume": DEFAULT_SFX_VOLUME,
		"ui_volume": DEFAULT_UI_VOLUME
	}
	_gameplay = {
		"game_speed": DEFAULT_GAME_SPEED,
		"tooltip_delay": DEFAULT_TOOLTIP_DELAY
	}
	_apply_graphics()
	_apply_audio()
	settings_changed.emit()
