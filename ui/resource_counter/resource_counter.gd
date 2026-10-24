class_name ResourceCounter
extends Label

## View only: displays the shared amount of one resource and pulses on change.

@export var resource_id: StringName = &"money"
## %s is replaced by the formatted amount.
@export var format: String = "$ %s"
@export var pulse_scale: float = 1.2
@export var pulse_duration: float = 0.15

var _tween: Tween

func _ready() -> void:
	EventBus.resource_changed.connect(_on_resource_changed)
	_refresh(GameState.get_amount(resource_id))

func _on_resource_changed(changed_id: StringName, new_amount: int) -> void:
	if changed_id != resource_id:
		return
	_refresh(new_amount)
	_pulse()

func _refresh(amount: int) -> void:
	text = format % _format_number(amount)

func _pulse() -> void:
	pivot_offset = size * 0.5
	if _tween:
		_tween.kill()
	scale = Vector2.ONE * pulse_scale
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, pulse_duration)

## Single place to change when switching to a big number class.
static func _format_number(value: int) -> String:
	var digits: String = str(absi(value))
	var result: String = ""
	while digits.length() > 3:
		result = " " + digits.right(3) + result
		digits = digits.left(-3)
	return ("-" if value < 0 else "") + digits + result
