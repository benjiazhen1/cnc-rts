## 战斗系统
##
## 管理单位之间的战斗交互，包括伤害计算、攻击目标选择和兵种克制系统。
##
## **兵种克制系统 (Unit Counter System)**
## 每个兵种都有其优势(Strong)和劣势(Weak)列表：
## - 克制关系：当攻击方克制防守方时，造成1.5倍伤害
## - 被克制关系：当攻击方被防守方克制时，造成0.7倍伤害
## - 无克制关系：造成正常伤害(1.0倍)
##
## **克制关系列表：**
## - Infantry: 克制无（弱势于LightTank, HeavyTank）
## - LightTank: 克制Infantry, Helicopter（弱势于HeavyTank）
## - HeavyTank: 克制LightTank（弱势于Helicopter, RocketSoldier）
## - Helicopter: 克制Infantry, LightTank（弱势于HeavyTank）
## - RocketSoldier: 克制LightTank, HeavyTank, Helicopter（弱势于Infantry）
##
## **攻击范围惩罚：**
## 远程单位在过近距离(<攻击范围*0.5)攻击时，伤害降低至80%
class_name CombatSystem
extends Node

# ==================== 伤害类型倍率 ====================
# 不同攻击类型对伤害的加成系数
const DAMAGE_TYPE_NORMAL: float = 1.0
const DAMAGE_TYPE_ARMOR_PIERCING: float = 1.5
const DAMAGE_TYPE_EXPLOSIVE: float = 0.8
const DAMAGE_TYPE_ANTI_BUILDING: float = 2.0

# ==================== 克制系统倍率 ====================
# 克制关系伤害倍率
const COUNTER_DAMAGE_MULTIPLIER: float = 1.5
# 被克制关系伤害倍率
const COUNTER_WEAK_MULTIPLIER: float = 0.7

# ==================== 攻击范围惩罚 ====================
# 触发近距离惩罚的距离阈值(相对于攻击范围的比例)
const CLOSE_RANGE_PENALTY_THRESHOLD: float = 0.5
# 近距离攻击的伤害惩罚倍率
const CLOSE_RANGE_PENALTY_MULTIPLIER: float = 0.8

# ==================== 游戏状态路径 ====================
const GAME_STATE_PATH: String = "/root/GameState"

# ==================== 伤害类型映射 ====================
var damage_types: Dictionary = {
	"normal": DAMAGE_TYPE_NORMAL,
	"armor_piercing": DAMAGE_TYPE_ARMOR_PIERCING,
	"explosive": DAMAGE_TYPE_EXPLOSIVE,
	"anti_building": DAMAGE_TYPE_ANTI_BUILDING
}

# ==================== 兵种克制表 ====================
# 结构：{攻击方: {"Strong": [被克制单位列表], "Weak": [克制攻击方的单位列表]}}
var unit_counters: Dictionary = {
	"Infantry": {
		"Strong": [],  # Infantry不克制任何单位
		"Weak": ["LightTank", "HeavyTank"]
	},
	"LightTank": {
		"Strong": ["Infantry", "Helicopter"],
		"Weak": ["HeavyTank"]
	},
	"HeavyTank": {
		"Strong": ["LightTank"],
		"Weak": ["Helicopter", "RocketSoldier"]
	},
	"Helicopter": {
		"Strong": ["Infantry", "LightTank"],
		"Weak": ["HeavyTank"]
	},
	"RocketSoldier": {
		"Strong": ["LightTank", "HeavyTank", "Helicopter"],
		"Weak": ["Infantry"]
	}
}

## 计算伤害
##
## 根据基础伤害、兵种克制关系和攻击距离计算最终伤害值。
##
## **伤害计算顺序：**
## 1. 应用兵种克制倍率（克制+50%，被克制-30%）
## 2. 应用攻击范围惩罚（近距离-20%）
##
## @param attacker: 攻击方单位
## @param defender: 防守方单位
## @param base_damage: 基础伤害值
## @return: 计算后的最终伤害值（整数）
func calculate_damage(attacker: Unit, defender: Unit, base_damage: int) -> int:
	# 参数验证
	if not is_instance_valid(attacker):
		push_error("CombatSystem: 无效的攻击方单位")
		return 0
	if not is_instance_valid(defender):
		push_error("CombatSystem: 无效的防守方单位")
		return 0
	if base_damage < 0:
		push_warning("CombatSystem: 负数基础伤害值 %d，已修正为0" % base_damage)
		base_damage = 0

	var damage: float = base_damage

	# ---------- 兵种克制 ----------
	# 检查攻击方是否存在于克制表中
	if attacker.unit_name in unit_counters:
		var counters: Dictionary = unit_counters[attacker.unit_name]

		# 检查防守方是否被攻击方克制（造成1.5倍伤害）
		if counters.get("Strong", []).has(defender.unit_name):
			damage *= COUNTER_DAMAGE_MULTIPLIER

		# 检查攻击方是否被防守方克制（造成0.7倍伤害）
		elif counters.get("Weak", []).has(defender.unit_name):
			damage *= COUNTER_WEAK_MULTIPLIER

	# ---------- 攻击范围惩罚 ----------
	# 远程单位在过近时伤害降低（模拟近战慌乱或武器最优射程外）
	var distance: float = attacker.global_position.distance_to(defender.global_position)
	var penalty_threshold: float = attacker.attack_range * CLOSE_RANGE_PENALTY_THRESHOLD

	if distance < penalty_threshold:
		damage *= CLOSE_RANGE_PENALTY_MULTIPLIER

	return int(damage)


## 获取可攻击目标
##
## 查找指定单位攻击范围内的所有敌方单位（单位+建筑）。
##
## @param unit: 需要寻找目标的单位
## @return: 可攻击目标列表（包含单位和建筑节点）
func get_attack_targets(unit: Unit) -> Array:
	# 参数验证
	if not is_instance_valid(unit):
		push_error("CombatSystem: 无效的单位")
		return []

	var targets: Array = []
	var enemy_owner: String = "ai" if unit.owner == "player" else "player"

	# ---------- 从敌方单位中查找 ----------
	var all_units: Array = get_tree().get_nodes_in_group("units")
	for u in all_units:
		if not is_instance_valid(u):
			continue
		if u.owner == enemy_owner:
			var dist: float = unit.global_position.distance_to(u.global_position)
			if dist <= unit.attack_range:
				targets.append(u)

	# ---------- 从敌方建筑中查找 ----------
	var gs: Node = get_node_or_null(GAME_STATE_PATH)
	if gs == null:
		push_error("CombatSystem: 无法获取GameState节点 at %s" % GAME_STATE_PATH)
		return targets

	var enemy_buildings: Array = gs.ai_buildings if unit.owner == "player" else gs.player_buildings
	if enemy_buildings == null:
		push_warning("CombatSystem: 敌方建筑列表为空")
		return targets

	for b in enemy_buildings:
		if not is_instance_valid(b):
			continue
		var dist: float = unit.global_position.distance_to(b.global_position)
		if dist <= unit.attack_range:
			targets.append(b)

	return targets


## 查找最近的敌方单位或建筑
##
## 在所有敌方单位（单位组+建筑）中搜索距离最近的敌人。
##
## @param unit: 执行搜索的单位
## @return: 最近的敌方节点（单位或建筑），无敌人时返回null
func find_nearest_enemy(unit: Unit) -> Node:
	# 参数验证
	if not is_instance_valid(unit):
		push_error("CombatSystem: 无效的单位")
		return null

	var enemy_owner: String = "ai" if unit.owner == "player" else "player"
	var nearest_dist: float = INF
	var nearest: Node = null

	# ---------- 搜索单位 ----------
	var all_units: Array = get_tree().get_nodes_in_group("units")
	for u in all_units:
		if not is_instance_valid(u):
			continue
		if u.owner == enemy_owner:
			var dist: float = unit.global_position.distance_to(u.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = u

	# ---------- 搜索建筑 ----------
	var gs: Node = get_node_or_null(GAME_STATE_PATH)
	if gs == null:
		push_error("CombatSystem: 无法获取GameState节点 at %s" % GAME_STATE_PATH)
		return nearest

	var enemy_buildings: Array = gs.ai_buildings if unit.owner == "player" else gs.player_buildings
	if enemy_buildings != null:
		for b in enemy_buildings:
			if not is_instance_valid(b):
				continue
			var dist: float = unit.global_position.distance_to(b.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = b

	return nearest


## 在攻击范围内查找最佳目标
##
## 优先选择攻击范围内血量最低的目标（集火目标）。
##
## **集火策略：**
## - 按血量升序排序，确保优先击杀低血量目标
## - 适用于快速消灭敌方有生力量
##
## @param unit: 需要寻找目标的单位
## @return: 最佳攻击目标（血量最低），无有效目标时返回null
func find_attack_target_in_range(unit: Unit) -> Node:
	# 参数验证
	if not is_instance_valid(unit):
		push_error("CombatSystem: 无效的单位")
		return null

	var targets: Array = get_attack_targets(unit)

	if targets.size() == 0:
		return null

	# 优先攻击最低血量的目标（集火）
	targets.sort_custom(func(a, b): return a.health < b.health)
	return targets[0]
