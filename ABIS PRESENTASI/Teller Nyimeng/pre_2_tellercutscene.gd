extends Control

@onready var name_label: RichTextLabel = $DialogBox/Name
@onready var dialog_label: RichTextLabel = $DialogBox/Dialog
@onready var char_left: TextureRect = $CharLeft

# Isi 2 field ini lewat Inspector: drag gambar sprite ke sini
# (Sierra & HootHoot pakai sprite yang sama)
@export var sierra_texture: Texture2D
@export var caine_texture: Texture2D

var dialog_lines: Array = [
	{"name": "HootHoot", "text": "Terus gimana dong..?"},
	{"name": "Caine", "text": "UHmmm kalo gitu kubikinin worksheet ajaib aja! nanti antriannya sesuai angka yg kamu masukkan"},
	{"name": "HootHoot", "text": "Hah bisa gitu??"},
	{"name": "Caine", "text": "BISAAA, sekalian jadi teller aja yuk"},
	{"name": "HootHoot", "text": "weh??"},
]

var current_line: int = 0

func _ready() -> void:
	display_line()

func display_line() -> void:
	var line = dialog_lines[current_line]
	name_label.text = line["name"]
	dialog_label.text = line["text"]
	_update_char_sprite(line["name"])

func _update_char_sprite(speaker_name: String) -> void:
	match speaker_name:
		"Sierra", "HootHoot":
			char_left.texture = sierra_texture
		"Caine":
			char_left.texture = caine_texture

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		next_line()

func next_line() -> void:
	current_line += 1
	if current_line < dialog_lines.size():
		display_line()
	else:
		get_tree().quit()
