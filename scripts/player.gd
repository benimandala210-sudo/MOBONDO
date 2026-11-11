extends CharacterBody3D

@export var walk_speed: float = 4.0
@export var run_speed: float = 6.5
@export var jump_velocity: float = 4.5
@export var ground_acceleration: float = 18.0
@export var ground_deceleration: float = 22.0
@export var air_acceleration: float = 5.0

var mobile_direction: Vector2 = Vector2.ZERO
var wants_run: bool = false
var jump_requested: bool = false
var movement_camera: Camera3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
    _configure_keyboard_controls()

func _configure_keyboard_controls() -> void:
    _add_key_action("move_left", [KEY_A, KEY_LEFT])
    _add_key_action("move_right", [KEY_D, KEY_RIGHT])
    _add_key_action("move_forward", [KEY_W, KEY_UP])
    _add_key_action("move_back", [KEY_S, KEY_DOWN])
    _add_key_action("sprint", [KEY_SHIFT])
    _add_key_action("jump", [KEY_SPACE])

func _add_key_action(action_name: String, keys: Array) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)
    for key in keys:
        var event := InputEventKey.new()
        event.physical_keycode = key
        var already_added := false
        for existing in InputMap.action_get_events(action_name):
            if existing is InputEventKey and existing.physical_keycode == key:
                already_added = true
                break
        if not already_added:
            InputMap.action_add_event(action_name, event)

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    var input_direction := mobile_direction
    var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if keyboard.length() > 0.1:
        input_direction = keyboard

    var move_direction := Vector3.ZERO
    if input_direction.length() > 0.05:
        if is_instance_valid(movement_camera):
            var camera_forward := -movement_camera.global_basis.z
            var camera_right := movement_camera.global_basis.x
            camera_forward.y = 0.0
            camera_right.y = 0.0
            camera_forward = camera_forward.normalized()
            camera_right = camera_right.normalized()
            move_direction = (camera_right * input_direction.x) + (camera_forward * -input_direction.y)
        else:
            move_direction = Vector3(input_direction.x, 0.0, input_direction.y)
        move_direction.y = 0.0
        move_direction = move_direction.normalized()

    var moving := move_direction.length_squared() > 0.001
    var target_speed := run_speed if wants_run or Input.is_action_pressed("sprint") else walk_speed
    var target_x := move_direction.x * target_speed if moving else 0.0
    var target_z := move_direction.z * target_speed if moving else 0.0
    var acceleration := ground_acceleration if is_on_floor() else air_acceleration
    var deceleration := ground_deceleration if is_on_floor() else air_acceleration
    velocity.x = move_toward(velocity.x, target_x, (acceleration if moving else deceleration) * delta)
    velocity.z = move_toward(velocity.z, target_z, (acceleration if moving else deceleration) * delta)

    if moving:
        rotation.y = lerp_angle(rotation.y, atan2(-move_direction.x, -move_direction.z), minf(delta * 12.0, 1.0))

    if (Input.is_action_just_pressed("jump") or jump_requested) and is_on_floor():
        velocity.y = jump_velocity
    jump_requested = false

    move_and_slide()

func set_mobile_direction(value: Vector2) -> void:
    mobile_direction = value.limit_length(1.0)

func set_running(value: bool) -> void:
    wants_run = value

func request_jump() -> void:
    jump_requested = true

func set_movement_camera(value: Camera3D) -> void:
    movement_camera = value
