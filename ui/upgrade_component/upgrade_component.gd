class_name UpgradeComponent
extends HBoxContainer

## One upgrade line: shows name, level, preview and cost, dispatches BuyUpgradeCommand on click.
## View only, never mutates state directly.

@export var upgrade: UpgradeDefinition
@export var player_id: int = 1

@onready var _title_label: Label = $TitleLabel
@onready var _level_label: Label = $LevelLabel
@onready var _preview_label: Label = $PreviewLabel
@onready var _button: Button = $Button

func _ready() -> void:
	if upgrade == null:
		push_warning("UpgradeComponent '%s': no upgrade assigned" % name)
		hide()
		return
	_title_label.text = upgrade.display_name
	# Button stops the mouse, so it needs the tooltip too
	tooltip_text = upgrade.description
	_button.tooltip_text = upgrade.description
	_button.pressed.connect(_on_button_pressed)
	EventBus.upgrade_level_changed.connect(_on_upgrade_level_changed)
	EventBus.resource_changed.connect(_on_resource_changed)
	_refresh()

func _refresh() -> void:
	var level: int = GameState.get_upgrade_level(upgrade.id)
	var maxed: bool = upgrade.is_maxed(level)
	var cost: int = upgrade.get_cost(level)

	if upgrade.max_level > 0:
		_level_label.text = "[%d / %d]" % [level, upgrade.max_level]
	else:
		_level_label.text = "[%d]" % level

	_preview_label.text = _get_preview_text(level, maxed)
	_preview_label.visible = not _preview_label.text.is_empty()

	_button.text = "MAX" if maxed else "%d $" % cost
	_button.disabled = maxed or GameState.get_amount(upgrade.cost_resource_id) < cost

func _get_preview_text(level: int, maxed: bool) -> String:
	var stat: StatDefinition = upgrade.preview_stat
	if stat == null:
		return ""
	var current: String = stat.display_format % Stats.preview(stat, upgrade.id, level)
	if maxed:
		return current
	return "%s -> %s" % [current, stat.display_format % Stats.preview(stat, upgrade.id, level + 1)]


func _on_button_pressed() -> void:
	CommandService.dispatch(BuyUpgradeCommand.new(player_id, upgrade.id))

func _on_upgrade_level_changed(upgrade_id: StringName, _level: int) -> void:
	if upgrade_id == upgrade.id:
		_refresh()

func _on_resource_changed(resource_id: StringName, _amount: int) -> void:
	if resource_id == upgrade.cost_resource_id:
		_refresh()
