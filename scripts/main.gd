extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const MISSION_MANAGER_SCRIPT = preload("res://scripts/mission_manager.gd")
const DIALOGUE_MANAGER_SCRIPT = preload("res://scripts/dialogue_manager.gd")
const SAVE_PATH := "user://mobondo_save.json"

var player: CharacterBody3D
var camera: Camera3D
var mission_manager: Node
var dialogue_manager: Node
var dialogue_panel: PanelContainer
var dialogue_speaker_label: Label
var dialogue_text_label: Label
var dialogue_choices: VBoxContainer
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
    mission_manager.mission_message.connect(_on_mission_message)
    add_child(mission_manager)

    dialogue_manager = DIALOGUE_MANAGER_SCRIPT.new()
    dialogue_manager.dialogue_updated.connect(_on_dialogue_updated)
    dialogue_manager.dialogue_closed.connect(_on_dialogue_closed)
    dialogue_manager.conversation_finished.connect(_on_conversation_finished)
    add_child(dialogue_manager)
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
    run_button.text = "KIMA"
    run_button.custom_minimum_size = Vector2(100, 56)
    run_button.button_down.connect(func(): player.set_running(true))
    run_button.button_up.connect(func(): player.set_running(false))
    controls.add_child(run_button)

    var jump_button := Button.new()
    jump_button.text = "PUMBWA"
    jump_button.custom_minimum_size = Vector2(90, 56)
    jump_button.pressed.connect(func(): Input.action_press("jump"); Input.action_release("jump"))
    controls.add_child(jump_button)

    action_button = Button.new()
    action_button.text = "SALA"
    action_button.custom_minimum_size = Vector2(100, 56)
    action_button.pressed.connect(_perform_action)
    controls.add_child(action_button)

    _setup_dialogue_ui(layer)

func _setup_dialogue_ui(layer: CanvasLayer) -> void:
    dialogue_panel = PanelContainer.new()
    dialogue_panel.anchor_left = 0.12
    dialogue_panel.anchor_top = 0.56
    dialogue_panel.anchor_right = 0.88
    dialogue_panel.anchor_bottom = 0.94
    dialogue_panel.offset_left = 0
    dialogue_panel.offset_top = 0
    dialogue_panel.offset_right = 0
    dialogue_panel.offset_bottom = 0
    dialogue_panel.visible = false
    layer.add_child(dialogue_panel)

    var dialogue_column := VBoxContainer.new()
    dialogue_panel.add_child(dialogue_column)
    dialogue_speaker_label = Label.new()
    dialogue_speaker_label.add_theme_font_size_override("font_size", 22)
    dialogue_column.add_child(dialogue_speaker_label)
    dialogue_text_label = Label.new()
    dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialogue_text_label.custom_minimum_size = Vector2(0, 64)
    dialogue_column.add_child(dialogue_text_label)
    dialogue_choices = VBoxContainer.new()
    dialogue_column.add_child(dialogue_choices)

func _on_dialogue_updated(speaker: String, text: String, choices: Array) -> void:
    dialogue_panel.visible = true
    dialogue_speaker_label.text = speaker
    dialogue_text_label.text = text
    for child in dialogue_choices.get_children():
        child.queue_free()
    for i in range(choices.size()):
        var choice: Dictionary = choices[i]
        var choice_button := Button.new()
        choice_button.text = str(choice.get("text", "Pona"))
        choice_button.custom_minimum_size = Vector2(0, 44)
        choice_button.pressed.connect(_on_dialogue_choice_pressed.bind(i))
        dialogue_choices.add_child(choice_button)
    if is_instance_valid(player):
        player.set_physics_process(false)

func _on_dialogue_choice_pressed(index: int) -> void:
    if not is_instance_valid(dialogue_manager):
        return
    if dialogue_manager.waiting_for_close:
        dialogue_manager.close_dialogue()
    else:
        dialogue_manager.choose_option(index)

func _on_dialogue_closed() -> void:
    dialogue_panel.visible = false
    if is_instance_valid(player):
        player.set_physics_process(true)

func _on_conversation_finished(character_id: String, _choice_id: String) -> void:
    if character_id == "resident_mapela" and mission_manager.get_current_objective_id() == "talk_resident":
        mission_manager.complete_objective("talk_resident")

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
    if is_instance_valid(dialogue_panel) and dialogue_panel.visible:
        return
    if not is_instance_valid(mission_manager):
        return

    var objective_id: String = mission_manager.get_current_objective_id()
    match objective_id:
        "reach_market":
            if player.global_position.distance_to(market_position) < 4.0:
                mission_manager.complete_objective(objective_id)
            else:
                status_label.text = "Pusana pene ya zando liboso ya kosala SALA."
        "talk_resident":
            if player.global_position.distance_to(npc_position) < 3.5:
                if not dialogue_manager.start_dialogue("resident_mapela"):
                    status_label.text = "Okoki kosolola na ye sikoyo te."
            else:
                status_label.text = "Pusana pene ya moto ya quartier liboso ya kosala SALA."
        "collect_parcel":
            if player.global_position.distance_to(parcel_position) < 3.5:
                mission_manager.complete_objective(objective_id)
            else:
                status_label.text = "Pusana pene ya colis liboso ya kosala SALA."
        _:
            status_label.text = "Mission oyo ebongisami naino te."

func _refresh_mission() -> void:
    if not is_instance_valid(mission_manager):
        return
    _on_mission_updated(
        mission_manager.get_mission_title(),
        mission_manager.get_objective_text(),
        mission_manager.get_current_objective_id(),
        mission_manager.get_current_objective_index(),
        mission_manager.get_current_objective_total()
    )

func _on_mission_updated(title: String, objective: String, objective_id: String, index: int, total: int) -> void:
    var progress := "" if total == 0 else "\nMokano %d/%d" % [index, total]
    mission_label.text = title + progress + "\n" + objective
    if is_instance_valid(parcel):
        parcel.visible = objective_id == "collect_parcel"

func _on_mission_completed(episode_title: String) -> void:
    status_label.text = "Malamu! Osilisi: " + episode_title
    _refresh_mission()

func _on_mission_failed(reason: String) -> void:
    status_label.text = "Mission elongi te: " + reason

func _on_mission_message(message: String) -> void:
    status_label.text = message

func _update_status() -> void:
    if not is_instance_valid(mission_manager):
        return
    if mission_manager.is_current_episode_completed():
        status_label.text = "Eteni oyo esili. Tokobongisa oyo elandi."
    elif player.global_position.length() > 0.1:
        status_label.text = "Landa mokano ya mission mpe finá SALA pene ya esika oyo esengeli."

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
