# 子弹/投射物系统
extends Node2D

var projectiles: Array = []

class Projectile:
	var sprite: Sprite2D
	var start_pos: Vector2
	var target_pos: Vector2
	var target: Node
	var speed: float
	var damage: int
	var owner: String
	
	func _init(s: Sprite2D, start: Vector2, end: Vector2, spd: float, dmg: int, own: String):
		sprite = s
		start_pos = start
		target_pos = end
		speed = spd
		damage = dmg
		owner = own
	
	func process(delta):
		var dir = (target_pos - sprite.position).normalized()
		sprite.position += dir * speed * delta
		return sprite.position.distance_to(target_pos) < 10

func _process(delta):
	var to_remove = []
	
	for p in projectiles:
		if p.process(delta):
			# 命中目标
			if p.target and p.target.has_method("take_damage"):
				p.target.take_damage(p.damage)
			p.sprite.queue_free()
			to_remove.append(p)
	
	for p in to_remove:
		projectiles.erase(p)

func fire_projectile(from_pos: Vector2, to_pos: Vector2, target: Node, speed: float, damage: int, owner: String):
	var spr = Sprite2D.new()
	spr.position = from_pos
	spr.modulate = Color(1, 0.8, 0)  # 黄色子弹
	
	# 简单用圆形代替
	var circle = ColorRect.new()
	circle.size = Vector2(4, 4)
	circle.color = Color(1, 0.8, 0)
	circle.position = -Vector2(2, 2)
	spr.add_child(circle)
	
	add_child(spr)
	projectiles.append(Projectile.new(spr, from_pos, to_pos, speed, damage, owner))
