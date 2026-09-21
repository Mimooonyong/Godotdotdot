extends Control

@onready var panel: Panel = $Panel
@onready var vbox: VBoxContainer = $Panel/VBoxContainer
@onready var grid: GridContainer = $Panel/VBoxContainer/GridContainer


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

const INPUT_COLUMNS := [
	"IAT",
	"Layanan"
]

const CELL_HEIGHT := 40
const HEADER_FONT_SIZE := 18
const CELL_FONT_SIZE := 16

const TEXT_COLOR := Color(0.12, 0.08, 0.04)

const COLOR_DEFAULT_BG := Color(1, 1, 1)
const COLOR_RESULT_BG := Color(0.92, 0.92, 0.92)


var row_inputs: Array = []

var start_button: Button


func _ready() -> void:

	# ==========================================================
	# PANEL
	# ==========================================================

	panel.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT,
		Control.PRESET_MODE_KEEP_SIZE,
		40
	)

	panel.clip_contents = true

	var panel_style := StyleBoxFlat.new()

	panel_style.bg_color = Color(0.96, 0.94, 0.88)

	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12

	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 24

	panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)


	# ==========================================================
	# VBOX
	# ==========================================================

	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)

	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	vbox.add_theme_constant_override(
		"separation",
		16
	)


	# ==========================================================
	# GRID
	# ==========================================================

	grid.columns = COLUMNS.size()

	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL

	grid.add_theme_constant_override(
		"h_separation",
		8
	)

	grid.add_theme_constant_override(
		"v_separation",
		8
	)


	# ==========================================================
	# BIKIN TABEL
	# ==========================================================

	_build_header()

	_build_rows()

	_build_start_button()


# ==========================================================
# HEADER
# ==========================================================

func _build_header() -> void:

	for col_name in COLUMNS:

		var label := Label.new()

		label.text = col_name

		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		label.custom_minimum_size = Vector2(
			0,
			CELL_HEIGHT
		)

		label.clip_text = true

		label.add_theme_font_size_override(
			"font_size",
			HEADER_FONT_SIZE
		)

		label.add_theme_color_override(
			"font_color",
			TEXT_COLOR
		)

		grid.add_child(label)


# ==========================================================
# STYLE CELL
# ==========================================================

func _make_cell_style(bg_color: Color) -> StyleBoxFlat:

	var style := StyleBoxFlat.new()

	style.bg_color = bg_color

	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	return style


# ==========================================================
# BIKIN ROW
# ==========================================================

func _build_rows() -> void:

	for i in TOTAL_ROWS:

		var row_dict := {}

		for col_name in COLUMNS:

			# --------------------------------------------------
			# KOLOM N
			# --------------------------------------------------

			if col_name == "N":

				var label := Label.new()

				label.text = str(i + 1)

				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

				label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

				label.custom_minimum_size = Vector2(
					0,
					CELL_HEIGHT
				)

				label.add_theme_font_size_override(
					"font_size",
					CELL_FONT_SIZE
				)

				label.add_theme_color_override(
					"font_color",
					TEXT_COLOR
				)

				grid.add_child(label)

				row_dict[col_name] = label


			# --------------------------------------------------
			# KOLOM LAIN
			# --------------------------------------------------

			else:

				var edit := LineEdit.new()

				edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL

				edit.custom_minimum_size = Vector2(
					0,
					CELL_HEIGHT
				)

				edit.alignment = HORIZONTAL_ALIGNMENT_CENTER

				edit.add_theme_font_size_override(
					"font_size",
					CELL_FONT_SIZE
				)

				edit.add_theme_color_override(
					"font_color",
					TEXT_COLOR
				)

				edit.add_theme_color_override(
					"font_uneditable_color",
					TEXT_COLOR
				)

				edit.add_theme_stylebox_override(
					"normal",
					_make_cell_style(COLOR_DEFAULT_BG)
				)

				edit.add_theme_stylebox_override(
					"read_only",
					_make_cell_style(COLOR_RESULT_BG)
				)


				# --------------------------------------------------
				# IAT + LAYANAN BISA DIISI
				# --------------------------------------------------

				if col_name in INPUT_COLUMNS:

					edit.editable = true

					edit.text_changed.connect(
						func(_text):
							_update_start_button()
					)

				else:

					edit.editable = false


				grid.add_child(edit)

				row_dict[col_name] = edit


		row_inputs.append(row_dict)


# ==========================================================
# TOMBOL PLAY
# ==========================================================

func _build_start_button() -> void:

	start_button = Button.new()

	start_button.text = "▶ Play"

	start_button.custom_minimum_size = Vector2(
		200,
		48
	)

	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	start_button.add_theme_font_size_override(
		"font_size",
		HEADER_FONT_SIZE
	)

	start_button.disabled = true

	start_button.pressed.connect(
		_on_start_button_pressed
	)

	vbox.add_child(start_button)


# ==========================================================
# CEK DATA
# ==========================================================

func _update_start_button() -> void:

	for i in TOTAL_ROWS:

		var iat_text: String = row_inputs[i]["IAT"].text.strip_edges()

		var layanan_text: String = row_inputs[i]["Layanan"].text.strip_edges()

		if iat_text == "" or layanan_text == "":

			start_button.disabled = true

			return


	start_button.disabled = false


# ==========================================================
# PLAY
# ==========================================================
func _on_start_button_pressed() -> void:

	print("1. TOMBOL DIKLIK")

	var data := get_simulation_data()

	print("2. DATA: ", data)

	if data.size() != TOTAL_ROWS:
		print("3. DATA TIDAK LENGKAP")
		return

	print("4. SIMPAN DATA")

	SimState2.simulation_data = data

	print("5. SIMSTATE2 BERHASIL")

	print("FILE ADA: ", FileAccess.file_exists("res://the_circus.tscn"))
	print("RESOURCE ADA: ", ResourceLoader.exists("res://the_circus.tscn"))

	start_button.disabled = true

	print("6. MAU PINDAH SCENE")

	var hasil := get_tree().change_scene_to_file("res://the_circus.tscn")

	print("7. HASIL: ", hasil)

# ==========================================================
# AMBIL DATA DARI TABEL
# ==========================================================

func get_simulation_data() -> Array:

	var data: Array = []

	for i in TOTAL_ROWS:

		var iat_text: String = row_inputs[i]["IAT"].text.strip_edges()

		var layanan_text: String = row_inputs[i]["Layanan"].text.strip_edges()


		if iat_text == "" or layanan_text == "":

			return []


		var iat: float = iat_text.replace(",", ".").to_float()

		var layanan: float = layanan_text.replace(",", ".").to_float()


		data.append({
			"IAT": iat,
			"Layanan": layanan
		})


	return data


# ==========================================================
# ISI HASIL KE TABEL
# ==========================================================

func set_result(
	index: int,
	datang: float,
	mulai: float,
	selesai: float,
	antri: float,
	sistem: float,
	idle: float
) -> void:

	if index < 0 or index >= TOTAL_ROWS:

		return


	row_inputs[index]["Datang"].text = str(snapped(datang, 0.01))

	row_inputs[index]["Mulai"].text = str(snapped(mulai, 0.01))

	row_inputs[index]["Selesai"].text = str(snapped(selesai, 0.01))

	row_inputs[index]["Antri"].text = str(snapped(antri, 0.01))

	row_inputs[index]["Sistem"].text = str(snapped(sistem, 0.01))

	row_inputs[index]["Idle"].text = str(snapped(idle, 0.01))
