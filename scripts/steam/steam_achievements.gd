# Steam成就定义
extends Node

# 成就ID必须与Steam后台配置一致
const ACHIEVEMENT_FIRST_BUILDING = "FIRST_BUILDING"   # 建造第一个建筑
const ACHIEVEMENT_FIRST_UNIT = "FIRST_UNIT"           # 生产第一个单位
const ACHIEVEMENT_FIRST_BATTLE = "FIRST_BATTLE"       # 第一次战斗
const ACHIEVEMENT_FIRST_WIN = "FIRST_WIN"             # 第一次胜利
const ACHIEVEMENT_FIRST_LOSS = "FIRST_LOSS"           # 第一次失败
const ACHIEVEMENT_DESTROY_10 = "DESTROY_10_UNITS"    # 摧毁10个单位
const ACHIEVEMENT_BUILD_ARMY = "BUILD_ARMY"          # 爆兵20个
const ACHIEVEMENT_TECH_UP = "TECH_UP"                # 科技升级

# 成就描述（用于UI显示）
const ACHIEVEMENT_NAMES: Dictionary = {
	ACHIEVEMENT_FIRST_BUILDING: "初具规模",
	ACHIEVEMENT_FIRST_UNIT: "第一滴血",
	ACHIEVEMENT_FIRST_BATTLE: "战斗开始",
	ACHIEVEMENT_FIRST_WIN: "首战告捷",
	ACHIEVEMENT_FIRST_LOSS: "胜败乃兵家常事",
	ACHIEVEMENT_DESTROY_10: "杀手本能",
	ACHIEVEMENT_BUILD_ARMY: "大军压境",
	ACHIEVEMENT_TECH_UP: "科技进步"
}

const ACHIEVEMENT_DESCS: Dictionary = {
	ACHIEVEMENT_FIRST_BUILDING: "建造你的第一座建筑",
	ACHIEVEMENT_FIRST_UNIT: "生产你的第一个单位",
	ACHIEVEMENT_FIRST_BATTLE: "赢得你的第一场战斗",
	ACHIEVEMENT_FIRST_WIN: "击败AI获得胜利",
	ACHIEVEMENT_FIRST_LOSS: "被AI击败",
	ACHIEVEMENT_DESTROY_10: "累计摧毁10个敌方单位",
	ACHIEVEMENT_BUILD_ARMY: "同时拥有20个单位",
	ACHIEVEMENT_TECH_UP: "升级建筑科技"
}

func get_achievement_name(id: String) -> String:
	return ACHIEVEMENT_NAMES.get(id, id)

func get_achievement_desc(id: String) -> String:
	return ACHIEVEMENT_DESCS.get(id, "")
