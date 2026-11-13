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

func configure(player_ref: CharacterBody3D, reputation_ref: Node, arrest_action: Callable) -> void:
    player = player_ref
    reputation_manager = reputation_ref
    arrest_callback = arrest_action
    _create_patrol_officers()

func set_active(value: bool) -> void:
    active = value
    if not active:
        for officer in officers:
            if is_instance_valid(officer) and str(officer.get_meta("state", "patrol")) == "pursuit":
                officer.set_meta("state", "patrol")
                officer.set_meta("search_timer", 0.0)

func set_player_vehicle_state(occupied: bool, speed_kmh: float = 0.0) -> void:
    player_in_vehicle = occupied
    vehicle_speed_kmh = absf(speed_kmh)

func _process(delta: float) -> void:
    if not active or not is_instance_valid(player) or not player.visible or not is_instance_valid(reputation_manager):
        return
    if message_cooldown > 0.0:
        message_cooldown = maxf(0.0, message_cooldown - delta)
    var wanted := int(reputation_manager.wanted_level)
    for i in range(officers.size()):
        var officer := officers[i]
        if not is_instance_valid(officer):
            continue
        var state := str(officer.get_meta("state", "patrol"))
        var distance := Vector2(officer.global_position.x - player.global_position.x, officer.global_position.z - player.global_position.z).length()
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
    var target := player.global_position
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
