## Sound Manager System
##
## Manages background music (looping) and sound effects (attack, build, select, etc.).
## Provides volume controls and mute toggle functionality.
## Uses placeholder AudioStreamPlayer setup — replace with actual audio files.

class_name SoundManager
extends Node

# ============================================================================
# CONSTANTS
# ============================================================================

## Master volume range
const MIN_VOLUME: float = 0.0
const MAX_VOLUME: float = 1.0
const DEFAULT_MASTER_VOLUME: float = 0.8

## Music volume range
const DEFAULT_MUSIC_VOLUME: float = 0.6

## SFX volume range
const DEFAULT_SFX_VOLUME: float = 0.8

## Volume DB limits (for AudioServer)
const MIN_VOLUME_DB: float = -80.0

# ============================================================================
# SIGNALS
# ============================================================================

signal master_volume_changed(volume: float)
signal music_volume_changed(volume: float)
signal sfx_volume_changed(volume: float)
signal mute_toggled(is_muted: bool)

# ============================================================================
# PUBLIC VARIABLES
# ============================================================================

## Current master volume (0.0 to 1.0)
var master_volume: float = DEFAULT_MASTER_VOLUME:
	set(value):
		master_volume = clamp(value, MIN_VOLUME, MAX_VOLUME)
		_apply_volumes()
		master_volume_changed.emit(master_volume)

## Current music volume (0.0 to 1.0)
var music_volume: float = DEFAULT_MUSIC_VOLUME:
	set(value):
		music_volume = clamp(value, MIN_VOLUME, MAX_VOLUME)
		_apply_volumes()
		music_volume_changed.emit(music_volume)

## Current SFX volume (0.0 to 1.0)
var sfx_volume: float = DEFAULT_SFX_VOLUME:
	set(value):
		sfx_volume = clamp(value, MIN_VOLUME, MAX_VOLUME)
		_apply_volumes()
		sfx_volume_changed.emit(sfx_volume)

## Whether all audio is muted
var is_muted: bool = false:
	set(value):
		is_muted = value
		_apply_volumes()
		mute_toggled.emit(is_muted)

# ============================================================================
# PRIVATE VARIABLES
# ============================================================================

## Background music player
var _music_player: AudioStreamPlayer

## SFX players pool (for overlapping sounds)
var _sfx_players: Array[AudioStreamPlayer] = []

## Number of SFX players in pool
const SFX_POOL_SIZE: int = 8

## Current SFX player index (round-robin)
var _sfx_pool_index: int = 0

## Volume buses (set via _ready)
var _master_bus_index: int = 0
var _music_bus_index: int = 0
var _sfx_bus_index: int = 0

# ============================================================================
# BUILT-IN FUNCTIONS
# ============================================================================

func _ready() -> void:
	_setup_audio_buses()
	_setup_players()
	_apply_volumes()


func _process(_delta: float) -> void:
	pass

# ============================================================================
# PUBLIC FUNCTIONS
# ============================================================================

## Play background music (loops by default)
func play_music(stream: AudioStream, fade_duration: float = 0.0) -> void:
	if not stream:
		return

	_music_player.stream = stream
	_music_player.loop = true

	if fade_duration > 0.0:
		_fade_in_music(fade_duration)
	else:
		_music_player.play()


## Stop background music (optionally with fade out)
func stop_music(fade_duration: float = 0.0) -> void:
	if fade_duration > 0.0:
		_fade_out_music(fade_duration)
	else:
		_music_player.stop()


## Pause background music
func pause_music() -> void:
	_music_player.stream_paused = true


## Resume background music
func resume_music() -> void:
	_music_player.stream_paused = false


## Play a sound effect (attack sound)
func play_attack() -> void:
	# TODO: Replace with actual attack sound
	# play_sfx(load("res://audio/sfx/attack.wav"))
	pass


## Play a sound effect (build construction)
func play_build() -> void:
	# TODO: Replace with actual build sound
	# play_sfx(load("res://audio/sfx/build.wav"))
	pass


## Play a sound effect (unit selected)
func play_select() -> void:
	# TODO: Replace with actual select sound
	# play_sfx(load("res://audio/sfx/select.wav"))
	pass


## Play a sound effect (unit move command)
func play_move() -> void:
	# TODO: Replace with actual move sound
	# play_sfx(load("res://audio/sfx/move.wav"))
	pass


## Play a sound effect (resource collected)
func play_collect() -> void:
	# TODO: Replace with actual collect sound
	# play_sfx(load("res://audio/sfx/collect.wav"))
	pass


## Play a sound effect (error/invalid action)
func play_error() -> void:
	# TODO: Replace with actual error sound
	# play_sfx(load("res://audio/sfx/error.wav"))
	pass


## Play a generic sound effect with an AudioStream
func play_sfx(stream: AudioStream, volume_modifier: float = 1.0) -> void:
	if not stream or is_muted:
		return

	var player: AudioStreamPlayer = _get_next_sfx_player()
	player.stream = stream
	player.volume_db = _volume_linear_to_db(sfx_volume * master_volume * volume_modifier)
	player.play()


## Toggle mute state
func toggle_mute() -> void:
	is_muted = !is_muted


## Set master volume directly (0.0 to 1.0)
func set_master_volume(value: float) -> void:
	master_volume = value


## Set music volume directly (0.0 to 1.0)
func set_music_volume(value: float) -> void:
	music_volume = value


## Set SFX volume directly (0.0 to 1.0)
func set_sfx_volume(value: float) -> void:
	sfx_volume = value


## Fade music volume to target over duration
func fade_music_volume_to(target_volume: float, duration: float) -> void:
	# TODO: Implement tween-based fade
	music_volume = target_volume


## Fade out and stop music
func fade_out_and_stop(duration: float = 1.0) -> void:
	_fade_out_music(duration)


# ============================================================================
# PRIVATE FUNCTIONS
# ============================================================================

func _setup_audio_buses() -> void:
	# Find audio bus indices by name (create them in Project Settings if needed)
	_master_bus_index = AudioServer.get_bus_index("Master")
	_music_bus_index = AudioServer.get_bus_index("Music")
	_sfx_bus_index = AudioServer.get_bus_index("SFX")

	# Fallback to Master if specific buses not found
	if _master_bus_index == -1:
		_master_bus_index = 0
	if _music_bus_index == -1:
		_music_bus_index = 0
	if _sfx_bus_index == -1:
		_sfx_bus_index = 0


func _setup_players() -> void:
	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.loop = true
	add_child(_music_player)

	# Create SFX player pool
	for i in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)


func _get_next_sfx_player() -> AudioStreamPlayer:
	var player: AudioStreamPlayer = _sfx_players[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	return player


func _apply_volumes() -> void:
	# Calculate effective volume multipliers
	var effective_master: float = 0.0 if is_muted else master_volume
	var effective_music: float = music_volume * effective_master
	var effective_sfx: float = sfx_volume * effective_master

	# Apply to music player
	if _music_player:
		_music_player.volume_db = _volume_linear_to_db(effective_music)

	# Apply to SFX pool
	for player in _sfx_players:
		player.volume_db = _volume_linear_to_db(effective_sfx)

	# Optionally adjust audio buses
	if _master_bus_index >= 0:
		AudioServer.set_bus_volume_db(_master_bus_index, _volume_linear_to_db(effective_master))


func _volume_linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return MIN_VOLUME_DB
	return linear_to_db(linear)


func _fade_in_music(duration: float) -> void:
	# TODO: Implement tween-based fade in
	_music_player.play()


func _fade_out_music(duration: float) -> void:
	# TODO: Implement tween-based fade out then stop
	_music_player.stop()


# ============================================================================
# PUBLIC STATIC FUNCTIONS
# ============================================================================

## Convert linear volume (0.0-1.0) to decibels
static func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return MIN_VOLUME_DB
	return 20.0 * log(linear) / log(10.0)


## Convert decibels to linear volume (0.0-1.0)
static func db_to_linear(db: float) -> float:
	if db <= MIN_VOLUME_DB:
		return 0.0
	return pow(10.0, db / 20.0)
