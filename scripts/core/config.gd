## 全局配置管理器
extends Node

# 游戏配置
const GAME_CONFIG = {
    # 资源路径
    "resources": {
        "sprites": "res://resources/sprites/",
        "audio": "res://resources/audio/",
        "effects": "res://resources/effects/"
    },
    
    # 单位属性
    "unit_stats": {
        "infantry": {
            "hp": 100, "attack": 15, "speed": 50, "range": 100
        },
        "light_tank": {
            "hp": 200, "attack": 30, "speed": 80, "range": 150
        },
        "heavy_tank": {
            "hp": 400, "attack": 50, "speed": 40, "range": 200
        },
        "helicopter": {
            "hp": 150, "attack": 40, "speed": 100, "range": 250
        },
        "rocket_soldier": {
            "hp": 80, "attack": 60, "speed": 45, "range": 300
        }
    },
    
    # 建筑属性
    "building_stats": {
        "command_center": {"hp": 1000, "cost": 0},
        "barracks": {"hp": 500, "cost": 200},
        "factory": {"hp": 600, "cost": 300},
        "power_plant": {"hp": 300, "cost": 150}
    },
    
    # 游戏数值
    "gameplay": {
        "starting_resources": 1000,
        "resource_per_tick": 10,
        "max_units": 50
    }
}

# 获取单位属性
static func get_unit_stats(unit_type: String) -> Dictionary:
    return GAME_CONFIG.get("unit_stats", {}).get(unit_type, {})

# 获取建筑属性
static func get_building_stats(building_type: String) -> Dictionary:
    return GAME_CONFIG.get("building_stats", {}).get(building_type, {})

# 获取资源配置路径
static func get_resource_path(resource_type: String) -> String:
    return GAME_CONFIG.get("resources", {}).get(resource_type, "")
