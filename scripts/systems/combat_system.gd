# 战斗系统
extends Node

var damage_types: Dictionary = {
	"normal": 1.0,
	"armor_piercing": 1.5,
	"explosive": 0.8,
	"anti_building": 2.0
}

var unit_counters: Dictionary = {
	"Infantry": {"Strong": [], "Weak": ["LightTank", "HeavyTank"]},
	"LightTank": {"Strong": ["Infantry", "Helicopter"], "Weak": ["HeavyTank"]},
	"HeavyTank": {"Strong": ["LightTank"], "Weak": ["Helicopter", "RocketSoldier"]},
	"Helicopter": {"Strong": ["Infantry", "LightTank"], "Weak": ["HeavyTank"]},
	"RocketSoldier": {"Strong": ["LightTank", "HeavyTank", "Helicopter"], "Weak": ["Infantry"]}
}

func calculate_damage(attacker: Unit, defender: Unit, base_damage: int) -> int:
	var damage = base_damage
	
	# 兵种克制
	if attacker.unit_name in unit_counters:
		var counters = unit_counters[attacker.unit_name]
		if defender.unit_name in counters.get("Strong", []):
			damage = int(damage * 1.5)
		elif defender.unit_name in counters.get("Weak", []):
			damage = int(damage * 0.7)
	
	# 攻击范围惩罚（远程单位在太近时伤害降低）
	var distance = attacker.global_position.distance_to(defender.global_position)
	if distance < attacker.attack_range * 0.5:
		damage = int(damage * 0.8)
	
	return damage

func get_attack_targets(unit: Unit) -> Array:
	var targets: Array = []
	var enemy_owner = "ai" if unit.owner == "player" else "player"
	
	# 从敌方单位中找
	var all_units = get_tree().get_nodes_in_group("units")
	for u in all_units:
		if u.owner == enemy_owner:
			if unit.global_position.distance_to(u.global_position) <= unit.attack_range:
				targets.append(u)
	
	# 从敌方建筑中找
	var gs = get_node("/root/GameState")
	var enemy_buildings = gs.ai_buildings if unit.owner == "player" else gs.player_buildings
	for b in enemy_buildings:
		if unit.global_position.distance_to(b.global_position) <= unit.attack_range:
			targets.append(b)
	
	return targets

func find_nearest_enemy(unit: Unit) -> Node:
	var enemy_owner = "ai" if unit.owner == "player" else "player"
	var nearest_dist: float = INF
	var nearest: Node = null
	
	# 搜索单位
	var all_units = get_tree().get_nodes_in_group("units")
	for u in all_units:
		if u.owner == enemy_owner:
			var dist = unit.global_position.distance_to(u.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = u
	
	# 搜索建筑
	var gs = get_node("/root/GameState")
	var enemy_buildings = gs.ai_buildings if unit.owner == "player" else gs.player_buildings
	for b in enemy_buildings:
		var dist = unit.global_position.distance_to(b.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = b
	
	return nearest

func find_attack_target_in_range(unit: Unit) -> Node:
	var targets = get_attack_targets(unit)
	if targets.size() > 0:
		# 优先攻击最低血量的目标
		targets.sort_custom(func(a, b): return a.health < b.health)
		return targets[0]
	return null
