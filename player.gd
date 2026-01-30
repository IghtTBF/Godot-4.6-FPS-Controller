extends CharacterBody3D

#region Parameters
@export_group("SFX PARAMETERS")
@export var footstep_interval: float
@export var footstep_cooldown: float
@export var can_play_footstep := true

#@onready var jump_sfx := get_node(REPLACE W/ JUMP NOISE)
#@onready var walk_sfx := get_node(REPLACE W/ FOOTSTEP)

@export_group("CAMERA PARAMETERS")
@onready var cam := get_node("CamHolder/Camera3D")
@onready var cam_holder := get_node("CamHolder")
@onready var target_walk_fov := walk_fov
@export var camera_rotation := Vector2.ZERO
@export var target_sprint_fov := 100
@export var walk_fov: int
@export var fov_transition_speed := 5.0
@export var offset := Vector3(0.0, 1.5, 0.0)
@export var smoothing := 10

@export_group("MOVE PARAMETERS")
@export var mouse_sensitivity := 0.005
@export var move_speed := 0.0
@export var target_move_speed := 10.0
@export var sprint_speed := 20.0
@export var jump_strength := 500.0

@export var can_move: bool = true
@export var out_of_bounds: bool = false

@export_group("ACCELERATION PARAMETERS")
@export var acceleration := 10.0
@export var deceleration := 15.0
@export var air_accerleration := 5.0
#endregion

#region Built-in Callbacks
func _ready() -> void:
	cam.fov = target_walk_fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if not can_move:
		return
	
	if event is InputEventMouseMotion:
		var mouse_delta = event.relative
		
		camera_rotation.y -= mouse_delta.x * mouse_sensitivity
		camera_rotation.x -= mouse_delta.y * mouse_sensitivity
		
		camera_rotation.x = clamp(camera_rotation.x, -PI/2, PI/2)
		
		rotation.y = camera_rotation.y
		cam_holder.rotation.x = camera_rotation.x

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if can_move:
		if Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	var target_pos = global_transform.origin + offset
	cam_holder.global_transform.origin = cam_holder.global_transform.origin.lerp(target_pos, smoothing * delta)
	cam_holder.rotation.y = rotation.y

func _physics_process(delta: float) -> void:
	if can_move:
		var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var is_trying_to_move := input_dir.length() > 0
		
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		var target_velocity = direction * move_speed
		
		var accel_rate = acceleration
		if not is_on_floor():
			accel_rate = deceleration
			velocity.y -= 20 * delta
		
		velocity.x = lerp(velocity.x, target_velocity.x, accel_rate * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, accel_rate * delta)
		
		var max_speed = target_move_speed
		var max_fov = target_walk_fov
		
		if Input.is_action_pressed("ui_select") and is_on_floor():
			velocity.y = jump_strength * delta
			#jump_sfx.pitch_scale = randf_range(0.8,1.1)
			#jump_sfx.play()
		
		if Input.is_action_pressed("sprint"):
			move_speed = lerpf(move_speed, sprint_speed, 10.0 * delta)
			max_speed = sprint_speed
			max_fov = target_sprint_fov
			footstep_interval = 0.2
			#walk_sfx.pitch_scale = randf_range(1,1.5)
		else: 
			move_speed = lerpf(move_speed, target_move_speed, 15.0 * delta)
			max_speed = target_move_speed
			max_fov = target_walk_fov
			footstep_interval = 0.35
			#walk_sfx.pitch_scale = randf_range(0.8,1.2)
		
		var horizontal_velocity = Vector2(velocity.x, velocity.z).length()
		
		var velocity_ratio = clamp(horizontal_velocity / max_speed, 0.0, 1.0)
		var target_fov = lerp(walk_fov, max_fov, velocity_ratio)
		
		cam.fov = lerpf(cam.fov, target_fov, fov_transition_speed * delta)
		
		if is_trying_to_move and horizontal_velocity > 0.1 and is_on_floor():
			if footstep_cooldown <= 0.0:
				#walk_sfx.play()
				footstep_cooldown = footstep_interval
		else:
			footstep_cooldown = 0.0
		if footstep_cooldown > 0.0:
			footstep_cooldown -= delta
		
	move_and_slide()
#endregion

#region Custom Functions
func death_fov() -> void:
	if not can_move and out_of_bounds:
		velocity.y = 0
		
		var tween = get_tree().create_tween()
		tween.set_trans(tween.TRANS_QUINT)
		tween.tween_property(cam, "fov", 30, 1)
#endregion
