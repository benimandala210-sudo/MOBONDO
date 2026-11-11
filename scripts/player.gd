extends CharacterBody3D

@export var walk_speed: float = 4.0
@export var run_speed: float = 7.0
@export var jump_velocity: float = 4.5
var mobile_direction: Vector2 = Vector2.ZERO
var wants_run: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := mobile_direction
    if keyboard.length() > 0.1:
        direction = keyboard

    var speed := run_speed if wants_run or Input.is_action_pressed("sprint") else walk_speed
    var move_dir := Vector3(direction.x, 0.0, direction.y)
    if move_dir.length() > 1.0:
        move_dir = move_dir.normalized()

    velocity.x = move_dir.x * speed
    velocity.z = move_dir.z * speed

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    move_and_slide()

func set_mobile_direction(value: Vector2) -> void:
    mobile_direction = value

func set_running(value: bool) -> void:
    wants_run = value
