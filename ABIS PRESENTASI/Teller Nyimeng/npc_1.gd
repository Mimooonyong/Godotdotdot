extends Node2D
class_name NPCUnit1

## ==========================================================
## npc_unit_1.gd
##
## Script dasar untuk semua NPC pelanggan:
## kinger, pomni, jax, ragatha, zooble, gangle.
##
## Menangani:
## - pergerakan (tween)
## - pemilihan animasi otomatis
##
## Pasang script ini di root scene tiap NPC:
## kinger.tscn
## pomni.tscn
## jax.tscn
## ragatha.tscn
## zooble.tscn
## gangle.tscn
##
## lalu isi "npc_id" dan drag AnimatedSprite2D
## ke "animated_sprite" di Inspector.
## ==========================================================


signal reached_target


@export var npc_id: String = ""

@export var move_speed: float = 120.0

@export var animated_sprite: AnimatedSprite2D


# ==========================================================
# NAMA ANIMASI
# ==========================================================

const ANIM_IDLE := "idle"

const ANIM_WALK_BACK := "jalan_ke_belakang"

const ANIM_WALK_LEFT := "jalan_ke_kiri"

const ANIM_SERVED := "dilayani"

const ANIM_SMILE := "senyum"

const ANIM_ANGRY := "marah"


# ==========================================================
# STATUS
# ==========================================================

var service_time: float = 1.0

var is_being_served: bool = false


func _ready() -> void:

	if animated_sprite == null:
		animated_sprite = _find_animated_sprite()

	play_anim(ANIM_IDLE)


# ==========================================================
# CARI ANIMATED SPRITE
# ==========================================================

func _find_animated_sprite() -> AnimatedSprite2D:

	for child in get_children():

		if child is AnimatedSprite2D:
			return child

	return null


# ==========================================================
# MAIN ANIMASI
# ==========================================================

func play_anim(anim_name: String) -> void:

	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return

	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return

	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)


# ==========================================================
# IDLE BIASA / EMOSI
# ==========================================================

func play_idle_or_emotion(emotion_anim: String = "") -> void:

	if is_being_served:
		return

	if emotion_anim != "":

		play_anim(emotion_anim)

	else:

		play_anim(ANIM_IDLE)


# ==========================================================
# JALAN KE SATU TITIK
# ==========================================================

func move_to(
	target_pos: Vector2,
	walk_anim: String = ANIM_WALK_BACK
) -> void:

	await _tween_to(
		target_pos,
		walk_anim
	)

	reached_target.emit()


# ==========================================================
# JALAN LEWAT BEBERAPA TITIK
# ==========================================================

func walk_path(
	points: Array,
	walk_anim: String = ANIM_WALK_BACK
) -> void:

	for p in points:

		await _tween_to(
			p,
			walk_anim
		)

	reached_target.emit()


# ==========================================================
# TWEEN PERGERAKAN
# ==========================================================

func _tween_to(
	target_pos: Vector2,
	walk_anim: String
) -> void:

	var distance: float = global_position.distance_to(target_pos)

	if distance <= 0.5:
		return

	play_anim(walk_anim)

	var duration: float = distance / move_speed

	var tween: Tween = create_tween()

	tween.tween_property(
		self,
		"global_position",
		target_pos,
		duration
	)

	await tween.finished


# ==========================================================
# MULAI DILAYANI
# ==========================================================

func start_service() -> void:

	is_being_served = true

	play_anim(ANIM_SERVED)

	await get_tree().create_timer(
		service_time
	).timeout

	is_being_served = false
