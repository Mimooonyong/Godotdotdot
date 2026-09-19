extends Control

@onready var panel: Panel = $Panel
@onready var vbox: VBoxContainer = $Panel/VBoxContainer
@onready var grid: GridContainer = $Panel/VBoxContainer/GridContainer

const TOTAL_ROWS := 10
const QUESTION_ROWS := 5  # hanya baris 1-5 yang bisa diisi & diperiksa
const COLUMNS := ["N", "IAT", "Layanan", "Datang", "Mulai", "Selesai", "Antri", "Sistem", "Idle"]

# Semua kolom selain "N" sekarang harus diisi & dihitung sendiri oleh siswa,
# termasuk IAT dan Layanan.
const EDITABLE_COLUMNS := ["IAT", "Layanan", "Datang", "Mulai", "Selesai", "Antri", "Sistem", "Idle"]

const CELL_HEIGHT := 40
const HEADER_FONT_SIZE := 18
const CELL_FONT_SIZE := 16
const TEXT_COLOR := Color(0.12, 0.08, 0.04)  # coklat gelap/hitam

const COLOR_DEFAULT_BG := Color(1, 1, 1)
const COLOR_CORRECT_BG := Color(0.75, 0.95, 0.75)  # hijau muda
const COLOR_WRONG_BG := Color(0.98, 0.75, 0.75)    # merah muda
const FLOAT_TOLERANCE := 0.01

const ENTER_TO_NEXT_DELAY := 1.2  # jeda (detik) sebelum pindah scene, biar warna sempat kelihatan

# --- Kunci jawaban untuk IAT & Layanan (hanya dipakai untuk baris 1-5) ---
# Nilai ini TIDAK ditampilkan ke siswa; dipakai backend untuk menghitung &
# memeriksa jawaban IAT, Layanan, dan semua kolom turunannya.
@export var interarrival_times: Array[float] = [2.0, 2.0, 2.0, 2.0, 2.0]
@export var service_times: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0]

var row_inputs: Array = []
var correct_answers: Array = []  # Array[Dictionary], hasil hitung rumus baris 1-5
var enter_button: Button

func _ready() -> void:
	# --- Panel full rect dengan margin seragam 40px ---
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 40)
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
	panel.add_theme_stylebox_override("panel", panel_style)

	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)

	grid.columns = COLUMNS.size()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)

	_compute_correct_answers()
	_build_header()
	_build_rows()
	_build_enter_button()

	if SimState.batch1_done:
		_fill_locked_rows()
	else:
		_activate_question_rows()

# --- Hitung kunci jawaban untuk baris 1-5 berdasarkan rumus antrian ---
# IAT     = interarrival_times[i]
# Layanan = service_times[i]
# Datang  = Datang_sebelumnya + IAT
# Mulai   = max(Datang, Selesai_sebelumnya)
# Selesai = Mulai + Layanan
# Antri   = Mulai - Datang
# Sistem  = Selesai - Datang
# Idle    = max(0, Datang - Selesai_sebelumnya)
func _compute_correct_answers() -> void:
	correct_answers.clear()
	var prev_datang := 0.0
	var prev_selesai := 0.0

	for i in QUESTION_ROWS:
		var iat: float = interarrival_times[i]
		var layan: float = service_times[i]

		var datang: float = prev_datang + iat
		var mulai: float = max(datang, prev_selesai)
		var selesai: float = mulai + layan
		var antri: float = mulai - datang
		var sistem: float = selesai - datang
		var idle: float = max(0.0, datang - prev_selesai)

		correct_answers.append({
			"IAT": iat,
			"Layanan": layan,
			"Datang": datang,
			"Mulai": mulai,
			"Selesai": selesai,
			"Antri": antri,
			"Sistem": sistem,
			"Idle": idle,
		})

		prev_datang = datang
		prev_selesai = selesai

func _build_header() -> void:
	for col_name in COLUMNS:
		var lbl := Label.new()
		lbl.text = col_name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.custom_minimum_size = Vector2(0, CELL_HEIGHT)
		lbl.clip_text = true
		lbl.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
		lbl.add_theme_color_override("font_color", TEXT_COLOR)
		grid.add_child(lbl)

func _make_cell_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _build_rows() -> void:
	for i in TOTAL_ROWS:
		var row_dict := {}
		var is_question_row := i < QUESTION_ROWS

		for col_name in COLUMNS:
			if col_name == "N":
				var lbl := Label.new()
				lbl.text = str(i + 1)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				lbl.custom_minimum_size = Vector2(0, CELL_HEIGHT)
				lbl.add_theme_font_size_override("font_size", CELL_FONT_SIZE)
				lbl.add_theme_color_override("font_color", TEXT_COLOR)
				grid.add_child(lbl)
				row_dict[col_name] = lbl

			else:
				# col_name ada di EDITABLE_COLUMNS (IAT, Layanan, Datang, Mulai, dst).
				var edit := LineEdit.new()
				edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				edit.custom_minimum_size = Vector2(0, CELL_HEIGHT)
				edit.editable = false
				edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
				edit.add_theme_font_size_override("font_size", CELL_FONT_SIZE)
				edit.add_theme_color_override("font_color", TEXT_COLOR)
				edit.add_theme_color_override("font_uneditable_color", TEXT_COLOR)

				var edit_style := _make_cell_style(COLOR_DEFAULT_BG)
				edit.add_theme_stylebox_override("normal", edit_style)
				edit.add_theme_stylebox_override("read_only", edit_style)

				if is_question_row:
					# Baris 1-5: nanti diaktifkan (editable) & ikut dicek jawabannya.
					edit.text_changed.connect(func(_t): _update_enter_button_visibility())
				# Baris 6-10: tetap kosong & tidak pernah bisa diisi.

				grid.add_child(edit)
				row_dict[col_name] = edit

		row_inputs.append(row_dict)

func _build_enter_button() -> void:
	enter_button = Button.new()
	enter_button.text = "Enter"
	enter_button.custom_minimum_size = Vector2(160, 48)
	enter_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	enter_button.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	enter_button.visible = false
	enter_button.pressed.connect(_on_enter_button_pressed)
	vbox.add_child(enter_button)

func _activate_question_rows() -> void:
	for i in QUESTION_ROWS:
		for col_name in EDITABLE_COLUMNS:
			var field: LineEdit = row_inputs[i][col_name]
			field.editable = true
			field.text = ""
			field.add_theme_stylebox_override("normal", _make_cell_style(COLOR_DEFAULT_BG))
			field.add_theme_stylebox_override("read_only", _make_cell_style(COLOR_DEFAULT_BG))

	enter_button.visible = false
	enter_button.disabled = false

func _fill_locked_rows() -> void:
	var answers: Array = SimState.batch1_answers
	for i in answers.size():
		for col_name in EDITABLE_COLUMNS:
			row_inputs[i][col_name].text = str(answers[i].get(col_name, ""))
			row_inputs[i][col_name].editable = false

# Munculkan tombol Enter kalau semua kolom jawaban di baris 1-5 sudah terisi.
func _update_enter_button_visibility() -> void:
	for i in QUESTION_ROWS:
		for col_name in EDITABLE_COLUMNS:
			if row_inputs[i][col_name].text.strip_edges() == "":
				enter_button.visible = false
				return

	enter_button.visible = true

func _on_enter_button_pressed() -> void:
	enter_button.disabled = true

	_grade_rows()
	_save_answers()

	# Kunci semua field jawaban setelah diperiksa
	for i in QUESTION_ROWS:
		for col_name in EDITABLE_COLUMNS:
			row_inputs[i][col_name].editable = false

	# Kasih jeda sebentar biar warna merah/hijau kelihatan dulu sebelum pindah scene
	await get_tree().create_timer(ENTER_TO_NEXT_DELAY).timeout

	SimState.batch1_done = true
	get_tree().change_scene_to_file(SimState.sleep_dialog_scene_path)

# Bandingkan input siswa dengan kunci jawaban, warnai tiap sel (hijau/merah).
func _grade_rows() -> bool:
	var all_correct := true
	for i in QUESTION_ROWS:
		var expected: Dictionary = correct_answers[i]
		for col_name in EDITABLE_COLUMNS:
			var field: LineEdit = row_inputs[i][col_name]
			var is_correct := _is_answer_correct(field.text, expected[col_name])
			var bg := COLOR_CORRECT_BG if is_correct else COLOR_WRONG_BG
			field.add_theme_stylebox_override("normal", _make_cell_style(bg))
			field.add_theme_stylebox_override("read_only", _make_cell_style(bg))
			if not is_correct:
				all_correct = false
	return all_correct

func _is_answer_correct(user_text: String, expected_value: float) -> bool:
	var clean := user_text.strip_edges().replace(",", ".")
	if not clean.is_valid_float():
		return false
	return abs(clean.to_float() - expected_value) < FLOAT_TOLERANCE

func _save_answers() -> void:
	var answers := []
	for i in QUESTION_ROWS:
		var row_answer := {}
		for col_name in EDITABLE_COLUMNS:
			row_answer[col_name] = row_inputs[i][col_name].text
		answers.append(row_answer)

	SimState.batch1_answers = answers
