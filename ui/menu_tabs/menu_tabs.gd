class_name MenuTabs
extends BoxContainer

## Tab bar: the Nth Button child shows the Nth page and hides the others.
## Works with HBox or VBox, any number of tabs.

@export var pages: Array[Control] = []
@export var default_page: int = 0

var _buttons: Array[Button] = []

func _ready() -> void:
	var group: ButtonGroup = ButtonGroup.new()
	for child in get_children():
		if child is Button:
			_buttons.append(child)

	if _buttons.size() != pages.size():
		push_warning("MenuTabs '%s': %d buttons for %d pages" % [name, _buttons.size(), pages.size()])

	for i in _buttons.size():
		var button: Button = _buttons[i]
		button.toggle_mode = true # Active tab stays pressed
		button.button_group = group
		button.pressed.connect(show_page.bind(i))

	show_page(default_page)

func show_page(index: int) -> void:
	for i in pages.size():
		if pages[i]:
			pages[i].visible = i == index
	if index < _buttons.size():
		_buttons[index].button_pressed = true
