## Combat Effects System - 战斗特效系统
extends Node2D

# 粒子效果预制体
const PARTICLE_SCENE = preload("res://scenes/effects/particle.tscn")

# 攻击特效
func show_attack_effect(pos: Vector2, effect_type: String):
    match effect_type:
        "explosion":
            show_explosion(pos)
        "muzzle_flash":
            show_muzzle_flash(pos)
        "bullet_trail":
            show_bullet_trail(pos)
        "shield_hit":
            show_shield_hit(pos)

# 爆炸效果
func show_explosion(pos: Vector2):
    var particles = PARTICLE_SCENE.instantiate()
    particles.position = pos
    particles.emitting = true
    particles.lifetime = 0.5
    particles.amount = 20
    particles.speed = 200
    particles.spread = 360
    particles.initial_velocity_max = 300
    add_child(particles)
    
    # 延迟删除
    await get_tree().create_timer(0.5).timeout
    particles.queue_free()

# 枪口火焰
func show_muzzle_flash(pos: Vector2):
    var flash = Sprite2D.new()
    flash.texture = preload("res://resources/effects/muzzle_flash.png")
    flash.position = pos
    flash.scale = Vector2(0.5, 0.5)
    flash.modulate = Color(1, 0.8, 0.4)
    add_child(flash)
    
    # 闪烁效果
    var tween = create_tween()
    tween.tween_property(flash, "modulate:a", 0.0, 0.1)
    tween.tween_callback(flash.queue_free)

# 子弹轨迹
func show_bullet_trail(from: Vector2, to: Vector2):
    var line = Line2D.new()
    line.width = 2
    line.default_color = Color(1, 1, 0.5)
    line.add_point(from)
    line.add_point(to)
    add_child(line)
    
    # 渐隐效果
    var tween = create_tween()
    tween.tween_property(line, "modulate:a", 0.0, 0.2)
    tween.tween_callback(line.queue_free)

# 护盾受击
func show_shield_hit(pos: Vector2):
    var ring = Sprite2D.new()
    ring.texture = preload("res://resources/effects/shield_ring.png")
    ring.position = pos
    ring.scale = Vector2(0.1, 0.1)
    ring.modulate = Color(0.5, 0.8, 1)
    add_child(ring)
    
    # 扩散效果
    var tween = create_tween()
    tween.tween_property(ring, "scale", Vector2(2, 2), 0.3)
    tween.tween_property(ring, "modulate:a", 0.0, 0.3)
    tween.tween_callback(ring.queue_free)

# 单位死亡效果
func show_unit_death(pos: Vector2):
    # 爆炸
    show_explosion(pos)
    
    # 烟雾
    var smoke = PARTICLE_SCENE.instantiate()
    smoke.position = pos
    smoke.emitting = true
    smoke.lifetime = 1.0
    smoke.amount = 10
    smoke.speed = 50
    smoke.spread = 180
    smoke.initial_velocity_max = 80
    smoke.process_material.color = Color(0.3, 0.3, 0.3, 0.8)
    add_child(smoke)
    
    await get_tree().create_timer(1.0).timeout
    smoke.queue_free()

# 建筑损坏效果
func show_building_damage(pos: Vector2, damage: float):
    # 火花
    var sparks = PARTICLE_SCENE.instantiate()
    sparks.position = pos
    sparks.emitting = true
    sparks.amount = int(damage / 5)
    sparks.speed = 100
    sparks.spread = 90
    sparks.initial_velocity_max = 150
    sparks.lifetime = 0.3
    add_child(sparks)
    
    await get_tree().create_timer(0.3).timeout
    sparks.queue_free()

# 治疗效果
func show_heal_effect(pos: Vector2):
    var heal = PARTICLE_SCENE.instantiate()
    heal.position = pos
    heal.emitting = true
    heal.lifetime = 0.8
    heal.amount = 15
    heal.speed = 30
    heal.spread = 60
    heal.initial_velocity_max = 50
    heal.process_material.gravity = Vector2(0, -100)
    heal.process_material.color = Color(0.2, 1, 0.3, 0.8)
    add_child(heal)
    
    await get_tree().create_timer(0.8).timeout
    heal.queue_free()

# 经验值获取效果
func show_xp_gain(pos: Vector2, amount: int):
    var label = Label.new()
    label.text = "+%d XP" % amount
    label.position = pos
    label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
    label.add_theme_font_size_override("font_size", 14)
    add_child(label)
    
    var tween = create_tween()
    tween.tween_property(label, "position:y", pos.y - 50, 0.8)
    tween.tween_property(label, "modulate:a", 0.0, 0.8)
    tween.tween_callback(label.queue_free)
