extends Control

# =========================================================
# SIMULASI ANTRIAN — 1 ANTRIAN, 2 TELLER
#
# Aturan:
# - Cuma ada 1 antrian (satu baris pelanggan).
# - Ada 2 teller. Tiap pelanggan dilayani teller yang lebih
#   dulu kosong. Kalau kedua teller kosong bareng, Teller 1
#   didahulukan. Pelanggan pertama selalu ke Teller 1.
#
# Rumus (n = baris ke-n, dimulai dari baris pertama):
#   Datang  = Datang sebelumnya + IAT   (baris pertama = IAT-nya sendiri)
#   Teller  = 1 kalau SelT1_prev <= SelT2_prev, else 2
#   Mulai   = MAX(Datang, MIN(SelT1_prev, SelT2_prev))
#   Selesai = Mulai + Layanan
#   SelT1   = Selesai kalau dilayani Teller 1, else tetap SelT1_prev
#   SelT2   = Selesai kalau dilayani Teller 2, else tetap SelT2_prev
#   Antri   = Mulai - Datang
#   Sistem  = Selesai - Datang
#   Idle    = Mulai - (SelT1_prev atau SelT2_prev, sesuai teller yang melayani)
# =========================================================

const TOTAL_ROWS := 6

const RESULT_COLUMNS := [
	"N",
	"IAT",
	"Layanan",
	"Datang",
	"Teller",
	"Mulai",
	"Selesai",
	"Antri",
	"Sistem",
	"Idle",
]

# GANTI path ini sesuai lokasi scene circus-mu
const THE_CIRCUS_SCENE: PackedScene = preload(
	"res://circus 2 teller.tscn"
)

var iat_inputs: Array = []
var layan_inputs: Array = []

var result_grid: GridContainer
var hitung_button: Button
var mulai_button: Button

# hasil simulasi terakhir, siap dikirim ke scene circus
var last_result: Array = []


# =========================================================
# WARNA & GAYA
# (palet sama seperti worksheet HTML-nya: biru/merah di atas paper)
# =========================================================

const INK          := Color("#1B2436")
const SLATE        := Color("#5C6678")
const PAPER        := Color("#F3F5FA")
const PANEL_WHITE  := Color("#FFFFFF")

const BLUE         := Color("#153E7B")
const BLUE_LIGHT   := Color("#2758A8")
const BLUE_TINT    := Color("#DCE7F7")

const RED          := Color("#B3241E")
const RED_LIGHT    := Color("#D8433C")
const RED_TINT     := Color("#FBE0DE")

const LINE         := Color("#DCE2ED")
const LINE_STRONG  := Color("#B7C2D6")


func _stylebox(bg: Color, border: Color = Color(0, 0, 0, 0),
		border_w: int = 0, radius: int = 6,
		margin_h: int = 10, margin_v: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = margin_h
	sb.content_margin_right = margin_h
	sb.content_margin_top = margin_v
	sb.content_margin_bottom = margin_v
	return sb


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg_panel := PanelContainer.new()
	bg_panel.add_theme_stylebox_override("panel", _stylebox(PAPER, LINE_STRONG, 1, 8, 0, 0))
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 26)
	bg_panel.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 16)
	margin.add_child(root_vbox)

	# ---------- judul ----------
	var title_panel := PanelContainer.new()
	title_panel.add_theme_stylebox_override("panel", _stylebox(BLUE, Color(0,0,0,0), 0, 6, 20, 14))
	root_vbox.add_child(title_panel)

	var title := Label.new()
	title.text = "SIMULASI ANTRIAN — 1 ANTRIAN, 2 TELLER"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", PANEL_WHITE)
	title_panel.add_child(title)

	# ---------- input ----------
	var input_label := _section_label("Data Pelanggan (IAT & Layanan)")
	root_vbox.add_child(input_label)

	var input_grid := GridContainer.new()
	input_grid.columns = 3
	input_grid.add_theme_constant_override("h_separation", 2)
	input_grid.add_theme_constant_override("v_separation", 2)
	root_vbox.add_child(input_grid)

	for header_text in ["N", "IAT", "Layanan"]:
		input_grid.add_child(_header_cell(header_text))

	for i in TOTAL_ROWS:
		var alt: bool = (i % 2 == 1)

		input_grid.add_child(_data_cell(str(i + 1), alt))

		var iat_input := _make_input(alt)
		input_grid.add_child(iat_input)
		iat_inputs.append(iat_input)

		var layan_input := _make_input(alt)
		input_grid.add_child(layan_input)
		layan_inputs.append(layan_input)

	# ---------- tombol ----------
	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)
	root_vbox.add_child(button_row)

	hitung_button = Button.new()
	hitung_button.text = "Hitung Simulasi"
	hitung_button.custom_minimum_size = Vector2(170, 40)
	hitung_button.pressed.connect(_on_hitung_pressed)
	_style_button(hitung_button, BLUE, BLUE_LIGHT, PANEL_WHITE)
	button_row.add_child(hitung_button)

	mulai_button = Button.new()
	mulai_button.text = "▶ Mulai (ke Circus)"
	mulai_button.custom_minimum_size = Vector2(190, 40)
	mulai_button.disabled = true
	mulai_button.pressed.connect(_on_mulai_pressed)
	_style_button(mulai_button, RED, RED_LIGHT, PANEL_WHITE)
	button_row.add_child(mulai_button)

	# ---------- hasil ----------
	var result_label := _section_label("Hasil Simulasi")
	root_vbox.add_child(result_label)

	var result_scroll := ScrollContainer.new()
	result_scroll.custom_minimum_size = Vector2(0, 260)
	root_vbox.add_child(result_scroll)

	result_grid = GridContainer.new()
	result_grid.columns = RESULT_COLUMNS.size()
	result_grid.add_theme_constant_override("h_separation", 2)
	result_grid.add_theme_constant_override("v_separation", 2)
	result_scroll.add_child(result_grid)
	_build_result_header()


func _build_result_header() -> void:
	for column in RESULT_COLUMNS:
		result_grid.add_child(_header_cell(column))


# =========================================================
# SECTION LABEL
# =========================================================

func _section_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", SLATE)
	return label


# =========================================================
# SEL TABEL (header & data), DIBUNGKUS PanelContainer BIAR
# ADA WARNA LATAR & GARIS PEMISAH
# =========================================================

func _header_cell(text_value: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _stylebox(BLUE, Color(0,0,0,0), 0, 0, 8, 7))
	panel.custom_minimum_size = Vector2(74, 0)

	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", PANEL_WHITE)
	panel.add_child(label)
	return panel


func _data_cell(text_value: String, alt: bool = false, accent: Color = INK) -> PanelContainer:
	var bg: Color = BLUE_TINT if alt else PANEL_WHITE
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _stylebox(bg, LINE, 1, 0, 8, 7))
	panel.custom_minimum_size = Vector2(74, 0)

	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", accent)
	panel.add_child(label)
	return panel


# kartu kecil warna beda buat "Teller 1" / "Teller 2" biar gampang dibedain
func _teller_cell(teller_id: int, alt: bool) -> PanelContainer:
	var bg: Color = RED_TINT if teller_id == 1 else BLUE_TINT
	var fg: Color = RED if teller_id == 1 else BLUE

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _stylebox(bg, LINE, 1, 0, 8, 7))
	panel.custom_minimum_size = Vector2(74, 0)

	var label := Label.new()
	label.text = "Teller %d" % teller_id
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", fg)
	panel.add_child(label)
	return panel


# =========================================================
# INPUT HELPER
# =========================================================

func _make_input(alt: bool = false) -> LineEdit:
	var input := LineEdit.new()
	input.placeholder_text = "0"
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.custom_minimum_size = Vector2(74, 34)

	var bg: Color = BLUE_TINT if alt else PANEL_WHITE
	var normal := _stylebox(bg, LINE_STRONG, 1, 4, 8, 4)
	var focus := _stylebox(PANEL_WHITE, RED, 2, 4, 8, 4)

	input.add_theme_stylebox_override("normal", normal)
	input.add_theme_stylebox_override("focus", focus)
	input.add_theme_color_override("font_color", INK)
	input.add_theme_color_override("font_placeholder_color", LINE_STRONG)
	return input


# =========================================================
# TOMBOL HELPER
# =========================================================

func _style_button(button: Button, base_color: Color, hover_color: Color, text_color: Color) -> void:
	var normal := _stylebox(base_color, Color(0,0,0,0), 0, 5, 16, 10)
	var hover := _stylebox(hover_color, Color(0,0,0,0), 0, 5, 16, 10)
	var pressed := _stylebox(base_color.darkened(0.15), Color(0,0,0,0), 0, 5, 16, 10)
	var disabled := _stylebox(LINE_STRONG, Color(0,0,0,0), 0, 5, 16, 10)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", SLATE)
	button.add_theme_font_size_override("font_size", 14)


# =========================================================
# TOMBOL "HITUNG SIMULASI" DITEKAN
# =========================================================

func _on_hitung_pressed() -> void:
	var customers: Array = []
	var datang_sebelumnya := 0.0

	for i in TOTAL_ROWS:
		var iat_text: String = iat_inputs[i].text.strip_edges()
		var layan_text: String = layan_inputs[i].text.strip_edges()

		var iat: float = float(iat_text) if iat_text != "" else 0.0
		var layan: float = float(layan_text) if layan_text != "" else 0.0

		var datang: float
		if i == 0:
			datang = iat
		else:
			datang = datang_sebelumnya + iat
		datang_sebelumnya = datang

		customers.append({
			"n": i + 1,
			"iat": iat,
			"layan": layan,
			"datang": datang,
			"teller": 0,
			"mulai": 0.0,
			"selesai": 0.0,
			"antri": 0.0,
			"sistem": 0.0,
			"idle": 0.0,
		})

	_simulate_two_tellers(customers)
	_render_result(customers)

	last_result = customers
	mulai_button.disabled = false


# =========================================================
# SIMULASI 2 TELLER, 1 ANTRIAN
# =========================================================

func _simulate_two_tellers(customers: Array) -> void:
	var sel_t1 := 0.0
	var sel_t2 := 0.0

	for i in customers.size():
		var c: Dictionary = customers[i]
		var datang: float = c["datang"]

		var teller: int
		var mulai: float
		var idle: float

		if i == 0:
			teller = 1
			mulai = datang
			idle = datang
		else:
			teller = 1 if sel_t1 <= sel_t2 else 2
			mulai = max(datang, min(sel_t1, sel_t2))
			var prev_teller_selesai: float = sel_t1 if teller == 1 else sel_t2
			idle = max(mulai - prev_teller_selesai, 0.0)

		var selesai: float = mulai + c["layan"]

		if teller == 1:
			sel_t1 = selesai
		else:
			sel_t2 = selesai

		c["teller"] = teller
		c["mulai"] = mulai
		c["selesai"] = selesai
		c["antri"] = mulai - datang
		c["sistem"] = selesai - datang
		c["idle"] = idle
		customers[i] = c


# =========================================================
# TAMPILKAN HASIL
# =========================================================

func _render_result(customers: Array) -> void:
	# buang semua baris hasil lama, sisakan header (10 sel pertama)
	var children := result_grid.get_children()
	for i in range(RESULT_COLUMNS.size(), children.size()):
		children[i].queue_free()

	for i in customers.size():
		var c: Dictionary = customers[i]
		var alt: bool = (i % 2 == 1)

		result_grid.add_child(_data_cell(str(c["n"]), alt))
		result_grid.add_child(_data_cell(_fmt(c["iat"]), alt))
		result_grid.add_child(_data_cell(_fmt(c["layan"]), alt))
		result_grid.add_child(_data_cell(_fmt(c["datang"]), alt))
		result_grid.add_child(_teller_cell(c["teller"], alt))
		result_grid.add_child(_data_cell(_fmt(c["mulai"]), alt))
		result_grid.add_child(_data_cell(_fmt(c["selesai"]), alt))
		result_grid.add_child(_data_cell(_fmt(c["antri"]), alt, RED))
		result_grid.add_child(_data_cell(_fmt(c["sistem"]), alt))
		result_grid.add_child(_data_cell(_fmt(c["idle"]), alt, SLATE))


func _fmt(value: float) -> String:
	return str(int(round(value)))


# =========================================================
# TOMBOL "MULAI (KE CIRCUS)" DITEKAN
# Kirim hasil ke autoload SimState2, lalu pindah scene.
# =========================================================

func _on_mulai_pressed() -> void:
	if last_result.is_empty():
		return

	# Autoload SimState2 harus sudah didaftarkan di
	# Project > Project Settings > Autoload, dengan nama "SimState2".
	var sim_state = get_node("/root/SimState2")

	# Array of Dictionary, tiap item:
	# { n, iat, layan, datang, teller (1/2), mulai, selesai, antri, sistem, idle }
	sim_state.simulation_data = last_result

	get_tree().change_scene_to_packed(THE_CIRCUS_SCENE)
