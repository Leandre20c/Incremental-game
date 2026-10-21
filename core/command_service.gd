extends Node

signal command_executed(command: Command, success: bool)

var _command_queue: Array[Command] = []

func dispatch(command: Command) -> void:
	if command == null:
		return
	_command_queue.append(command)

func _physics_process(_delta: float) -> void:
	process_queue()

func process_queue() -> void:
	if _command_queue.is_empty():
		return

	# Copy and clear to allow safe queuing during execution
	var current_commands: Array[Command] = _command_queue.duplicate()
	_command_queue.clear()

	for cmd in current_commands:
		var success: bool = cmd.execute()
		command_executed.emit(cmd, success)
