extends Node2D
class_name NPCSpawner

## ==========================================================
## npc_spawner.gd - pasang di node "NPCSpawner"
##
## Menyimulasikan kedatangan 6 NPC dengan URUTAN TETAP:
##   kinger -> pomni -> jax -> ragatha -> zooble -> gangle
##
## Aturan antrian:
##  - Yang sedang dilayani berdiri di "exit point" (service_point)
##  - Yang menunggu antri di queue / queue1 / queue2 (maksimal 3 orang)
##  - Kalau antrian sudah penuh (3 orang), NPC berikutnya BELUM
##    di-spawn sampai ada slot kosong
##  - Setelah selesai dilayani, NPC jalan ke "despawn" lalu dihapus
##
## PENTING: isi array di bawah lewat Inspector:
##   - npc_scenes  : 6 PackedScene, urutannya HARUS sama dengan npc_ids
##   - interarrival_times / service_times : ganti dengan angka dari data kamu
##   - queue_slots : isi [queue, queue1, queue2] urut dari paling depan
##
## (Fitur pindah ke cutscene setelah customer terakhir DIHAPUS dulu,
## bisa ditambah lagi nanti kalau sudah dibutuhkan)
## ==========================================================

# ---------- Scene & id tiap NPC (urutan HARUS: kinger, pomni, jax, ragatha, zooble, gangle) ----------
@export var npc_scenes: Array[PackedScene] = []
@export var npc_ids: Array[String] = ["kinger", "pomni", "jax", "ragatha", "zooble", "gangle"]

# ---------- Waktu (detik) — GANTI sesuai data di foto ke-2 kamu ----------
# interarrival_times[i] = jeda kedatangan NPC ke-i dihitung dari NPC sebelumnya
# service_times[i]      = lama NPC ke-i dilayani teller
@export var interarrival_times: Array[float] = [3.0, 4.0, 3.5, 4.0, 3.5, 4.0]
@export var service_times: Array[float] = [2.5, 3.0, 2.5, 3.0, 2.5, 3.0]

# ---------- Titik-titik (Marker2D) ----------
@export var teller: Teller                        # node "Teller" (untuk animasi idle/done_customer)
@export var spawn_point: Marker2D                  # node "spawn" -> NPC muncul di sini
@export var queue_slots: Array[Marker2D] = []       # isi: [queue, queue1, queue2] urut dari paling depan
@export var service_point: Marker2D                 # node "exit point" -> posisi NPC saat DILAYANI
@export var despawn_point: Marker2D                 # node "despawn" -> titik NPC hilang
@export var npc_container: Node2D                   # parent tempat instance NPC diletakkan

const MAX_QUEUE: int = 3

var _queue: Array[NPCUnit] = []
var _is_serving: bool = false

func _ready() -> void:
	_run_simulation()

func _run_simulation() -> void:
	for i in npc_scenes.size():
		var wait_time: float = interarrival_times[i] if i < interarrival_times.size() else 3.0
		await get_tree().create_timer(wait_time).timeout
		await _wait_for_queue_space()

		var svc_time: float = service_times[i] if i < service_times.size() else 2.0
		var id: String = npc_ids[i] if i < npc_ids.size() else ""
		_spawn_npc(npc_scenes[i], id, svc_time)

## Nunggu sampai antrian punya slot kosong (maksimal 3 yang menunggu, TIDAK termasuk yang sedang dilayani)
func _wait_for_queue_space() -> void:
	while _queue.size() >= MAX_QUEUE:
		await get_tree().create_timer(0.1).timeout

func _spawn_npc(scene: PackedScene, id: String, svc_time: float) -> void:
	var npc: NPCUnit = scene.instantiate()
	npc.npc_id = id
	npc.service_time = svc_time
	npc_container.add_child(npc)
	npc.global_position = spawn_point.global_position

	var slot_index: int = _queue.size()
	var target_slot: Marker2D = queue_slots[slot_index]

	npc.move_to(target_slot.global_position, NPCUnit.ANIM_WALK_BACK)
	await npc.reached_target

	_queue.append(npc)
	_update_queue_moods()
	_try_serve_next()

## Geser sisa antrian maju satu slot (queue1 -> queue, queue2 -> queue1, dst)
func _reposition_queue() -> void:
	for i in _queue.size():
		var npc: NPCUnit = _queue[i]
		var slot: Marker2D = queue_slots[i]
		if npc.global_position.distance_to(slot.global_position) > 0.5:
			npc.move_to(slot.global_position, NPCUnit.ANIM_WALK_BACK)
	_update_queue_moods()

func _try_serve_next() -> void:
	if _is_serving or _queue.is_empty():
		return
	_is_serving = true

	var npc: NPCUnit = _queue.pop_front()
	_reposition_queue()

	# jalan ke titik layanan ("exit point")
	npc.move_to(service_point.global_position, NPCUnit.ANIM_WALK_BACK)
	await npc.reached_target

	if teller:
		teller.play_idle()   # teller "idle" = sedang melayani
	await npc.start_service()

	_is_serving = false
	_try_serve_next()   # biar NPC antrian berikutnya langsung mulai, tanpa nunggu npc ini selesai jalan keluar

	_exit_npc(npc)

func _exit_npc(npc: NPCUnit) -> void:
	if teller:
		teller.play_done_customer()   # animasi teller saat customer jalan keluar

	npc.move_to(despawn_point.global_position, NPCUnit.ANIM_WALK_LEFT)
	await npc.reached_target
	npc.queue_free()

	# kalau tidak ada yang sedang dilayani lagi setelah ini, balik ke idle
	if teller and not _is_serving:
		teller.play_idle()

## Jax & Pomni: kalau posisi mereka bersebelahan di antrian (dan tidak sedang dilayani)
## -> jax main animasi senyum, pomni main animasi marah.
## Kalau tidak bersebelahan (atau salah satu lagi dilayani) -> idle biasa.
func _update_queue_moods() -> void:
	var jax_index: int = -1
	var pomni_index: int = -1
	for i in _queue.size():
		if _queue[i].npc_id == "jax":
			jax_index = i
		elif _queue[i].npc_id == "pomni":
			pomni_index = i

	var adjacent: bool = jax_index != -1 and pomni_index != -1 and abs(jax_index - pomni_index) == 1

	for i in _queue.size():
		var npc: NPCUnit = _queue[i]
		if npc.npc_id == "jax" and adjacent:
			npc.play_idle_or_emotion(NPCUnit.ANIM_SMILE)
		elif npc.npc_id == "pomni" and adjacent:
			npc.play_idle_or_emotion(NPCUnit.ANIM_ANGRY)
		else:
			npc.play_idle_or_emotion()
			
