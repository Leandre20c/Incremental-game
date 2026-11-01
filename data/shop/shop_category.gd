class_name ShopCategory
extends Resource

## A tab of the buy menu. Items join it with ItemDefinition.shop_category.
## Adding a tab = adding a .tres, no code.

@export var display_name: String = ""
@export var title: String = ""
@export var order: int = 0 ## Tabs are sorted by this, lowest first

func get_title() -> String:
	return title if not title.is_empty() else display_name
