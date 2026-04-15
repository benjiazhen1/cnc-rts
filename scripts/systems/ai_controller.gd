# AI控制器
extends Node

var ai_credits: int = 2000
var ai_buildings: Array = []
var ai_units: Array = []
var strategy_timer: float = 0.0
var strategy_interval: float = 10.0  # 每10秒执行一次策略

enum AIState {BUILDING, ATTACKING, DEFENDING}
var current_state: AIState = AIState.BUILDING

func _process(delta):
	strategy_timer += delta
	if strategy_timer >= strategy_interval:
		strategy_timer = 0.0
		execute_strategy()

func execute_strategy():
	match current_state:
		AIState.BUILDING:
			ai_build_phase()
		AIState.ATTACKING:
			ai_attack_phase()
		AIState.DEFENDING:
			ai_defend_phase()
	
	# 根据情况切换状态
	if ai_units.size() >= 10:
		current_state = AIState.ATTACKING
	elif ai_buildings.size() < 3:
		current_state = AIState.BUILDING

func ai_build_phase():
	# AI建造逻辑
	ai_credits += 500  # 每回合获得资源

func ai_attack_phase():
	# AI攻击逻辑
	if ai_units.size() > 0:
		# 随机选择一个玩家单位或建筑作为攻击目标
		pass

func ai_defend_phase():
	# AI防御逻辑
	pass

func add_ai_building(building: Node):
	ai_buildings.append(building)

func add_ai_unit(unit: Node):
	ai_units.append(unit)
