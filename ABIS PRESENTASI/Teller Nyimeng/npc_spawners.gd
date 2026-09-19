extends Node2D

@export var npc_scene: PackedScene
@export var spawn_point: Marker2D
@export var entry_corner: Marker2D
@export var teller: Marker2D
@export var queue_slot: Marker2D
@export var exit_corner: Marker2D
@export var exit_point: Marker2D
@export var npc_container: Node2D
@export var fade_duration: float = 1.5

@export var interarrival_times: Array[float] = [2.0, 2.0, 2.0, 2.0, 2.0]
@export var service_times: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0]

# >>> BARU: path scene cutscene yang mau dituju
@export var cutscene_scene_path: String = "res://cutscene_hitung.tscn"
@export var seconds_after_last_customer: float = 5.0

var _queue: Array[NPCUnit] = []
var _is_serving: bool = false

# >>> BARU
var _total_customers: int = 0
var _customers_exited: int = 0
var _all_spawned: bool = false
var _cutscene_triggered: bool = false

func _ready() -> void:
	_total_customers = interarrival_times.size()  # >>> BARU
	_run_simulation()

func _run_simulation() -> void:
	for i in interarrival_times.size():
		await get_tree().create_timer(interarrival_times[i]).timeout
		await _wait_for_space()
		_spawn_npc(service_times[i])

	_all_spawned = true  # >>> BARU: semua customer sudah selesai di-spawn
	_check_all_done()    # >>> BARU: jaga-jaga kalau ternyata sudah semua keluar duluan

func _wait_for_space() -> void:
	while _is_serving and _queue.size() >= 1:
		await get_tree().create_timer(0.1).timeout

func _spawn_npc(service_time: float) -> void:
	var npc: NPCUnit = npc_scene.instantiate()
	npc.service_time = service_time
	npc_container.add_child(npc)
	npc.global_position = spawn_point.global_position

	if entry_corner:
		npc.walk_path([entry_corner.global_position, queue_slot.global_position])
	else:
		npc.move_to(queue_slot.global_position)
	await npc.reached_target

	_enqueue(npc)

func _enqueue(npc: NPCUnit) -> void:
	_queue.append(npc)
	_try_serve_next()

func _try_serve_next() -> void:
	if _is_serving or _queue.is_empty():
		return

	_is_serving = true
	var npc: NPCUnit = _queue.pop_front()

	npc.move_to(teller.global_position)
	await npc.reached_target

	await npc.start_service()

	_is_serving = false
	_try_serve_next()

	_exit_npc(npc)

func _exit_npc(npc: NPCUnit) -> void:
	if exit_corner:
		npc.walk_path([exit_corner.global_position, exit_point.global_position])
	else:
		npc.move_to(exit_point.global_position)
	await npc.reached_target
	npc.queue_free()

	# >>> BARU: hitung customer yang sudah keluar
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
