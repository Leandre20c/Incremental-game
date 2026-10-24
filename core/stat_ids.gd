@tool
class_name StatIds
extends RefCounted

## Every stat an upgrade can modify. Single source of truth for stat ids.

## Harvest speed multiplier of fishing spots (1.0 = normal, 2.0 = twice as fast).
const FISHING_SPEED: StringName = &"fishing_speed"

const ALL: Array[StringName] = [
	FISHING_SPEED,
]
