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

var grid: GridContainer
var rows: Array = []


func _ready() -> void:

	# =========================
	# BACKGROUND PANEL
	# =========================

	var panel := Panel.new()

	panel.position = Vector2(0, 0)

	# 9 kolom x 5 px
	# 7 baris x 5 px
	panel.size = Vector2(45, 35)

	add_child(panel)


	# =========================
	# GRID
	# =========================

	grid = GridContainer.new()

	grid.columns = COLUMNS.size()

	grid.position = Vector2(0, 0)

	panel.add_child(grid)


	# =========================
	# BUAT TABEL
	# =========================

	_build_header()
	_build_rows()
	_load_simulation_data()


func _make_label(text_value: String) -> Label:

	var label := Label.new()

	label.text = text_value

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	label.add_theme_font_size_override(
		"font_size",
		5
	)

	label.custom_minimum_size = Vector2(5, 5)

	return label


func _build_header() -> void:

	for column in COLUMNS:

		var label := _make_label(column)

		grid.add_child(label)


func _build_rows() -> void:

	for i in TOTAL_ROWS:

		var row := {}


		# =========================
		# NOMOR
		# =========================

		var number_label := _make_label(
			str(i + 1)
		)

		grid.add_child(number_label)

		row["N"] = number_label


		# =========================
		# KOLOM DATA
		# =========================

		for column in [
			"IAT",
			"Layanan",
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


		rows.append(row)


func _load_simulation_data() -> void:

	var data: Array = SimState2.simulation_data

	for i in data.size():

		if i >= TOTAL_ROWS:
			break

		rows[i]["IAT"].text = str(
			data[i]["IAT"]
		)

		rows[i]["Layanan"].text = str(
			data[i]["Layanan"]
		)


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

	if index >= rows.size():
		return

	rows[index]["Datang"].text = str(
		datang
	)

	rows[index]["Mulai"].text = str(
		mulai
	)

	rows[index]["Selesai"].text = str(
		selesai
	)

	rows[index]["Antri"].text = str(
		antri
	)

	rows[index]["Sistem"].text = str(
		sistem
	)

	rows[index]["Idle"].text = str(
		idle
	)
