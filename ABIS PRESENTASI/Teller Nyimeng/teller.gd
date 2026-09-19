extends Node2D
class_name Teller

## ==========================================================
## teller.gd - pasang di node "Teller"
## Cuma mengurus animasi teller sendiri (idle / done_customer).
## Semua logika antrian & spawn NPC ada di npc_spawner.gd,
## yang akan memanggil play_idle() / play_done_customer() di sini.
## ==========================================================

@export var animated_sprite: AnimatedSprite2D   # drag AnimatedSprite2 milik node Teller ke sini

const ANIM_IDLE := "idle"
const ANIM_DONE := "done_customer"

func _ready() -> void:
	if animated_sprite == null:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	play_idle()

## Dipanggil saat teller sedang melayani NPC
func play_idle() -> void:
	_play(ANIM_IDLE)

## Dipanggil saat NPC yang baru selesai dilayani sedang berjalan keluar
func play_done_customer() -> void:
	_play(ANIM_DONE)

func _play(anim_name: String) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)
