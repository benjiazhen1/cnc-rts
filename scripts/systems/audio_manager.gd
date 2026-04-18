## Audio Manager - 音效管理器
extends Node

# 音频播放器
var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var ui_sfx_player: AudioStreamPlayer

# 音效音量
var sfx_volume: float = 0.8
var music_volume: float = 0.6

# 音效库
const SFX = {
    # 界面音效
    "ui_click": "res://resources/audio/sfx/ui_click.wav",
    "ui_hover": "res://resources/audio/sfx/ui_hover.wav",
    "ui_open": "res://resources/audio/sfx/ui_open.wav",
    "ui_close": "res://resources/audio/sfx/ui_close.wav",
    
    # 单位音效
    "unit_select": "res://resources/audio/sfx/unit_select.wav",
    "unit_move": "res://resources/audio/sfx/unit_move.wav",
    "unit_attack": "res://resources/audio/sfx/unit_attack.wav",
    "unit_die": "res://resources/audio/sfx/unit_die.wav",
    "unit_build": "res://resources/audio/sfx/unit_build.wav",
    
    # 武器音效
    "weapon_gun": "res://resources/audio/sfx/weapon_gun.wav",
    "weapon_cannon": "res://resources/audio/sfx/weapon_cannon.wav",
    "weapon_rocket": "res://resources/audio/sfx/weapon_rocket.wav",
    "weapon_explosion": "res://resources/audio/sfx/weapon_explosion.wav",
    
    # 建筑音效
    "building_place": "res://resources/audio/sfx/building_place.wav",
    "building_complete": "res://resources/audio/sfx/building_complete.wav",
    "building_destroyed": "res://resources/audio/sfx/building_destroyed.wav",
}

# 背景音乐
const MUSIC = {
    "main_menu": "res://resources/audio/music/main_menu.mp3",
    "battle_1": "res://resources/audio/music/battle_1.mp3",
    "battle_2": "res://resources/audio/music/battle_2.mp3",
    "victory": "res://resources/audio/music/victory.mp3",
    "defeat": "res://resources/audio/music/defeat.mp3",
}

func _ready():
    # 创建播放器
    sfx_player = AudioStreamPlayer.new()
    music_player = AudioStreamPlayer.new()
    ui_sfx_player = AudioStreamPlayer.new()
    
    sfx_player.bus = "SFX"
    music_player.bus = "Music"
    ui_sfx_player.bus = "SFX"
    
    add_child(sfx_player)
    add_child(music_player)
    add_child(ui_sfx_player)
    
    # 加载音量设置
    load_volume_settings()

func load_volume_settings():
    var config = ConfigFile.new()
    if config.load("user://settings.cfg") == OK:
        sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
        music_volume = config.get_value("audio", "music_volume", 0.6)
        
        sfx_player.volume_db = linear_to_db(sfx_volume)
        music_player.volume_db = linear_to_db(music_volume)

func save_volume_settings():
    var config = ConfigFile.new()
    config.set_value("audio", "sfx_volume", sfx_volume)
    config.set_value("audio", "music_volume", music_volume)
    config.save("user://settings.cfg")

func set_sfx_volume(vol: float):
    sfx_volume = clamp(vol, 0.0, 1.0)
    sfx_player.volume_db = linear_to_db(sfx_volume)
    save_volume_settings()

func set_music_volume(vol: float):
    music_volume = clamp(vol, 0.0, 1.0)
    music_player.volume_db = linear_to_db(music_volume)
    save_volume_settings()

# 播放音效
func play_sfx(sfx_name: String):
    if not SFX.has(sfx_name):
        return
    
    var stream = load(SFX[sfx_name])
    if stream:
        sfx_player.stream = stream
        sfx_player.volume_db = linear_to_db(sfx_volume)
        sfx_player.play()

# 播放UI音效
func play_ui(sfx_name: String):
    var full_name = "ui_" + sfx_name
    play_sfx(full_name)

# 播放背景音乐
func play_music(music_name: String, fade_in: bool = false):
    if not MUSIC.has(music_name):
        return
    
    var stream = load(MUSIC[music_name])
    if stream:
        if fade_in and music_player.playing:
            # 淡入淡出切换
            var tween = create_tween()
            tween.tween_property(music_player, "volume_db", linear_to_db(0.0), 0.5)
            tween.tween_callback(music_player.stop)
            yield(tween, "finished")
        
        music_player.stream = stream
        music_player.volume_db = linear_to_db(music_volume)
        music_player.play()

# 停止音乐
func stop_music(fade_out: bool = false):
    if fade_out:
        var tween = create_tween()
        tween.tween_property(music_player, "volume_db", linear_to_db(0.0), 0.5)
        tween.tween_callback(music_player.stop)
    else:
        music_player.stop()

# 暂停/恢复
func pause_music():
    music_player.stream_paused = true

func resume_music():
    music_player.stream_paused = false

# 单位音效快捷方法
func play_unit_sfx(action: String):
    play_sfx("unit_" + action)

# 武器音效快捷方法
func play_weapon_sfx(weapon_type: String):
    play_sfx("weapon_" + weapon_type)
