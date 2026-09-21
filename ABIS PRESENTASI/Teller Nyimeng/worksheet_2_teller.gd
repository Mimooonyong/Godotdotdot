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
# READY
# =========================================================

func _ready() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 14)
	add_child(root_vbox)

	var title := Label.new()
	title.text = "SIMULASI ANTRIAN — 1 ANTRIAN, 2 TELLER"
	title.add_theme_font_size_override("font_size", 20)
	root_vbox.add_child(title)

	var input_grid := GridContainer.new()
	input_grid.columns = 3
	root_vbox.add_child(input_grid)

	for header_text in ["N", "IAT", "Layanan"]:
		input_grid.add_child(_make_label(header_text))

	for i in TOTAL_ROWS:
		input_grid.add_child(_make_label(str(i + 1)))

		var iat_input := _make_input()
		input_grid.add_child(iat_input)
		iat_inputs.append(iat_input)

		var layan_input := _make_input()
		input_grid.add_child(layan_input)
		layan_inputs.append(layan_input)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)
	root_vbox.add_child(button_row)

	hitung_button = Button.new()
	hitung_button.text = "Hitung Simulasi"
	hitung_button.custom_minimum_size = Vector2(160, 36)
	hitung_button.pressed.connect(_on_hitung_pressed)
	button_row.add_child(hitung_button)

	mulai_button = Button.new()
	mulai_button.text = "▶ Mulai (ke Circus)"
	mulai_button.custom_minimum_size = Vector2(180, 36)
	mulai_button.disabled = true
	mulai_button.pressed.connect(_on_mulai_pressed)
	button_row.add_child(mulai_button)

	var result_title := Label.new()
	result_title.text = "Hasil"
	root_vbox.add_child(result_title)

	result_grid = GridContainer.new()
	result_grid.columns = RESULT_COLUMNS.size()
	root_vbox.add_child(result_grid)
	_build_result_header()


func _build_result_header() -> void:
	for column in RESULT_COLUMNS:
		result_grid.add_child(_make_label(column))


# =========================================================
# LABEL & INPUT HELPER
# =========================================================

func _make_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(70, 32)
	return label


func _make_input() -> LineEdit:
	var input := LineEdit.new()
	input.placeholder_text = "0"
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.custom_minimum_size = Vector2(70, 32)
	return input


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
	# buang semua baris hasil lama, sisakan header (10 label pertama)
	var children := result_grid.get_children()
	for i in range(RESULT_COLUMNS.size(), children.size()):
		children[i].queue_free()

	for i in customers.size():
		var c: Dictionary = customers[i]
		result_grid.add_child(_make_label(str(c["n"])))
		result_grid.add_child(_make_label(_fmt(c["iat"])))
		result_grid.add_child(_make_label(_fmt(c["layan"])))
		result_grid.add_child(_make_label(_fmt(c["datang"])))
		result_grid.add_child(_make_label("Teller %d" % c["teller"]))
		result_grid.add_child(_make_label(_fmt(c["mulai"])))
		result_grid.add_child(_make_label(_fmt(c["selesai"])))
		result_grid.add_child(_make_label(_fmt(c["antri"])))
		result_grid.add_child(_make_label(_fmt(c["sistem"])))
		result_grid.add_child(_make_label(_fmt(c["idle"])))


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
