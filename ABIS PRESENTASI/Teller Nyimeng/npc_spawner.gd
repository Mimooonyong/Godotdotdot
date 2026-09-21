extends Node2D
class_name NPCSpawner


## ==========================================================
## npc_spawner.gd
##
## Mengatur:
## - spawn NPC
## - Teller 1
## - Teller 2
## - antrean Teller 1
## - antrean Teller 2
## - pelayanan NPC
## - NPC keluar
##
## Urutan NPC:
## kinger → pomni → jax → ragatha → zooble → gangle
##
## PERBAIKAN (dibanding versi sebelumnya):
## 1. Kalau autoload SimState2 ada isinya (dikirim dari scene
##    kalkulator "1 antrian 2 teller"), interarrival_times &
##    service_times otomatis dipakai dari situ, bukan angka
##    hardcode di bawah. Kalau SimState2 kosong/gak ada,
##    fallback ke angka default (biar scene ini tetap bisa
##    dites sendiri tanpa lewat kalkulator).
## 2. teller1 / teller2 dicek dengan get_node_or_null +
##    push_error yang jelas, gak langsung crash tanpa pesan.
## 3. Jumlah slot antrian yang dipakai dibatasi ke jumlah
##    Marker2D yang beneran kamu isi di Inspector (gak lagi
##    ngotot ke MAX_QUEUE=3 kalau slotnya cuma diisi 1-2),
##    dan kalau tetap kehabisan slot, NPC langsung di-despawn
##    dengan peringatan alih-alih nyangkut selamanya.
## ==========================================================


# ==========================================================
# NPC SCENE
# ==========================================================

@export var npc_scenes: Array[PackedScene] = []

@export var npc_ids: Array[String] = [
	"kinger",
	"pomni",
	"jax",
	"ragatha",
	"zooble",
	"gangle"
]


# ==========================================================
# WAKTU KEDATANGAN & PELAYANAN (fallback)
# Dipakai HANYA kalau SimState2 belum ada datanya.
# ==========================================================

@export var interarrival_times: Array[float] = [
	3.0,
	4.0,
	3.5,
	4.0,
	3.5,
	4.0
]

@export var service_times: Array[float] = [
	2.5,
	3.0,
	2.5,
	3.0,
	2.5,
	3.0
]


# ==========================================================
# TELLER
# ==========================================================

@onready var teller1 = _require_sibling_node("Teller")
@onready var teller2 = _require_sibling_node("Teller2")


func _require_sibling_node(node_name: String) -> Node:
	var found: Node = get_parent().get_node_or_null(node_name)
	if found == null:
		push_error(
			"NPCSpawner: node '%s' tidak ditemukan sebagai sibling. "
			% node_name
			+ "Cek nama node di scene tree (harus sama persis, termasuk huruf besar/kecil)."
		)
	return found


# ==========================================================
# SPAWN UTAMA
# SATU SPAWN UNTUK SEMUA NPC
# ==========================================================

@export var spawn_point: Marker2D


# ==========================================================
# NPC CONTAINER
# TEMPAT NPC HASIL SPAWN
# ==========================================================

@export var npc_container: Node2D


# ==========================================================
# TELLER 1
# ==========================================================

@export var teller1_queue_slots: Array[Marker2D] = []

@export var teller1_service_point: Marker2D

@export var teller1_despawn_point: Marker2D


# ==========================================================
# TELLER 2
# ==========================================================

@export var teller2_queue_slots: Array[Marker2D] = []

@export var teller2_service_point: Marker2D

@export var teller2_despawn_point: Marker2D


# ==========================================================
# MAKSIMAL ANTRIAN
# Batas "keinginan" — batas beneran dihitung dari jumlah slot
# Marker2D yang kamu isi di Inspector (lihat _max_queue_*()).
# ==========================================================

const MAX_QUEUE: int = 3


func _max_queue1() -> int:
	return min(MAX_QUEUE, teller1_queue_slots.size())


func _max_queue2() -> int:
	return min(MAX_QUEUE, teller2_queue_slots.size())


# ==========================================================
# DATA ANTRIAN
# ==========================================================

var queue1: Array[NPCUnit] = []

var queue2: Array[NPCUnit] = []


# ==========================================================
# STATUS TELLER
# ==========================================================

var teller1_busy: bool = false

var teller2_busy: bool = false


# ==========================================================
# READY
# ==========================================================

func _ready() -> void:

	if npc_container == null:
		npc_container = get_parent()

	_load_simulation_data()

	_run_simulation()


# ==========================================================
# AMBIL DATA DARI SimState2 (KALAU ADA)
# Format tiap item: { n, iat, layan, datang, teller, mulai,
#                      selesai, antri, sistem, idle }
# ==========================================================

func _load_simulation_data() -> void:

	if not has_node("/root/SimState2"):
		return

	var sim_state = get_node("/root/SimState2")

	if not ("simulation_data" in sim_state):
		return

	var data: Array = sim_state.simulation_data

	if data.is_empty():
		return

	var new_iat: Array[float] = []
	var new_layan: Array[float] = []

	for c in data:
		new_iat.append(float(c.get("iat", 3.0)))
		new_layan.append(float(c.get("layan", 2.0)))

	interarrival_times = new_iat
	service_times = new_layan


# ==========================================================
# MENJALANKAN SIMULASI
# ==========================================================

func _run_simulation() -> void:

	for i in npc_scenes.size():

		var wait_time: float = 3.0

		if i < interarrival_times.size():
			wait_time = interarrival_times[i]

		await get_tree().create_timer(wait_time).timeout

		await _wait_for_queue_space()

		var service_time: float = 2.0

		if i < service_times.size():
			service_time = service_times[i]

		var npc_id: String = ""

		if i < npc_ids.size():
			npc_id = npc_ids[i]

		_spawn_npc(
			npc_scenes[i],
			npc_id,
			service_time
		)


# ==========================================================
# MENUNGGU KALAU DUA ANTRIAN PENUH
# ==========================================================

func _wait_for_queue_space() -> void:

	while queue1.size() >= _max_queue1() and queue2.size() >= _max_queue2():

		await get_tree().create_timer(0.1).timeout


# ==========================================================
# SPAWN NPC
# ==========================================================

func _spawn_npc(
	scene: PackedScene,
	id: String,
	svc_time: float
) -> void:

	var npc: NPCUnit = scene.instantiate()

	npc.npc_id = id

	npc.service_time = svc_time

	npc_container.add_child(npc)

	npc.global_position = spawn_point.global_position


# ======================================================
# CEK TELLER 1
# ======================================================

	if not teller1_busy:

		_send_to_teller1(npc)

		return


# ======================================================
# CEK TELLER 2
# ======================================================

	if not teller2_busy:

		_send_to_teller2(npc)

		return


# ======================================================
# DUA TELLER SIBUK
# ======================================================

	var space1: bool = queue1.size() < _max_queue1()
	var space2: bool = queue2.size() < _max_queue2()

	if space1 and space2:

		if queue1.size() < queue2.size():

			_add_to_teller1_queue(npc)

		elif queue2.size() < queue1.size():

			_add_to_teller2_queue(npc)

		else:

			_add_to_teller1_queue(npc)

		return


# ======================================================
# KALAU TELLER 1 PENUH
# ======================================================

	if not space1 and space2:

		_add_to_teller2_queue(npc)

		return


# ======================================================
# KALAU TELLER 2 PENUH
# ======================================================

	if not space2 and space1:

		_add_to_teller1_queue(npc)

		return


# ======================================================
# DUA-DUANYA BENER-BENER PENUH
# (seharusnya jarang kejadian karena _wait_for_queue_space
# sudah nunggu duluan, tapi tetap dijaga biar gak nyangkut)
# ======================================================

	push_warning(
		"NPCSpawner: kedua antrian penuh, NPC '%s' langsung dikeluarkan." % id
	)
	npc.queue_free()


# ==========================================================
# LANGSUNG KE TELLER 1
# ==========================================================

func _send_to_teller1(npc: NPCUnit) -> void:

	teller1_busy = true

	npc.move_to(
		teller1_service_point.global_position,
		NPCUnit.ANIM_WALK_BACK
	)

	await npc.reached_target

	if teller1:
		teller1.play_idle()

	await npc.start_service()

	if teller1:
		teller1.play_done_customer()

	teller1_busy = false

	_try_serve_teller1()

	_exit_npc(
		npc,
		teller1_despawn_point
	)


# ==========================================================
# LANGSUNG KE TELLER 2
# ==========================================================

func _send_to_teller2(npc: NPCUnit) -> void:

	teller2_busy = true

	npc.move_to(
		teller2_service_point.global_position,
		NPCUnit.ANIM_WALK_BACK
	)

	await npc.reached_target

	if teller2:
		teller2.play_idle()

	await npc.start_service()

	if teller2:
		teller2.play_done_customer()

	teller2_busy = false

	_try_serve_teller2()

	_exit_npc(
		npc,
		teller2_despawn_point
	)


# ==========================================================
# MASUK ANTRIAN TELLER 1
# ==========================================================

func _add_to_teller1_queue(npc: NPCUnit) -> void:

	var index: int = queue1.size()

	if index >= teller1_queue_slots.size():
		push_warning(
			"NPCSpawner: slot antrian Teller 1 habis, NPC '%s' langsung dikeluarkan." % npc.npc_id
		)
		npc.queue_free()
		return

	queue1.append(npc)

	var slot: Marker2D = teller1_queue_slots[index]

	npc.move_to(
		slot.global_position,
		NPCUnit.ANIM_WALK_BACK
	)

	await npc.reached_target

	_update_queue_moods()


# ==========================================================
# MASUK ANTRIAN TELLER 2
# ==========================================================

func _add_to_teller2_queue(npc: NPCUnit) -> void:

	var index: int = queue2.size()

	if index >= teller2_queue_slots.size():
		push_warning(
			"NPCSpawner: slot antrian Teller 2 habis, NPC '%s' langsung dikeluarkan." % npc.npc_id
		)
		npc.queue_free()
		return

	queue2.append(npc)

	var slot: Marker2D = teller2_queue_slots[index]

	npc.move_to(
		slot.global_position,
		NPCUnit.ANIM_WALK_BACK
	)

	await npc.reached_target

	_update_queue_moods()


# ==========================================================
# TELLER 1 AMBIL ANTRIAN BERIKUTNYA
# ==========================================================

func _try_serve_teller1() -> void:

	if teller1_busy:
		return

	if queue1.is_empty():
		return

	teller1_busy = true

	var npc: NPCUnit = queue1.pop_front()

	_reposition_teller1_queue()

	npc.move_to(
		teller1_service_point.global_position,
		NPCUnit.ANIM_WALK_BACK
	)

	await npc.reached_target

	if teller1:
		teller1.play_idle()

	await npc.start_service()

	if teller1:
		teller1.play_done_customer()

	teller1_busy = false

	_try_serve_teller1()

	_exit_npc(
		npc,
		teller1_despawn_point
	)


# ==========================================================
# TELLER 2 AMBIL ANTRIAN BERIKUTNYA
# ==========================================================

func _try_serve_teller2() -> void:

	if teller2_busy:
		return

	if queue2.is_empty():
		return

	teller2_busy = true

	var npc: NPCUnit = queue2.pop_front()

	_reposition_teller2_queue()

	npc.move_to(
		teller2_service_point.global_position,
		NPCUnit.ANIM_WALK_BACK
	)

	await npc.reached_target

	if teller2:
		teller2.play_idle()

	await npc.start_service()

	if teller2:
		teller2.play_done_customer()

	teller2_busy = false

	_try_serve_teller2()

	_exit_npc(
		npc,
		teller2_despawn_point
	)


# ==========================================================
# GESER ANTRIAN TELLER 1
# ==========================================================

func _reposition_teller1_queue() -> void:

	for i in queue1.size():

		var npc: NPCUnit = queue1[i]

		var slot: Marker2D = teller1_queue_slots[i]

		npc.move_to(
			slot.global_position,
			NPCUnit.ANIM_WALK_BACK
		)

	_update_queue_moods()


# ==========================================================
# GESER ANTRIAN TELLER 2
# ==========================================================

func _reposition_teller2_queue() -> void:

	for i in queue2.size():

		var npc: NPCUnit = queue2[i]

		var slot: Marker2D = teller2_queue_slots[i]

		npc.move_to(
			slot.global_position,
			NPCUnit.ANIM_WALK_BACK
		)

	_update_queue_moods()


# ==========================================================
# NPC KELUAR
# ==========================================================

func _exit_npc(
	npc: NPCUnit,
	despawn_point: Marker2D
) -> void:

	npc.move_to(
		despawn_point.global_position,
		NPCUnit.ANIM_WALK_LEFT
	)

	await npc.reached_target

	npc.queue_free()


# ==========================================================
# EMOSI JAX & POMNI
# ==========================================================

func _update_queue_moods() -> void:

	var all_queue: Array[NPCUnit] = []

	for npc in queue1:
		all_queue.append(npc)

	for npc in queue2:
		all_queue.append(npc)


	var jax_index: int = -1

	var pomni_index: int = -1


	for i in all_queue.size():

		if all_queue[i].npc_id == "jax":

			jax_index = i

		elif all_queue[i].npc_id == "pomni":

			pomni_index = i


	var adjacent: bool = (
		jax_index != -1
		and pomni_index != -1
		and abs(jax_index - pomni_index) == 1
	)


	for npc in all_queue:

		if npc.npc_id == "jax" and adjacent:

			npc.play_idle_or_emotion(
				NPCUnit.ANIM_SMILE
			)

		elif npc.npc_id == "pomni" and adjacent:

			npc.play_idle_or_emotion(
				NPCUnit.ANIM_ANGRY
			)

		else:

			npc.play_idle_or_emotion()
