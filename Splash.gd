extends Control

# ── Splash.gd ──────────────────────────────────────────────────────────────────
# Fast, energetic boot splash (~1.2 s total, all GPU: Tween + shader + particles):
#   0.00 s  logo punches in: scale 0.55 → 1.0 with TRANS_BACK overshoot (0.45 s)
#   0.45 s  impact moment: radial flash pops + particle burst fires
#   0.95 s  whole screen quick-fades out (0.25 s)
#   1.20 s  hard switch to Main.tscn (menu fades itself in)
# Tap anywhere to skip instantly.
# Logo uses TextureRect Keep-Aspect-Centered inside a padded full-rect, so the
# full logo (including text) is always visible at any device aspect ratio.

# ── Tunable timing values ──────────────────────────────────────────────────────
const PUNCH_IN_TIME := 0.45      # logo scale-up with overshoot bounce
const PUNCH_IN_ALPHA_TIME := 0.12  # quick alpha-in, runs parallel with the punch
const HOLD_TIME := 0.50          # pause so the impact burst reads clearly
const FADE_OUT_TIME := 0.25      # full-screen fade into the menu
const FLASH_TIME := 0.30         # radial flash expand + fade (starts at impact)
const LOGO_START_SCALE := Vector2(0.55, 0.55)
const FLASH_START_SCALE := Vector2(0.35, 0.35)
const FLASH_END_SCALE := Vector2(1.6, 1.6)
const NEXT_SCENE := "res://Main.tscn"

@onready var logo: TextureRect = $Logo
@onready var flash: TextureRect = $ImpactFlash
@onready var burst: GPUParticles2D = $ImpactBurst

var _finished := false

func _ready() -> void:
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()
	_play_intro()

func _update_layout() -> void:
	burst.position = get_viewport_rect().size * 0.5
	logo.pivot_offset = logo.size * 0.5
	flash.pivot_offset = flash.size * 0.5

func _play_intro() -> void:
	logo.scale = LOGO_START_SCALE
	logo.modulate.a = 0.0
	flash.modulate.a = 0.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(logo, "modulate:a", 1.0, PUNCH_IN_ALPHA_TIME)
	tw.tween_property(logo, "scale", Vector2.ONE, PUNCH_IN_TIME) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(_impact)
	tw.chain().tween_interval(HOLD_TIME)
	tw.chain().tween_property(self, "modulate:a", 0.0, FADE_OUT_TIME) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(_finish)

func _impact() -> void:
	# Radial flash: expand + fade, timed to the exact landing frame
	flash.scale = FLASH_START_SCALE
	flash.modulate.a = 0.9
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "scale", FLASH_END_SCALE, FLASH_TIME) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(flash, "modulate:a", 0.0, FLASH_TIME) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)

	# One-shot GPU particle burst
	burst.restart()
	burst.emitting = true

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		_finish()

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		_finish()

func _finish() -> void:
	if _finished:
		return
	_finished = true
	get_tree().change_scene_to_file(NEXT_SCENE)
