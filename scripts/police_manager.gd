extends Node3D
## Patrouilles de la Police nationale congolaise — premier secteur Mapela–Raïs.
## Modèles provisoires stylisés : uniforme bleu nuit, béret sombre, ceinturon et bottines noires.

signal police_message(message: String)

const UNIFORM_BLUE := Color(0.035, 0.075, 0.16)
const TROUSER_BLUE := Color(0.025, 0.045, 0.105)
const BOOT_BLACK := Color(0.018, 0.02, 0.025)
const SKIN_BROWN := Color(0.29, 0.16, 0.105)
const BELT_BLACK := Color(0.025, 0.028, 0.032)

var player: CharacterBody3D
var vehicle_target: Node3D
var reputation_manager: Node
var arrest_callback: Callable
var officers: Array[Node3D] = []
var routes: Array[Array] = []
var patrol_indices: Array[int] = []
var active := false
var player_in_vehicle := false
var vehicle_speed_kmh := 0.0
var message_cooldown := 0.0
var arrest_in_progress := false
var patrol_motorcycle: Node3D
var motorcycle_route: Array[Vector3] = [Vector3(0.0, 0.0, -8.0), Vector3(0.0, 0.0, -36.0), Vector3(0.0, 0.0, -56.0), Vector3(0.0, 0.0, -36.0)]
var motorcycle_route_index := 1
var motorcycle_state := "patrol"
var motorcycle_search_timer := 0.0

func configure(player_ref: CharacterBody3D, reputation_ref: Node, arrest_action: Callable, vehicle_ref: Node3D = null) -> void:
    player = player_ref
    reputation_manager = reputation_ref
    arrest_callback = arrest_action
    vehicle_target = vehicle_ref
    _create_patrol_officers()
    _create_motorized_patrol()

func set_vehicle_target(vehicle_ref: Node3D) -> void:
    vehicle_target = vehicle_ref

func set_active(value: bool) -> void:
    if value and not active:
        arrest_in_progress = false
    active = value
    if not active:
        for officer in officers:
            if is_instance_valid(officer) and str(officer.get_meta("state", "patrol")) == "pursuit":
                officer.set_meta("state", "patrol")
                officer.set_meta("search_timer", 0.0)
        motorcycle_state = "patrol"
        motorcycle_search_timer = 0.0

func set_player_vehicle_state(occupied: bool, speed_kmh: float = 0.0) -> void:
    player_in_vehicle = occupied
    vehicle_speed_kmh = absf(speed_kmh)

func _process(delta: float) -> void:
    if not active or not is_instance_valid(player) or (not player.visible and not player_in_vehicle) or not is_instance_valid(reputation_manager):
        return
    if message_cooldown > 0.0:
        message_cooldown = maxf(0.0, message_cooldown - delta)
    var wanted := int(reputation_manager.wanted_level)
    for i in range(officers.size()):
        var officer := officers[i]
        if not is_instance_valid(officer):
            continue
        var state := str(officer.get_meta("state", "patrol"))
        var target_position := vehicle_target.global_position if player_in_vehicle and is_instance_valid(vehicle_target) else player.global_position
        var distance := Vector2(officer.global_position.x - target_position.x, officer.global_position.z - target_position.z).length()
        if wanted <= 0:
            if state == "pursuit":
                officer.set_meta("state", "patrol")
                _announce("La patrouille reprend sa ronde.")
            _patrol_officer(i, delta)
            continue
        if state != "pursuit":
            var detection_radius := 8.0 + float(wanted) * 3.2
            if distance <= detection_radius:
                officer.set_meta("state", "pursuit")
                officer.set_meta("search_timer", 0.0)
                _announce("PNC : un agent t'a repéré. La patrouille se rapproche.")
                state = "pursuit"
        if state == "pursuit":
            if distance > 38.0 + float(wanted) * 3.0:
                var lost_time := float(officer.get_meta("search_timer", 0.0)) + delta
                officer.set_meta("search_timer", lost_time)
                if lost_time >= 12.0:
                    officer.set_meta("state", "patrol")
                    officer.set_meta("search_timer", 0.0)
                    _announce("La police a perdu ta trace. Reste prudent.")
                    continue
            else:
                officer.set_meta("search_timer", 0.0)
            _pursue_player(officer, delta, wanted)
            var arrest_distance := 2.0 if player_in_vehicle else 1.55
            if distance <= arrest_distance and (not player_in_vehicle or vehicle_speed_kmh <= 3.0):
                if not arrest_in_progress:
                    arrest_in_progress = true
                    _announce("PNC : interpellation. Tu es conduit au poste.")
                    if arrest_callback.is_valid():
                        arrest_callback.call()
                    set_active(false)
                    return
    _update_motorized_patrol(delta, wanted)

func _create_motorized_patrol() -> void:
    if is_instance_valid(patrol_motorcycle):
        return
    patrol_motorcycle = _build_patrol_motorcycle()
    patrol_motorcycle.position = motorcycle_route[0]
    patrol_motorcycle.set_meta("state", "patrol")
    add_child(patrol_motorcycle)

func _update_motorized_patrol(delta: float, wanted: int) -> void:
    if not is_instance_valid(patrol_motorcycle):
        return
    var target_position := vehicle_target.global_position if player_in_vehicle and is_instance_valid(vehicle_target) else player.global_position
    var distance := Vector2(patrol_motorcycle.global_position.x - target_position.x, patrol_motorcycle.global_position.z - target_position.z).length()
    if wanted > 0 and distance <= 14.0 + float(wanted) * 3.0:
        if motorcycle_state != "pursuit":
            motorcycle_state = "pursuit"
            motorcycle_search_timer = 0.0
            _announce("PNC : une patrouille motorisée rejoint l'intervention.")
        if distance > 45.0:
            motorcycle_search_timer += delta
            if motorcycle_search_timer > 14.0:
                motorcycle_state = "patrol"
                motorcycle_search_timer = 0.0
                _announce("La patrouille motorisée a perdu ta trace.")
        else:
            motorcycle_search_timer = 0.0
        if motorcycle_state == "pursuit":
            var chase_target := target_position
            chase_target.y = 0.0
            patrol_motorcycle.position = patrol_motorcycle.position.move_toward(chase_target, (5.0 + float(wanted) * 0.75) * delta)
            _face_target(patrol_motorcycle, chase_target)
            if distance <= 2.3 and (not player_in_vehicle or vehicle_speed_kmh <= 3.0):
                if not arrest_in_progress:
                    arrest_in_progress = true
                    _announce("PNC : la patrouille motorisée procède à l'interpellation.")
                    if arrest_callback.is_valid():
                        arrest_callback.call()
                    set_active(false)
                    return
    if motorcycle_state == "patrol":
        var route_target: Vector3 = motorcycle_route[motorcycle_route_index]
        patrol_motorcycle.position = patrol_motorcycle.position.move_toward(route_target, 4.0 * delta)
        _face_target(patrol_motorcycle, route_target)
        if patrol_motorcycle.position.distance_to(route_target) < 0.5:
            motorcycle_route_index = (motorcycle_route_index + 1) % motorcycle_route.size()

func _build_patrol_motorcycle() -> Node3D:
    var root := Node3D.new()
    root.name = "Moto de patrouille PNC"
    _add_box(root, "Carénage bleu nuit", Vector3(0, 0.76, 0), Vector3(0.58, 0.4, 1.15), UNIFORM_BLUE)
    _add_box(root, "Réservoir PNC", Vector3(0, 1.02, -0.1), Vector3(0.48, 0.3, 0.5), TROUSER_BLUE)
    _add_box(root, "Selle moto PNC", Vector3(0, 1.0, 0.38), Vector3(0.4, 0.15, 0.55), BELT_BLACK)
    _add_box(root, "Phare moto PNC", Vector3(0, 0.95, -0.63), Vector3(0.25, 0.22, 0.12), Color(0.95, 0.86, 0.58))
    for z in [-0.62, 0.62]:
        var wheel := MeshInstance3D.new()
        var wheel_mesh := TorusMesh.new()
        wheel_mesh.inner_radius = 0.2
        wheel_mesh.outer_radius = 0.29
        wheel.mesh = wheel_mesh
        wheel.position = Vector3(0, 0.31, z)
        wheel.rotation.y = PI / 2.0
        wheel.material_override = _material(BOOT_BLACK)
        root.add_child(wheel)
    var rider := _build_officer("Motard PNC")
    rider.position = Vector3(0, 0.28, 0.05)
    rider.scale = Vector3(0.82, 0.82, 0.82)
    root.add_child(rider)
    var marking := Label3D.new()
    marking.text = "PNC"
    marking.font_size = 24
    marking.pixel_size = 0.01
    marking.position = Vector3(0, 1.42, -0.58)
    marking.modulate = Color(0.95, 0.9, 0.7)
    root.add_child(marking)
    return root

func _create_patrol_officers() -> void:
    if not officers.is_empty():
        return
    routes = [
        [Vector3(-5.0, 0.0, -4.0), Vector3(-5.0, 0.0, -18.0), Vector3(-2.5, 0.0, -30.0), Vector3(-5.0, 0.0, -18.0)],
        [Vector3(5.0, 0.0, -43.0), Vector3(5.0, 0.0, -31.0), Vector3(3.0, 0.0, -19.0), Vector3(5.0, 0.0, -31.0)]
    ]
    for i in range(routes.size()):
        var officer := _build_officer("Agent PNC %02d" % (i + 1))
        officer.position = routes[i][0]
        officer.set_meta("state", "patrol")
        officer.set_meta("route_index", 1)
        officer.set_meta("search_timer", 0.0)
        add_child(officer)
        officers.append(officer)
        patrol_indices.append(1)

func _build_officer(label: String) -> Node3D:
    var root := Node3D.new()
    root.name = label
    _add_box(root, "Chemise bleu nuit", Vector3(0, 1.2, 0), Vector3(0.56, 0.72, 0.32), UNIFORM_BLUE)
    _add_box(root, "Pantalon", Vector3(-0.16, 0.52, 0), Vector3(0.19, 0.62, 0.22), TROUSER_BLUE)
    _add_box(root, "Pantalon", Vector3(0.16, 0.52, 0), Vector3(0.19, 0.62, 0.22), TROUSER_BLUE)
    _add_box(root, "Bottine", Vector3(-0.16, 0.12, -0.035), Vector3(0.23, 0.2, 0.38), BOOT_BLACK)
    _add_box(root, "Bottine", Vector3(0.16, 0.12, -0.035), Vector3(0.23, 0.2, 0.38), BOOT_BLACK)
    _add_box(root, "Ceinturon", Vector3(0, 0.84, 0), Vector3(0.59, 0.12, 0.36), BELT_BLACK)
    _add_box(root, "Bras gauche", Vector3(-0.39, 1.18, 0), Vector3(0.18, 0.64, 0.22), UNIFORM_BLUE)
    _add_box(root, "Bras droit", Vector3(0.39, 1.18, 0), Vector3(0.18, 0.64, 0.22), UNIFORM_BLUE)
    _add_sphere(root, "Tête", Vector3(0, 1.78, 0), Vector3(0.24, 0.27, 0.23), SKIN_BROWN)
    _add_box(root, "Béret sombre", Vector3(0, 2.02, 0.015), Vector3(0.43, 0.12, 0.38), TROUSER_BLUE)
    _add_box(root, "Poche poitrine", Vector3(-0.16, 1.31, -0.17), Vector3(0.14, 0.17, 0.035), TROUSER_BLUE)
    _add_box(root, "Poche poitrine", Vector3(0.16, 1.31, -0.17), Vector3(0.14, 0.17, 0.035), TROUSER_BLUE)
    var marking := Label3D.new()
    marking.text = "PNC"
    marking.font_size = 28
    marking.pixel_size = 0.008
    marking.position = Vector3(0, 1.43, -0.19)
    marking.modulate = Color(0.92, 0.9, 0.78)
    root.add_child(marking)
    var name_tag := Label3D.new()
    name_tag.text = "POLICE"
    name_tag.font_size = 22
    name_tag.pixel_size = 0.009
    name_tag.position = Vector3(0, 2.35, 0)
    name_tag.modulate = Color(0.92, 0.92, 0.86)
    root.add_child(name_tag)
    return root

func _patrol_officer(index: int, delta: float) -> void:
    var officer := officers[index]
    var route: Array = routes[index]
    var route_index := int(officer.get_meta("route_index", 0)) % route.size()
    var target: Vector3 = route[route_index]
    officer.position = officer.position.move_toward(target, 1.05 * delta)
    _face_target(officer, target)
    if officer.position.distance_to(target) < 0.22:
        officer.set_meta("route_index", (route_index + 1) % route.size())

func _pursue_player(officer: Node3D, delta: float, wanted: int) -> void:
    var target := vehicle_target.global_position if player_in_vehicle and is_instance_valid(vehicle_target) else player.global_position
    target.y = 0.0
    var speed := 3.0 + float(wanted) * 0.32
    officer.position = officer.position.move_toward(target, speed * delta)
    _face_target(officer, target)

func _face_target(officer: Node3D, target: Vector3) -> void:
    var direction := target - officer.position
    if Vector2(direction.x, direction.z).length() > 0.05:
        officer.rotation.y = lerp_angle(officer.rotation.y, atan2(-direction.x, -direction.z), 0.18)

func _add_box(parent: Node3D, label: String, pos: Vector3, size: Vector3, color: Color) -> void:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = pos
    node.material_override = _material(color)
    parent.add_child(node)

func _add_sphere(parent: Node3D, label: String, pos: Vector3, size: Vector3, color: Color) -> void:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    node.mesh = mesh
    node.position = pos
    node.scale = size
    node.material_override = _material(color)
    parent.add_child(node)

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    return material

func _announce(message: String) -> void:
    if message_cooldown > 0.0:
        return
    message_cooldown = 3.0
    police_message.emit(message)
