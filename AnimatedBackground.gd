extends Control

# ── AnimatedBackground.gd ──────────────────────────────────────────────────────
# Lightweight GPU-based animated background for low-end mobile performance.
# Combines:
# 1. Static TextureRect (res://assets/bg_funky.png) with Keep Aspect Covered
# 2. Ambient GPUParticles2D drifting slowly upward with random rotation
# 3. Additive pulsing ColorRect with ambient_glow.gdshader

@onready var texture_rect: TextureRect = $TextureRect
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var glow_overlay: ColorRect = $GlowOverlay

func _ready() -> void:
	# Ensure the background always renders strictly behind gameplay grids and UI
	z_index = -10
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Connect viewport resize signal for responsive mobile full-screen coverage
	if get_viewport():
		get_viewport().size_changed.connect(_update_layout)
	_update_layout()

# Updates background bounds & particle emission extents dynamically
func _update_layout() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	size = vp_size

	if particles:
		# Center particles emitter and span emission box across screen with generous bounds
		particles.position = vp_size * 0.5
		var pmat := particles.process_material as ParticleProcessMaterial
		if pmat:
			pmat.emission_box_extents = Vector3(vp_size.x * 0.55, vp_size.y * 0.55, 1.0)
