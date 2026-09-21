extends Node

# --- Data soal ---
var iat_batch1: Array[float] = []
var layan_batch1: Array[float] = []

var iat_batch2: Array[float] = []
var layan_batch2: Array[float] = []

# --- Progress player ---
var batch1_answers: Array = []
var batch2_answers: Array = []
var batch1_done: bool = false
var batch2_done: bool = false

var worksheet_scene_path: String = "res://worksheet_antrian.tscn"
var sleep_dialog_scene_path: String = "res://ketiduran.tscn"
var welcome_tadc_scene_path: String = "res://welcome_tadc.tscn"

func fade_to_black(duration: float) -> ColorRect:
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100

	var fade_rect := ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fade_layer.add_child(fade_rect)
	get_tree().root.add_child(fade_layer)

	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, duration)
	await tween.finished

	return fade_rect

func fade_from_black(fade_rect: ColorRect, duration: float) -> void:
	await get_tree().process_frame

	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, duration)
	await tween.finished

	fade_rect.get_parent().queue_free()
