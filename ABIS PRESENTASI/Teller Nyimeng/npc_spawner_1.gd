extends Control

const TOTAL_ROWS := 6

const COLUMNS := [
	"N",
	"IAT",
	"Layanan",
	"Datang",
	"Mulai",
	"Selesai",
	"Antri",
	"Sistem",
	"Idle"
]


const THE_CIRCUS_SCENE: PackedScene = preload(
	"res://the circus.tscn"
)


var grid: GridContainer
var rows: Array = []
var input_iat: Array = []
var input_layanan: Array = []
var result_labels: Array = []

var start_button: Button


func _ready() -> void:

	_build_table()

	_build_start_button()


# =========================================================
# BUAT TABEL
# =========================================================

func _build_table() -> void:

	grid = GridContainer.new()

	grid.columns = COLUMNS.size()

	grid.position = Vector2(0, 0)

	add_child(grid)


	# =========================
	# HEADER
	# =========================

	for column in COLUMNS:

		var label := _make_label(column)

		grid.add_child(label)


	# =========================
	# 6 BARIS
	# =========================

	for i in TOTAL_ROWS:

		_build_row(i)


# =========================================================
# BUAT SATU BARIS
# =========================================================

func _build_row(index: int) -> void:

	var row := {}


	# =========================
	# NOMOR
	# =========================

	var number_label := _make_label(
		str(index + 1)
	)

	grid.add_child(number_label)

	row["N"] = number_label


	# =========================
	# IAT
	# =========================

	var iat_input := _make_input()

	grid.add_child(iat_input)

	row["IAT"] = iat_input

	input_iat.append(iat_input)


	# =========================
	# LAYANAN
	# =========================

	var layanan_input := _make_input()

	grid.add_child(layanan_input)

	row["Layanan"] = layanan_input

	input_layanan.append(layanan_input)


	# =========================
	# HASIL
	# =========================

	var hasil := {}

	for column in [
		"Datang",
		"Mulai",
		"Selesai",
		"Antri",
		"Sistem",
		"Idle"
	]:

		var label := _make_label("-")

		grid.add_child(label)

		row[column] = label

		hasil[column] = label


	result_labels.append(hasil)

	rows.append(row)


# =========================================================
# LABEL
# =========================================================

func _make_label(text_value: String) -> Label:

	var label := Label.new()

	label.text = text_value

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	label.add_theme_font_size_override(
		"font_size",
		5
	)

	label.custom_minimum_size = Vector2(
		5,
		5
	)

	return label


# =========================================================
# INPUT
# =========================================================

func _make_input() -> LineEdit:

	var input := LineEdit.new()

	input.placeholder_text = "0"

	input.alignment = HORIZONTAL_ALIGNMENT_CENTER

	input.add_theme_font_size_override(
		"font_size",
		5
	)

	input.custom_minimum_size = Vector2(
		5,
		5
	)

	return input


# =========================================================
# TOMBOL PLAY
# =========================================================

func _build_start_button() -> void:

	start_button = Button.new()

	start_button.text = "▶ Play"

	start_button.position = Vector2(
		0,
		40
	)

	start_button.custom_minimum_size = Vector2(
		50,
		15
	)

	add_child(start_button)

	start_button.pressed.connect(
		_on_play_pressed
	)


	_update_start_button()


# =========================================================
# CEK INPUT
# =========================================================

func _update_start_button() -> void:

	var lengkap := true


	for i in TOTAL_ROWS:

		var iat_text: String = input_iat[i].text.strip_edges()

		var layanan_text: String = input_layanan[i].text.strip_edges()


		if iat_text == "" or layanan_text == "":

			lengkap = false

			break


	start_button.disabled = not lengkap


# =========================================================
# PLAY
# =========================================================

func _on_play_pressed() -> void:

	var data: Array = get_simulation_data()


	if data.size() != TOTAL_ROWS:

		return


	SimState2.simulation_data = data


	get_tree().change_scene_to_packed(
		THE_CIRCUS_SCENE
	)


# =========================================================
# AMBIL DATA INPUT
# =========================================================

func get_simulation_data() -> Array:

	var data: Array = []


	for i in TOTAL_ROWS:

		var iat: float = float(
			input_iat[i].text
		)

		var layanan: float = float(
			input_layanan[i].text
		)


		data.append({
			"IAT": iat,
			"Layanan": layanan
		})


	return data


# =========================================================
# ISI HASIL
# =========================================================

func set_result(
	index: int,
	datang: float,
	mulai: float,
	selesai: float,
	antri: float,
	sistem: float,
	idle: float
) -> void:

	if index < 0:

		return

	if index >= result_labels.size():

		return


	result_labels[index]["Datang"].text = _format_number(
		datang
	)

	result_labels[index]["Mulai"].text = _format_number(
		mulai
	)

	result_labels[index]["Selesai"].text = _format_number(
		selesai
	)

	result_labels[index]["Antri"].text = _format_number(
		antri
	)

	result_labels[index]["Sistem"].text = _format_number(
		sistem
	)

	result_labels[index]["Idle"].text = _format_number(
		idle
	)


# =========================================================
# FORMAT ANGKA
# =========================================================

func _format_number(value: float) -> String:

	if value < 0:

		return "-"


	return str(
		int(round(value))
	)
