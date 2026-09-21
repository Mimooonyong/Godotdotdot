extends Node2D

@export var npc_scene: PackedScene
@export var spawn_point: Marker2D

@export_group("Teller Points")
@export var teller_1: Marker2D       # Dra TellerPoint1 ke sini
@export var teller_2: Marker2D       # Dra TellerPoint2 ke sini

@export_group("Queue & Exit Points")
@export var queue_slot: Marker2D     # Dra QueueAnchor ke sini
@export var exit_point: Marker2D     # Dra ExitPoint ke sini

@export var npc_container: Node2D
@export var fade_duration: float = 1.5

@export var interarrival_times: Array[float] = [2.0, 2.0, 2.0, 2.0, 2.0]
@export var service_times: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0]

@export var cutscene_scene_path: String = "res://cutscene_hitung.tscn"
@export var seconds_after_last_customer: float = 5.0

var _queue: Array[NPCUnit] = []

var _is_teller1_busy: bool = false
var _is_teller2_busy: bool = false

var _total_customers: int = 0
var _customers_exited: int = 0
var _all_spawned: bool = false
var _cutscene_triggered: bool = false

func _ready() -> void:
	_total_customers = interarrival_times.size()
	_run_simulation()

func _run_simulation() -> void:
	for i in interarrival_times.size():
		await get_tree().create_timer(interarrival_times[i]).timeout
		await _wait_for_space()
		_spawn_npc(service_times[i])

	_all_spawned = true
	_check_all_done()

func _wait_for_space() -> void:
	while (_is_teller1_busy and _is_teller2_busy) and _queue.size() >= 1:
		await get_tree().create_timer(0.1).timeout

func _spawn_npc(service_time: float) -> void:
	var npc: NPCUnit = npc_scene.instantiate()
	npc.service_time = service_time
	npc_container.add_child(npc)
	npc.global_position = spawn_point.global_position

	# Langsung jalan ke titik antrean utama (QueueAnchor)
	npc.move_to(queue_slot.global_position)
	await npc.reached_target

	_enqueue(npc)

func _enqueue(npc: NPCUnit) -> void:
	_queue.append(npc)
	_try_serve_next()

func _try_serve_next() -> void:
	if _queue.is_empty():
		return

	# Cek mana teller yang kosong
	if not _is_teller1_busy:
		_serve_at_teller(1, teller_1)
	elif not _is_teller2_busy:
		_serve_at_teller(2, teller_2)

func _serve_at_teller(teller_num: int, target_teller: Marker2D) -> void:
	if teller_num == 1:
		_is_teller1_busy = true
	else:
		_is_teller2_busy = true

	var npc: NPCUnit = _queue.pop_front()

	npc.move_to(target_teller.global_position)
	await npc.reached_target

	await npc.start_service()

	if teller_num == 1:
		_is_teller1_busy = false
	else:
		_is_teller2_busy = false

	_try_serve_next()
	_exit_npc(npc)

func _exit_npc(npc: NPCUnit) -> void:
	# Jalan langsung ke ExitPoint tanpa butuh node corner tambahan
	npc.move_to(exit_point.global_position, NPCUnit.ANIM_WALK_LEFT)
	await npc.reached_target
	npc.queue_free()

	_customers_exited += 1
	_check_all_done()

func _check_all_done() -> void:
	if _cutscene_triggered:
		return
	if _all_spawned and _customers_exited >= _total_customers:
		_cutscene_triggered = true
		await get_tree().create_timer(seconds_after_last_customer).timeout

		var fade_rect: ColorRect = await SimState.fade_to_black(fade_duration)
		_go_to_cutscene()
		await SimState.fade_from_black(fade_rect, fade_duration)

func _go_to_cutscene() -> void:
	get_tree().change_scene_to_file(cutscene_scene_path)
