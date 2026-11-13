extends CharacterBody3D
## Véhicules jouables : conduite arcade moto et voiture adaptée aux commandes tactiles.
signal vehicle_state_changed(speed_kmh: int, fuel: float)

@export var acceleration := 8.0
@export var max_speed := 13.0
@export var reverse_speed := 4.0
@export var steering_rate := 1.9
@export var braking_rate := 13.0
@export_enum("moto", "voiture") var vehicle_type := "moto"

var control_direction := Vector2.ZERO
var accelerating := false
var braking := false
var occupied := false
var fuel := 100.0
var current_speed := 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
    if vehicle_type == "voiture":
        acceleration = 5.5
        max_speed = 19.0
        reverse_speed = 5.0
        steering_rate = 1.25
        braking_rate = 17.0
        _build_car()
        var car_collision := CollisionShape3D.new()
        var car_shape := BoxShape3D.new()
        car_shape.size = Vector3(2.05, 1.35, 3.65)
        car_collision.shape = car_shape
        car_collision.position.y = 0.76
        add_child(car_collision)
    else:
        _build_motorcycle()
        var collision := CollisionShape3D.new()
        var shape := CapsuleShape3D.new()
        shape.radius = 0.62
        shape.height = 1.15
        collision.shape = shape
        collision.position.y = 0.62
        add_child(collision)

func _physics_process(delta: float) -> void:
    if not occupied:
        velocity = Vector3.ZERO
        return
    if not is_on_floor():
        velocity.y -= gravity * delta
    var keyboard := Vector2(
        float(Input.is_action_pressed("move_right")) - float(Input.is_action_pressed("move_left")),
        float(Input.is_action_pressed("move_back")) - float(Input.is_action_pressed("move_forward"))
    )
    var direction := keyboard if keyboard.length() > 0.05 else control_direction
    var throttle := 0.0
    if accelerating or direction.y < -0.1:
        throttle = 1.0
    elif direction.y > 0.1:
        throttle = -0.45
    if braking:
        current_speed = move_toward(current_speed, 0.0, braking_rate * delta)
    elif fuel > 0.0 and absf(throttle) > 0.0:
        var limit := max_speed if throttle > 0.0 else reverse_speed
        current_speed = move_toward(current_speed, limit * throttle, acceleration * delta)
        fuel = maxf(0.0, fuel - delta * (0.11 + absf(current_speed) * 0.012))
    else:
        current_speed = move_toward(current_speed, 0.0, acceleration * 0.55 * delta)
    var steer := direction.x
    var speed_factor := clampf(absf(current_speed) / max_speed, 0.18, 1.0)
    if absf(current_speed) > 0.15:
        rotation.y -= steer * steering_rate * speed_factor * delta * signf(current_speed)
    var forward := -global_basis.z
    velocity.x = forward.x * current_speed
    velocity.z = forward.z * current_speed
    move_and_slide()
    vehicle_state_changed.emit(roundi(absf(current_speed) * 3.6), fuel)

func set_control_direction(value: Vector2) -> void:
    control_direction = value.limit_length(1.0)

func set_accelerating(value: bool) -> void:
    accelerating = value

func set_braking(value: bool) -> void:
    braking = value

func mount() -> void:
    occupied = true
    current_speed = 0.0
    set_physics_process(true)

func dismount() -> void:
    occupied = false
    current_speed = 0.0
    velocity = Vector3.ZERO
    set_physics_process(false)

func refuel(amount: float = 50.0) -> void:
    fuel = minf(100.0, fuel + amount)
    vehicle_state_changed.emit(roundi(absf(current_speed) * 3.6), fuel)

func get_fuel() -> float:
    return fuel

func _build_car() -> void:
    var yellow := _mat(Color(0.86, 0.62, 0.08))
    var dark := _mat(Color(0.12, 0.15, 0.17))
    var glass := _mat(Color(0.12, 0.2, 0.24))
    var rubber := _mat(Color(0.025, 0.025, 0.028))
    var light := _mat(Color(0.95, 0.86, 0.62), true)
    _add_box("Carrosserie", Vector3(0, 0.72, 0), Vector3(2.05, 0.72, 3.65), yellow)
    _add_box("Habitacle", Vector3(0, 1.34, -0.12), Vector3(1.68, 0.72, 1.9), glass)
    _add_box("Capot", Vector3(0, 1.02, -1.28), Vector3(1.92, 0.12, 0.9), yellow)
    _add_box("Coffre", Vector3(0, 1.02, 1.38), Vector3(1.92, 0.12, 0.72), yellow)
    _add_box("Pare-chocs avant", Vector3(0, 0.48, -1.88), Vector3(2.0, 0.18, 0.12), dark)
    _add_box("Pare-chocs arrière", Vector3(0, 0.48, 1.88), Vector3(2.0, 0.18, 0.12), dark)
    _add_box("Calandre", Vector3(0, 0.78, -1.86), Vector3(0.72, 0.22, 0.06), dark)
    for x in [-0.72, 0.72]:
        _add_box("Phare", Vector3(x, 0.9, -1.86), Vector3(0.34, 0.2, 0.07), light)
        _add_box("Feu arrière", Vector3(x, 0.88, 1.86), Vector3(0.28, 0.2, 0.07), _mat(Color(0.72, 0.045, 0.025), true))
        for z in [-1.22, 1.22]:
            var wheel := MeshInstance3D.new()
            var wheel_mesh := CylinderMesh.new()
            wheel_mesh.top_radius = 0.39
            wheel_mesh.bottom_radius = 0.39
            wheel_mesh.height = 0.22
            wheel.mesh = wheel_mesh
            wheel.position = Vector3(x * 1.18, 0.39, z)
            wheel.rotation.z = PI / 2.0
            wheel.material_override = rubber
            add_child(wheel)
            var hub := MeshInstance3D.new()
            var hub_mesh := CylinderMesh.new()
            hub_mesh.top_radius = 0.17
            hub_mesh.bottom_radius = 0.17
            hub_mesh.height = 0.23
            hub.mesh = hub_mesh
            hub.position = Vector3(x * 1.18, 0.39, z)
            hub.rotation.z = PI / 2.0
            hub.material_override = _mat(Color(0.48, 0.49, 0.5))
            add_child(hub)

func _build_motorcycle() -> void:
    var dark := _mat(Color(0.055, 0.065, 0.07))
    var red := _mat(Color(0.68, 0.055, 0.035))
    var metal := _mat(Color(0.42, 0.45, 0.46))
    var rubber := _mat(Color(0.025, 0.025, 0.028))
    _add_box("Cadre", Vector3(0, 0.68, 0), Vector3(0.28, 0.18, 1.2), metal)
    _add_box("Réservoir", Vector3(0, 0.98, -0.12), Vector3(0.48, 0.42, 0.55), red)
    _add_box("Selle", Vector3(0, 1.02, 0.42), Vector3(0.42, 0.16, 0.58), dark)
    _add_box("Garde-boue avant", Vector3(0, 0.72, -0.82), Vector3(0.42, 0.08, 0.42), red)
    _add_box("Guidon", Vector3(0, 1.25, -0.68), Vector3(0.95, 0.08, 0.08), metal)
    _add_box("Phare", Vector3(0, 1.12, -0.78), Vector3(0.28, 0.25, 0.12), _mat(Color(0.95, 0.82, 0.48), true))
    for z in [-0.78, 0.78]:
        var wheel := MeshInstance3D.new()
        var wheel_mesh := TorusMesh.new()
        wheel_mesh.inner_radius = 0.27
        wheel_mesh.outer_radius = 0.36
        wheel_mesh.rings = 12
        wheel_mesh.ring_segments = 16
        wheel.mesh = wheel_mesh
        wheel.position = Vector3(0, 0.38, z)
        wheel.rotation.y = PI / 2.0
        wheel.material_override = rubber
        add_child(wheel)
        var hub := MeshInstance3D.new()
        var hub_mesh := CylinderMesh.new()
        hub_mesh.top_radius = 0.13
        hub_mesh.bottom_radius = 0.13
        hub_mesh.height = 0.13
        hub.mesh = hub_mesh
        hub.position = Vector3(0, 0.38, z)
        hub.rotation.z = PI / 2.0
        hub.material_override = metal
        add_child(hub)
    _add_box("Fourche avant", Vector3(0, 0.72, -0.65), Vector3(0.1, 0.62, 0.1), metal)
    _add_box("Pot échappement", Vector3(0.25, 0.56, 0.36), Vector3(0.12, 0.13, 0.72), metal)

func _add_box(label: String, position_value: Vector3, size_value: Vector3, material: Material) -> void:
    var mesh_node := MeshInstance3D.new()
    mesh_node.name = label
    var mesh := BoxMesh.new()
    mesh.size = size_value
    mesh_node.mesh = mesh
    mesh_node.position = position_value
    mesh_node.material_override = material
    add_child(mesh_node)

func _mat(color: Color, emission: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    if emission:
        material.emission_enabled = true
        material.emission = color
    return material
