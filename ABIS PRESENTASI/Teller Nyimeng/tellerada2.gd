extends Node2D
class_name Teller2

@export var animated_sprite: AnimatedSprite2D

const ANIM_IDLE := "idle"
const ANIM_DONE := "done_customer"

var sedang_melayani: bool = false


func _ready() -> void:

	if animated_sprite == null:
		animated_sprite = get_node_or_null("AnimatedSprite2D")

	play_idle()


func mulai_melayani() -> void:

	sedang_melayani = true

	play_idle()


func selesai_melayani() -> void:

	sedang_melayani = false

	play_done_customer()


func play_idle() -> void:

	_play(ANIM_IDLE)


func play_done_customer() -> void:

	_play(ANIM_DONE)


func _play(anim_name: String) -> void:

	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames == null:
		return

	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return

	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():

		animated_sprite.play(anim_name)
