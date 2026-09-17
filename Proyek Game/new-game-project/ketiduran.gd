extends Control

@onready var name_label: RichTextLabel = $DialogBox/Name
@onready var dialog_label: RichTextLabel = $DialogBox/Dialog

var dialog_lines: Array = [
	{"name": "Sierra", "text": "Aduh.. ngantuk.."},
	{"name": "Sierra", "text": "Ini lagi istirahat siang si.."}
]

var current_line: int = 0

func _ready() -> void:
	display_line()

func display_line() -> void:
	var line = dialog_lines[current_line]
	name_label.text = line["name"]
	dialog_label.text = line["text"]

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		next_line()

func next_line() -> void:
	current_line += 1
	if current_line < dialog_lines.size():
		display_line()
	else:
		get_tree().change_scene_to_file(SimState.welcome_tadc_scene_path)
