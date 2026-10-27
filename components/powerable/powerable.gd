class_name Powerable
extends SecondaryAction

## Child of a machine body. Turns its power state (GameState) into a power multiplier:
## 0 = off or not running, 1 = level 1, then +level_step for each level above.
## Tap the secondary key: switch on/off. Long press: settings menu (levels).
## Both work on the machine placed, lying on the floor or in hand.
## Connect power_changed to the parts that run (WindZone, BounceZone, Spinner…).

signal power_changed(power: float)

@export var level_step: float = 0.5 ## Extra power per level above 1 (0.5 = +50%)
@export var runs_while_held: bool = false ## Also runs in the player's hands (e.g. a fan used as a blower)
@export var runs_when_loose: bool = false ## Also runs lying free (not placed, not held), e.g. a fan dropped on the floor
@export var turn_on_text: String = "Turn on"
@export var turn_off_text: String = "Turn off"
@export var settings_text: String = "Settings"

var _body: Node3D
var _power: float = -1.0 ## -1 so the first refresh always emits

func _ready() -> void:
	_body = get_parent() as Node3D
	EventBus.item_power_changed.connect(_on_item_power_changed)
	EventBus.item_anchor_changed.connect(_on_item_anchor_changed)
	EventBus.item_grabbed.connect(_on_item_grabbed)
	EventBus.items_released.connect(_on_items_released)
	_refresh.call_deferred() # The spawner sets the entity_id meta right after add_child

func get_power() -> float:
	return maxf(_power, 0.0)

# --- Tap: on / off ---------------------------------------------------------

func get_prompt_text() -> String:
	return turn_off_text if GameState.is_powered(_get_entity_id()) else turn_on_text

func create_command(player_id: int) -> Command:
	var entity_id: int = _get_entity_id()
	if entity_id < 0:
		return null
	return SetPowerCommand.new(player_id, entity_id, not GameState.is_powered(entity_id), GameState.get_power_level(entity_id))

# --- Long press: settings menu ---------------------------------------------

## Only machines with intensity levels have a menu. Placed, loose or held.
func has_long_action() -> bool:
	var definition: ItemDefinition = ItemDatabase.get_definition(GameState.get_world_item(_get_entity_id()).get("item_id", &""))
	return definition != null and definition.has_power_settings()

func get_long_prompt_text() -> String:
	return "%s (Lv %d)" % [settings_text, GameState.get_power_level(_get_entity_id())]

## Local UI action: the menu dispatches the commands itself.
func perform_long(player_id: int) -> void:
	var entity_id: int = _get_entity_id()
	if entity_id >= 0:
		EventBus.machine_menu_requested.emit(player_id, entity_id)

# --- State -----------------------------------------------------------------

func _on_item_power_changed(entity_id: int) -> void:
	if entity_id == _get_entity_id():
		_refresh()

func _on_item_anchor_changed(entity_id: int, _anchored: bool) -> void:
	if entity_id == _get_entity_id():
		_refresh()

func _on_item_grabbed(_player_id: int, entity_id: int) -> void:
	if entity_id == _get_entity_id():
		_refresh()

func _on_items_released(_player_id: int, entity_ids: Array) -> void:
	if _get_entity_id() in entity_ids:
		_refresh()

func _refresh() -> void:
	var entity_id: int = _get_entity_id()
	var item: Dictionary = GameState.get_world_item(entity_id)
	var running: bool = not item.is_empty() and _is_running_state(item)
	var level: int = GameState.get_effective_power_level(entity_id) if running else 0
	var power: float = 0.0 if level <= 0 else 1.0 + (level - 1) * level_step
	if is_equal_approx(power, _power):
		return
	_power = power
	power_changed.emit(power)

## Whether the machine may run in its current state: placed, held or lying free.
func _is_running_state(item: Dictionary) -> bool:
	if item["anchored"]:
		return true
	if item["holder"] != 0:
		return runs_while_held
	return runs_when_loose

func _get_entity_id() -> int:
	return _body.get_meta(&"entity_id", -1)
