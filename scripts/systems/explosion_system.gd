# 爆炸/粒子特效系统
extends Node2D

var explosions: Array = []

class Explosion:
	var particles: Array
	var lifetime: float
	var age: float
	
	func _init(pos: Vector2, lifetime_sec: float, scene: Node2D):
		lifetime = lifetime_sec
		age = 0
		particles = []
		
		# 创建粒子
		for i in range(8):
			var p = Sprite2D.new()
			p.modulate = Color(1, 0.5, 0, 0.8)
			var circle = ColorRect.new()
			circle.size = Vector2(8, 8)
			circle.color = Color(1, 0.3, 0, 0.8)
			circle.position = -Vector2(4, 4)
			p.add_child(circle)
			p.position = pos
			
			var angle = randf() * TAU
			var speed = randf() * 100 + 50
			p.userdata_velocity = Vector2(cos(angle), sin(angle)) * speed
			scene.add_child(p)
			particles.append(p)
	
	func process(delta):
		age += delta
		for p in particles:
			if "userdata_velocity" in p:
				p.position += p.userdata_velocity * delta
				p.modulate.a = 1.0 - (age / lifetime)
		return age >= lifetime
	
	func cleanup(scene: Node2D):
		for p in particles:
			p.queue_free()

func create_explosion(pos: Vector2):
	var exp = Explosion.new(pos, 0.5, self)
	explosions.append(exp)

func _process(delta):
	var to_remove = []
	
	for exp in explosions:
		if exp.process(delta):
			exp.cleanup(self)
			to_remove.append(exp)
	
	for exp in to_remove:
		explosions.erase(exp)
