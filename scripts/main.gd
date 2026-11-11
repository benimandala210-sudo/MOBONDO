extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const MISSION_MANAGER_SCRIPT = preload("res://scripts/mission_manager.gd")
const SAVE_PATH := "user://mobondo_save.json"

var player: CharacterBody3D
var camera: Camera3D
var mission_manager: Node
var mission_label: Label
var status_label: Label
var action_button: Button
var run_button: Button
var held_keys := {"left": false, "right": false, "up": false, "down": false}

var npc_position := Vector3(5, 0, -28)
var parcel_position := Vector3(-8, 0.5, -30)
var market_position := Vector3(0, 0, -15)
var parcel: MeshInstance3D

func _ready() -> void:
    _setup_world()
    _setup_player()
    _setup_ui()
    mission_manager = MISSION_MANAGER_SCRIPT.new()
    mission_manager.mission_updated.connect(_on_mission_updated)
    mission_manager.mission_completed.connect(_on_mission_completed)
    mission_manager.mission_failed.connect(_on_mission_failed)
    add_child(mission_manager)
    _refresh_mission()

func _process(_delta: float) -> void:
    if is_instance_valid(player) and is_instance_valid(camera):
        camera.global_position = player.global_position + Vector3(0, 7, 11)
        camera.look_at(player.global_position + Vector3(0, 1, 0), Vector3.UP)
    _update_mobile_direction()
    _update_status()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_E or event.keycode == KEY_SPACE:
            _perform_action()

func _setup_world() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.72, 0.78, 0.9)
    env.ambient_light_energy = 0.8
    environment.environment = env
    add_child(environment)

    _add_box("Sol", Vector3(0, -0.55, -15), Vector3(70, 1, 80), Color(0.22, 0.42, 0.24))
    _add_box("Route", Vector3(0, -0.02, -15), Vector3(9, 0.12, 80), Color(0.18, 0.18, 0.2))

    for i in range(6):
        var z := -5.0 - float(i) * 10.0
        _add_box("Maison gauche %d" % i, Vector3(-9, 2, z), Vector3(6, 5, 7), Color(0.72, 0.48, 0.31))
        _add_box("Maison droite %d" % i, Vector3(9, 2, z - 3), Vector3(6, 5, 7), Color(0.65, 0.68, 0.52))

    for i in range(4):
        _add_box("Étal marché %d" % i, Vector3(-5 + i * 3.2, 0.9, -21), Vector3(2.5, 1.8, 2), Color(0.62, 0.3, 0.16))

    _add_marker("Objectif marché", market_position + Vector3(0, 0.2, 0), Color(1, 0.78, 0.12))
    _add_marker("Habitant", npc_position + Vector3(0, 1, 0), Color(0.2, 0.75, 1))
    parcel = _add_box("Colis", parcel_position, Vector3(0.9, 0.9, 0.9), Color(0.9, 0.62, 0.16))
    parcel.visible = false

func _setup_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Joueur"
    player.position = Vector3(0, 1, 0)
    player.set_script(PLAYER_SCRIPT)
    add_child(player)

    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.42
    capsule.height = 1.8
    body.mesh = capsule
    body.position.y = 0.9
    body.material_override = _material(Color(0.12, 0.3, 0.72))
    player.add_child(body)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42
    shape.height = 1.8
    collision.shape = shape
    collision.position.y = 0.9
    player.add_child(collision)

    camera = Camera3D.new()
    camera.current = true
    add_child(camera)

func _setup_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    panel.custom_minimum_size = Vector2(340, 92)
    layer.add_child(panel)

    var column := VBoxContainer.new()
    panel.add_child(column)
    mission_label = Label.new()
    mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(mission_label)
    status_label = Label.new()
    column.add_child(status_label)

    var controls := HBoxContainer.new()
    controls.anchor_left = 0.0
    controls.anchor_top = 1.0
    controls.anchor_right = 1.0
    controls.anchor_bottom = 1.0
    controls.offset_left = 12
    controls.offset_top = -82
    controls.offset_right = -12
    controls.offset_bottom = -12
    layer.add_child(controls)

    var left_box := HBoxContainer.new()
    controls.add_child(left_box)
    _add_hold_button(left_box, "◀", "left")
    _add_hold_button(left_box, "▲", "up")
    _add_hold_button(left_box, "▼", "down")
    _add_hold_button(left_box, "▶", "right")

    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    controls.add_child(spacer)

    run_button = Button.new()
    run_button.text = "COURIR"
    run_button.custom_minimum_size = Vector2(100, 56)
    run_button.button_down.connect(func(): player.set_running(true))
    run_button.button_up.connect(func(): player.set_running(false))
    controls.add_child(run_button)

    var jump_button := Button.new()
    jump_button.text = "SAUTER"
    jump_button.custom_minimum_size = Vector2(90, 56)
    jump_button.pressed.connect(func(): Input.action_press("jump"); Input.action_release("jump"))
    controls.add_child(jump_button)

    action_button = Button.new()
    action_button.text = "ACTION"
    action_button.custom_minimum_size = Vector2(100, 56)
    action_button.pressed.connect(_perform_action)
    controls.add_child(action_button)

func _add_hold_button(parent: HBoxContainer, caption: String, key_name: String) -> void:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(58, 56)
    button.button_down.connect(func(): held_keys[key_name] = true)
    button.button_up.connect(func(): held_keys[key_name] = false)
    parent.add_child(button)

func _update_mobile_direction() -> void:
    if not is_instance_valid(player):
        return
    var x := float(held_keys["right"]) - float(held_keys["left"])
    var y := float(held_keys["down"]) - float(held_keys["up"])
    player.set_mobile_direction(Vector2(x, y))

func _perform_action() -> void:
    if not is_instance_valid(mission_manager):
        return

    var objective_id: String = mission_manager.get_current_objective_id()
    match objective_id:
        "reach_market":
            if player.global_position.distance_to(market_position) < 4.0:
                mission_manager.complete_objective(objective_id)
            else:
                status_label.text = "Pusana pene ya zando liboso ya kosala ACTION."
        "talk_resident":
            if player.global_position.distance_to(npc_position) < 3.5:
                mission_manager.complete_objective(objective_id)
            else:
                status_label.text = "Pusana pene ya moto ya quartier liboso ya kosala ACTION."
        "collect_parcel":
            if player.global_position.distance_to(parcel_position) < 3.5:
                mission_manager.complete_objective(objective_id)
            else:
                status_label.text = "Pusana pene ya colis liboso ya kosala ACTION."
        _:
            status_label.text = "Mission oyo ezali naino na préparation."

func _refresh_mission() -> void:
    if not is_instance_valid(mission_manager):
        return
    _on_mission_updated(
        mission_manager.get_mission_title(),
        mission_manager.get_objective_text(),
        mission_manager.get_current_objective_id(),
        0,
        0
    )

func _on_mission_updated(title: String, objective: String, objective_id: String, _index: int, _total: int) -> void:
    mission_label.text = title + "\\n" + objective
    if is_instance_valid(parcel):
        parcel.visible = objective_id == "collect_parcel"

func _on_mission_completed(episode_title: String) -> void:
    status_label.text = "Malamu! Osilisi: " + episode_title
    _refresh_mission()

func _on_mission_failed(reason: String) -> void:
    status_label.text = "Mission elongi te: " + reason

func _update_status() -> void:
    if not is_instance_valid(mission_manager):
        return
    if mission_manager.is_current_episode_completed():
        status_label.text = "Episodi esili. Tokobongisa oyo elandi."
    elif player.global_position.length() > 0.1:
        status_label.text = "Landa mokano ya mission mpe finá ACTION pene ya esika oyo esengeli."

func _add_marker(marker_name: String, pos: Vector3, color: Color) -> MeshInstance3D:
    var marker := MeshInstance3D.new()
    marker.name = marker_name
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.35
    mesh.bottom_radius = 0.35
    mesh.height = 0.25
    marker.mesh = mesh
    marker.position = pos
    marker.material_override = _material(color)
    add_child(marker)
    return marker

func _add_box(box_name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = box_name
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.position = pos
    item.material_override = _material(color)
    add_child(item)
    var static_body := StaticBody3D.new()
    item.add_child(static_body)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    static_body.add_child(collision)
    return item

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    return mat
