## Game State Machine - Manages global game state and phase transitions.
## Handles resources, player/AI entities, and game flow between menu/play/gameover states.
extends Node

## Game phases for state machine
enum GamePhase {
	MENU,       ## Main menu state
	LOADING,    ## Loading between states
	PLAYING,    ## Active gameplay
	PAUSED,     ## Game paused
	GAME_OVER,  ## Game ended (victory or defeat)
}

## Current game phase
var current_phase: GamePhase = GamePhase.MENU

## Player resources
var credits: int = 1000
var credits_per_minute: int = 100

## Entity tracking arrays
var player_buildings: Array = []
var player_units: Array = []
var ai_buildings: Array = []
var ai_units: Array = []

## Map configuration
var current_map: String = "map_01"
var map_size: Vector2i = Vector2i(64, 64)

## Game speed multiplier
var game_speed: float = 1.0
var is_paused: bool = false

## Game outcome tracking
var game_outcome: String = ""  # "victory" or "defeat"

## Signal declarations for phase changes and events
signal phase_changed(new_phase: GamePhase)
signal credits_changed(new_amount: int)
signal game_over(outcome: String)
signal player_base_destroyed()
signal ai_base_destroyed()

func _ready() -> void:
	"""Initialize the game state machine."""
	_debug_print("GameStateMachine: Initialized")


## Starts a new game with fresh state.
## Resets all resources, clears entity arrays, and transitions to PLAYING phase.
func start_new_game() -> void:
	_debug_print("GameStateMachine: Starting new game")

	current_phase = GamePhase.PLAYING
	credits = 1000
	game_speed = 1.0
	is_paused = false
	game_outcome = ""

	# Clear all entity arrays
	player_buildings.clear()
	player_units.clear()
	ai_buildings.clear()
	ai_units.clear()

	emit_signal("phase_changed", current_phase)
	emit_signal("credits_changed", credits)


## Pauses the game and transitions to PAUSED phase.
func pause_game() -> void:
	if current_phase != GamePhase.PLAYING:
		return

	is_paused = true
	current_phase = GamePhase.PAUSED
	emit_signal("phase_changed", current_phase)
	_debug_print("GameStateMachine: Game paused")


## Resumes the game from PAUSED to PLAYING phase.
func resume_game() -> void:
	if current_phase != GamePhase.PAUSED:
		return

	is_paused = false
	current_phase = GamePhase.PLAYING
	emit_signal("phase_changed", current_phase)
	_debug_print("GameStateMachine: Game resumed")


## Returns to main menu, resetting to MENU phase.
func return_to_menu() -> void:
	current_phase = GamePhase.MENU
	is_paused = false
	emit_signal("phase_changed", current_phase)
	_debug_print("GameStateMachine: Returned to menu")


## Triggers game over with specified outcome.
## [param outcome] should be "victory" or "defeat".
func trigger_game_over(outcome: String) -> void:
	if current_phase == GamePhase.GAME_OVER:
		return  # Already in game over state

	game_outcome = outcome
	current_phase = GamePhase.GAME_OVER
	emit_signal("phase_changed", current_phase)
	emit_signal("game_over", outcome)
	_debug_print("GameStateMachine: Game over - " + outcome)


## Adds credits to player's resource pool.
## [param amount] The number of credits to add.
func add_credits(amount: int) -> void:
	if amount < 0:
		_debug_print("GameStateMachine: Warning - negative credit amount")
		return

	credits += amount
	emit_signal("credits_changed", credits)


## Attempts to spend credits if sufficient funds exist.
## [param amount] The cost to deduct.
## [return] true if transaction successful, false if insufficient credits.
func spend_credits(amount: int) -> bool:
	if amount < 0:
		_debug_print("GameStateMachine: Warning - negative spend amount")
		return false

	if credits < amount:
		_debug_print("GameStateMachine: Insufficient credits - needed %d, have %d" % [amount, credits])
		return false

	credits -= amount
	emit_signal("credits_changed", credits)
	return true


## Returns the current credit generation rate based on buildings.
## Each building generates 10 credits per minute.
func get_credit_rate() -> int:
	return player_buildings.size() * 10


## Checks if player has any remaining Command Centers.
## [return] true if player has at least one Command Center.
func has_player_command_center() -> bool:
	for building in player_buildings:
		if is_instance_valid(building) and building.building_name == "Command Center":
			return true
	return false


## Checks if AI has any remaining Command Centers.
## [return] true if AI has at least one Command Center.
func has_ai_command_center() -> bool:
	for building in ai_buildings:
		if is_instance_valid(building) and building.building_name == "Command Center":
			return true
	return false


## Registers a building to the appropriate owner's tracking array.
## [param building] The building instance to register.
## [param owner] Either "player" or "ai".
func register_building(building: Node, owner: String) -> void:
	if not is_instance_valid(building):
		_debug_print("GameStateMachine: Warning - attempted to register invalid building")
		return

	if owner == "player":
		if not building in player_buildings:
			player_buildings.append(building)
			building.destroyed.connect(_on_player_building_destroyed)
	elif owner == "ai":
		if not building in ai_buildings:
			ai_buildings.append(building)
			building.destroyed.connect(_on_ai_building_destroyed)
	else:
		_debug_print("GameStateMachine: Warning - unknown owner '%s'" % owner)


## Unregisters a building from tracking arrays.
## [param building] The building instance to remove.
func unregister_building(building: Node) -> void:
	if not is_instance_valid(building):
		return

	player_buildings.erase(building)
	ai_buildings.erase(building)


## Registers a unit to the appropriate owner's tracking array.
## [param unit] The unit instance to register.
## [param owner] Either "player" or "ai".
func register_unit(unit: Node, owner: String) -> void:
	if not is_instance_valid(unit):
		_debug_print("GameStateMachine: Warning - attempted to register invalid unit")
		return

	if owner == "player":
		if not unit in player_units:
			player_units.append(unit)
			unit.destroyed.connect(_on_player_unit_destroyed)
	elif owner == "ai":
		if not unit in ai_units:
			ai_units.append(unit)
			unit.destroyed.connect(_on_ai_unit_destroyed)
	else:
		_debug_print("GameStateMachine: Warning - unknown owner '%s'" % owner)


## Unregisters a unit from tracking arrays.
## [param unit] The unit instance to remove.
func unregister_unit(unit: Node) -> void:
	if not is_instance_valid(unit):
		return

	player_units.erase(unit)
	ai_units.erase(unit)


## Called when a player building is destroyed.
func _on_player_building_destroyed() -> void:
	# Clean up the reference from player_buildings
	var building = get_instance_from_signal_connection()
	if building != null:
		unregister_building(building)

	# Check if player lost their command center
	if not has_player_command_center():
		emit_signal("player_base_destroyed")
		trigger_game_over("defeat")


## Called when an AI building is destroyed.
func _on_ai_building_destroyed() -> void:
	# Clean up the reference from ai_buildings
	var building = get_instance_from_signal_connection()
	if building != null:
		unregister_building(building)

	# Check if AI lost their command center
	if not has_ai_command_center():
		emit_signal("ai_base_destroyed")
		trigger_game_over("victory")


## Called when a player unit is destroyed.
func _on_player_unit_destroyed() -> void:
	var unit = get_instance_from_signal_connection()
	if unit != null:
		unregister_unit(unit)


## Called when an AI unit is destroyed.
func _on_ai_unit_destroyed() -> void:
	var unit = get_instance_from_signal_connection()
	if unit != null:
		unregister_unit(unit)


## Helper to get object from signal connection (Godot 4.x compatible).
func get_instance_from_signal_connection() -> Node:
	# In Godot 4, connected signals pass the object directly
	# This is a fallback for proper cleanup
	return null


## Debug print helper that only prints in debug builds.
func _debug_print(message: String) -> void:
	# Only print if not in release/headless mode
	if OS.has_feature("debug") or true:  # Enable for development
		print(message)
