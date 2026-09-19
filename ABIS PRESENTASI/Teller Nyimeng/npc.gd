extends Node2D
class_name NPCUnit

## ==========================================================
## npc_unit.gd
## Script dasar untuk semua NPC pelanggan: kinger, pomni, jax,
## ragatha, zooble, gangle. Menangani pergerakan (tween) dan
## pemilihan animasi otomatis.
##
## Pasang script ini di root scene tiap NPC (kinger.tscn, jax.tscn, dst)
## lalu isi "npc_id" dan drag AnimatedSprite2D-nya ke "animated_sprite"
## di Inspector.
## ==========================================================

signal reached_target

@export var npc_id: String = ""              # "kinger" | "pomni" | "jax" | "ragatha" | "zooble" | "gangle"
@export var move_speed: float = 120.0          # px/detik
@export var animated_sprite: AnimatedSprite2D  # drag & drop AnimatedSprite2D milik NPC ini

# --- nama animasi (samakan persis dengan nama animasi di SpriteFrames tiap NPC) ---
const ANIM_IDLE      := "idle"               # nunggu di antrian
const ANIM_WALK_BACK := "jalan_ke_belakang"  # jalan menuju teller
const ANIM_WALK_LEFT := "jalan_ke_kiri"      # jalan keluar setelah dilayani
const ANIM_SERVED    := "dilayani"           # sedang dilayani
const ANIM_SMILE     := "senyum"             # khusus jax
const ANIM_ANGRY     := "marah"              # khusus pomni

var service_time: float = 1.0
var is_being_served: bool = false

func _ready() -> void:
	if animated_sprite == null:
		animated_sprite = _find_animated_sprite()
	play_anim(ANIM_IDLE)

func _find_animated_sprite() -> AnimatedSprite2D:
	for child in get_children():
		if child is AnimatedSprite2D:
			return child
	return null

## Mainkan animasi kalau memang ada di SpriteFrames NPC ini.
## Kalau tidak ada (mis. NPC selain jax/pomni dipanggil ANIM_SMILE),
## fungsi ini diam saja supaya tidak error.
func play_anim(anim_name: String) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)

## Idle biasa, atau animasi emosi khusus (senyum/marah) kalau memang sedang tidak dilayani
func play_idle_or_emotion(emotion_anim: String = "") -> void:
	if is_being_served:
		return
	if emotion_anim != "":
		play_anim(emotion_anim)
	else:
		play_anim(ANIM_IDLE)

## Jalan lurus ke satu titik tujuan
func move_to(target_pos: Vector2, walk_anim: String = ANIM_WALK_BACK) -> void:
	await _tween_to(target_pos, walk_anim)
	reached_target.emit()

## Jalan lewat beberapa titik berurutan (mis. belok dulu di corner sebelum sampai tujuan akhir)
func walk_path(points: Array, walk_anim: String = ANIM_WALK_BACK) -> void:
	for p in points:
		await _tween_to(p, walk_anim)
	reached_target.emit()

func _tween_to(target_pos: Vector2, walk_anim: String) -> void:
	var distance: float = global_position.distance_to(target_pos)
	if distance <= 0.5:
		return
	play_anim(walk_anim)
	var duration: float = distance / move_speed
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, duration)
	await tween.finished

## Dipanggil spawner saat NPC ini sampai di titik layanan ("exit point").
## Menunggu selama service_time detik sambil main animasi "dilayani".
func start_service() -> void:
	is_being_served = true
	play_anim(ANIM_SERVED)
	await get_tree().create_timer(service_time).timeout
	is_being_served = false
