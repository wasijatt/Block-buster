extends Control

# ── Splash.gd ──────────────────────────────────────────────────────────────────
# Project boot splash screen.
# Displays the game logo over AnimatedBackground with smooth fade in/out transitions,
# then seamlessly forwards into Main.tscn.

@onready var logo: Sprite2D = $Logo

# Tuning parameters for splash timing
const FADE_IN_TIME: float = 1.0
const HOLD_TIME: float = 1.5
const FADE_OUT_TIME: float = 0.5
const NEXT_SCENE: String = "res://Main.tscn"

func _ready() -> void:
	# Ensure logo starts invisible
	if logo:
		logo.modulate.a = 0.0
		_center_logo()

	get_viewport().size_changed.connect(_center_logo)
	_play_splash_sequence()

func _center_logo() -> void:
	if logo:
		logo.position = get_viewport_rect().size * 0.5

var _skipped: bool = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_skip_splash()

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		_skip_splash()

func _skip_splash() -> void:
	if _skipped:
		return
	_skipped = true
	get_tree().change_scene_to_file(NEXT_SCENE)

func _play_splash_sequence() -> void:
	var tw := create_tween()
	
	# 1. Fade logo in over 1.0 second
	tw.tween_property(logo, "modulate:a", 1.0, FADE_IN_TIME)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	# 2. Hold on screen for 1.5 seconds
	tw.tween_interval(HOLD_TIME)
	
	# 3. Fade out over 0.5 seconds
	tw.tween_property(logo, "modulate:a", 0.0, FADE_OUT_TIME)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	
	# 4. Transition to main game scene
	tw.tween_callback(func():
		_skip_splash()
	)

