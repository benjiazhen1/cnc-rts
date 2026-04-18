## 战斗系统 (重构版)
extends Node
class_name CombatSystem

# 导入配置和日志
const Config = preload("res://scripts/core/config.gd")
const Logger = preload("res://scripts/core/logger.gd")

# 伤害类型
enum DamageType { NORMAL, ARMOR_PIERCING, EXPLOSIVE, ANTI_BUILDING }

# 克制伤害倍率
const COUNTER_BONUS = 1.5
const COUNTER_PENALTY = 0.7
const CLOSE_RANGE_PENALTY = 0.8

# 克制关系表
var _counter_chart: Dictionary = {
    "Infantry": {"Strong": [], "Weak": ["LightTank", "HeavyTank"]},
    "LightTank": {"Strong": ["Infantry", "Helicopter"], "Weak": ["HeavyTank"]},
    "HeavyTank": {"Strong": ["LightTank"], "Weak": ["Helicopter", "RocketSoldier"]},
    "Helicopter": {"Strong": ["Infantry", "LightTank"], "Weak": ["HeavyTank"]},
    "RocketSoldier": {"Strong": ["LightTank", "HeavyTank", "Helicopter"], "Weak": ["Infantry"]}
}

# 计算伤害
func calculate_damage(
    attacker_type: String,
    defender_type: String,
    base_damage: float,
    distance: float,
    attack_range: float,
    damage_type: int = DamageType.NORMAL
) -> float:
    var damage = base_damage
    
    # 1. 伤害类型加成
    damage = _apply_damage_type(damage, damage_type)
    
    # 2. 克制关系加成
    damage = _apply_counter(attacker_type, defender_type, damage)
    
    # 3. 距离惩罚
    damage = _apply_range_penalty(damage, distance, attack_range)
    
    Logger.debug("伤害计算: %s -> %s = %.1f" % [attacker_type, defender_type, damage])
    return damage

func _apply_damage_type(base: float, dtype: int) -> float:
    match dtype:
        DamageType.ARMOR_PIERCING: return base * 1.5
        DamageType.EXPLOSIVE: return base * 0.8
        DamageType.ANTI_BUILDING: return base * 2.0
        _: return base

func _apply_counter(attacker: String, defender: String, base: float) -> float:
    var chart = _counter_chart.get(attacker, {})
    var strong_list = chart.get("Strong", [])
    var weak_list = chart.get("Weak", [])
    
    if defender in strong_list:
        Logger.debug("%s 克制 %s, 伤害 x%.1f" % [attacker, defender, COUNTER_BONUS])
        return base * COUNTER_BONUS
    elif defender in weak_list:
        Logger.debug("%s 被 %s 克制, 伤害 x%.1f" % [attacker, defender, COUNTER_PENALTY])
        return base * COUNTER_PENALTY
    
    return base

func _apply_range_penalty(base: float, dist: float, range_val: float) -> float:
    if range_val > 0 and dist < range_val * 0.5:
        Logger.debug("近距离惩罚, 伤害 x%.1f" % CLOSE_RANGE_PENALTY)
        return base * CLOSE_RANGE_PENALTY
    return base
