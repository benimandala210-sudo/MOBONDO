extends Node3D

const PLAYER_SCENE = preload("res://scenes/characters/player/player.tscn")
const MISSION_MANAGER_SCRIPT = preload("res://scripts/mission_manager.gd")
const DIALOGUE_MANAGER_SCRIPT = preload("res://scripts/dialogue_manager.gd")
const ECONOMY_MANAGER_SCRIPT = preload("res://scripts/economy_manager.gd")
const MOBONDO_EMBLEM_SCRIPT = preload("res://scripts/mobondo_emblem.gd")
const SAVE_PATH := "user://mobondo_save.json"

var player: CharacterBody3D
var camera: Camera3D
var mission_manager
var dialogue_manager
var economy_manager
var market_panel: PanelContainer
var wallet_label: Label
var market_balance_label: Label
var market_inventory_label: Label
var market_message_label: Label
var game_ui_layer: CanvasLayer
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
var menu_layer: CanvasLayer
var menu_root: Control
var main_menu_panel: PanelContainer
var mode_panel: PanelContainer
var settings_panel: PanelContainer
var menu_message: Label
var selected_mode := "histoire"
var menu_active := true
var menu_taxi: Node3D
var menu_emblem: Control
var menu_glow: ColorRect
var menu_time := 0.0
var transition_active := false
var pedestrian_nodes: Array[Node3D] = []
var pedestrian_origins: Array[Vector3] = []
var pedestrian_speeds: Array[float] = []
var street_moto: Node3D
var world_minutes := 7.0 * 60.0
var routine_refresh_timer := 0.0
var sunlight: DirectionalLight3D
var world_clock_label: Label

func _ready() -> void:
    _setup_world()
    _setup_player()
    _setup_ui()
    _setup_main_menu()
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
    economy_manager = ECONOMY_MANAGER_SCRIPT.new()
    economy_manager.economy_updated.connect(_on_economy_updated)
    add_child(economy_manager)
    _refresh_mission()

func _process(delta: float) -> void:
    menu_time += delta
    _animate_street_life()
    _update_world_clock(delta)
    if is_instance_valid(camera):
        if menu_active:
            camera.global_position = Vector3(sin(menu_time * 0.12) * 0.45, 7.2 + sin(menu_time * 0.22) * 0.12, 16.5)
            camera.look_at(Vector3(0, 2.0, -15), Vector3.UP)
            if is_instance_valid(menu_emblem):
                var pulse := 1.0 + sin(menu_time * 1.8) * 0.025
                menu_emblem.scale = Vector2(pulse, pulse)
            if is_instance_valid(menu_glow):
                var glow_color := menu_glow.color
                glow_color.a = 0.12 + (sin(menu_time * 0.7) + 1.0) * 0.025
                menu_glow.color = glow_color
        elif is_instance_valid(player) and not transition_active:
            var camera_target := player.global_position + Vector3(0, 5.6, 9.0)
            camera.global_position = camera.global_position.lerp(camera_target, minf(delta * 5.5, 1.0))
            var look_target := player.global_position + Vector3(0, 1.15, 0)
            camera.look_at(look_target, Vector3.UP)
    if not menu_active:
        _update_mobile_direction()
        _update_status()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_E:
            _perform_action()

func _setup_world() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.72, 0.78, 0.9)
    env.ambient_light_energy = 0.8
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.environment = env
    add_child(environment)

    sunlight = DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-38, -28, 0)
    sunlight.light_color = Color(1.0, 0.78, 0.55)
    sunlight.light_energy = 1.15
    sunlight.shadow_enabled = false
    add_child(sunlight)

    # Construction complète du premier secteur jouable Mapela–Raïs.
    _add_box("Terrain Mapela", Vector3(0, -0.55, -15), Vector3(70, 1, 80), Color(0.22, 0.42, 0.24))
    _add_box("Avenue Bilonda", Vector3(0, -0.02, -15), Vector3(9, 0.12, 80), Color(0.25, 0.23, 0.22))
    _create_roadside_environment()
    _create_road_markings_and_lights()
    _create_mapela_road_network()
    _create_mapela_houses()
    _create_market_detail()
    _create_mapela_landmarks()
    _create_masina_local_areas()
    _create_rais_railway_remains()
    _create_mapela_street_directory()
    _create_pedestrians()
    _create_menu_taxi()




func _create_mapela_landmarks() -> void:
    _create_neighborhood_admin_hut(Vector3(-21.0, 0.0, -12.0))
    _create_neighborhood_health_post(Vector3(22.0, 0.0, -36.0))
    _create_neighborhood_school(Vector3(-22.0, 0.0, -43.0))
    _create_neighborhood_church(Vector3(22.0, 0.0, -8.0))
    _create_football_space(Vector3(0.0, 0.0, -57.0))
    _create_water_point(Vector3(5.5, 0.0, -39.0))

func _create_masina_local_areas() -> void:
    # Emplacements de jeu provisoires : les positions exactes restent à confirmer.
    _create_pascal_market(Vector3(25.0, 0.0, -51.0))
    _create_bar_terrace(Vector3(-14.0, 0.0, -16.0), "BAR-TERRASSE DU QUARTIER", Color(0.66, 0.3, 0.16))
    _create_bar_terrace(Vector3(14.0, 0.0, -28.0), "TERRASSE POPULAIRE", Color(0.24, 0.38, 0.28))
    _create_bar_terrace(Vector3(-14.0, 0.0, -39.0), "BAR DU COIN", Color(0.25, 0.34, 0.52))
    _create_masina_communal_office(Vector3(0.0, 0.0, 18.0))

func _create_bar_terrace(origin: Vector3, sign_text: String, awning_color: Color) -> void:
    _add_visual_box("Bar de quartier — bâtiment", origin + Vector3(0, 1.45, 0), Vector3(5.0, 2.9, 4.2), Color(0.68, 0.57, 0.42))
    _add_visual_box("Toit bar", origin + Vector3(0, 3.0, 0), Vector3(5.3, 0.18, 4.5), Color(0.25, 0.27, 0.27))
    _add_visual_box("Comptoir terrasse", origin + Vector3(0, 1.0, 2.35), Vector3(3.4, 1.0, 0.55), Color(0.32, 0.2, 0.12))
    _add_visual_box("Auvent terrasse", origin + Vector3(0, 2.55, 3.0), Vector3(5.2, 0.12, 2.0), awning_color)
    _create_street_name_marker(sign_text, origin + Vector3(0, 3.8, -2.3))
    for i in range(3):
        var table_x := -1.8 + float(i) * 1.8
        _add_visual_box("Table terrasse", origin + Vector3(table_x, 0.92, 4.2), Vector3(0.95, 0.12, 0.95), Color(0.36, 0.23, 0.13))
        _add_visual_box("Pied table terrasse", origin + Vector3(table_x, 0.48, 4.2), Vector3(0.12, 0.85, 0.12), Color(0.18, 0.17, 0.15))
        for side in [-1.0, 1.0]:
            _add_visual_box("Chaise terrasse", origin + Vector3(table_x + side * 0.62, 0.48, 4.2), Vector3(0.42, 0.08, 0.42), Color(0.16, 0.22, 0.24))
            _add_visual_box("Dossier chaise", origin + Vector3(table_x + side * 0.62, 0.82, 4.42), Vector3(0.42, 0.62, 0.08), Color(0.16, 0.22, 0.24))

func _create_pascal_market(origin: Vector3) -> void:
    # Marché Pascal : lieu nommé par le concepteur. L'ambiance de foule est jouable,
    # mais aucune personne ni aucun commerçant n'est désigné comme voleur.
    _add_visual_box("Marché Pascal — sol", origin + Vector3(0, 0.04, 0), Vector3(20.0, 0.08, 16.0), Color(0.55, 0.42, 0.28))
    _add_visual_box("Entrée Marché Pascal", origin + Vector3(0, 2.0, 8.0), Vector3(12.0, 3.8, 0.35), Color(0.22, 0.25, 0.23))
    _create_street_name_marker("GRAND MARCHE PASCAL", origin + Vector3(0, 4.2, 8.4))
    var awning_colors := [Color(0.72, 0.18, 0.12), Color(0.86, 0.68, 0.18), Color(0.18, 0.38, 0.28), Color(0.2, 0.32, 0.55)]
    for i in range(4):
        var x := -6.0 + float(i) * 4.0
        _add_visual_box("Etal marché Pascal", origin + Vector3(x, 1.0, -2.0), Vector3(3.0, 2.0, 2.8), Color(0.48, 0.29, 0.17))
        _add_visual_box("Bâche étal Pascal", origin + Vector3(x, 2.25, -2.0), Vector3(3.4, 0.12, 3.2), awning_colors[i])
        for item in range(3):
            _add_visual_box("Produits marché Pascal", origin + Vector3(x - 0.8 + float(item) * 0.8, 2.0, -2.0), Vector3(0.5, 0.3, 0.55), Color(0.76, 0.43, 0.12))
    _add_visual_box("Panneau vigilance marché", origin + Vector3(8.5, 1.8, 5.0), Vector3(0.15, 2.4, 2.6), Color(0.16, 0.2, 0.18))
    var warning := Label3D.new()
    warning.text = "ZALA NA BOKEBI\nBA BILOKO NA YO"
    warning.font_size = 25
    warning.pixel_size = 0.012
    warning.modulate = Color(1.0, 0.86, 0.58)
    warning.position = origin + Vector3(8.62, 1.8, 5.0)
    warning.rotation.y = PI / 2.0
    add_child(warning)

func _create_masina_communal_office(origin: Vector3) -> void:
    # Maison communale de Masina : repère public placé à l'entrée BKTF vers Mapela.
    _add_visual_box("Maison communale Masina — bâtiment", origin + Vector3(0, 2.0, 0), Vector3(10.0, 4.0, 7.0), Color(0.76, 0.72, 0.6))
    _add_visual_box("Toit maison communale", origin + Vector3(0, 4.12, 0), Vector3(10.4, 0.2, 7.4), Color(0.28, 0.32, 0.32))
    _add_visual_box("Entrée maison communale", origin + Vector3(5.08, 1.25, 0), Vector3(0.12, 2.5, 1.8), Color(0.18, 0.24, 0.28))
    _add_visual_box("Cour maison communale", origin + Vector3(0, 0.03, 5.2), Vector3(14.0, 0.06, 5.0), Color(0.58, 0.47, 0.34))
    _create_street_name_marker("MAISON COMMUNALE DE MASINA", origin + Vector3(0, 5.0, -3.8))
    _create_street_name_marker("ENTREE BKTF — VERS MAPELA", origin + Vector3(-7.0, 2.0, 5.0))

func _create_neighborhood_admin_hut(origin: Vector3) -> void:
    # Représentation volontairement modeste du bureau de quartier décrit comme un hangar.
    _add_visual_box("Bureau quartier — abri administratif", origin + Vector3(0, 1.35, 0), Vector3(5.0, 2.7, 4.2), Color(0.62, 0.56, 0.43))
    _add_visual_box("Toit hangar bureau quartier", origin + Vector3(0, 2.82, 0), Vector3(5.5, 0.16, 4.7), Color(0.32, 0.35, 0.35))
    _add_visual_box("Ouverture bureau quartier", origin + Vector3(2.54, 1.0, 0), Vector3(0.08, 1.8, 1.3), Color(0.16, 0.18, 0.17))
    _add_visual_box("Comptoir bureau quartier", origin + Vector3(1.6, 0.85, -0.6), Vector3(1.0, 0.12, 1.3), Color(0.34, 0.24, 0.15))
    _create_street_name_marker("BUREAU DU QUARTIER", origin + Vector3(0, 3.7, -2.6))

func _create_neighborhood_health_post(origin: Vector3) -> void:
    _add_visual_box("Centre de santé — bâtiment", origin + Vector3(0, 1.8, 0), Vector3(6.2, 3.6, 5.8), Color(0.78, 0.75, 0.65))
    _add_visual_box("Toit centre de santé", origin + Vector3(0, 3.72, 0), Vector3(6.5, 0.18, 6.1), Color(0.35, 0.38, 0.36))
    _add_visual_box("Porte centre de santé", origin + Vector3(3.14, 1.0, 0), Vector3(0.1, 2.0, 1.25), Color(0.2, 0.3, 0.34))
    _add_visual_box("Signe croix centre santé", origin + Vector3(3.25, 2.8, 0), Vector3(0.12, 0.85, 0.85), Color(0.75, 0.12, 0.12))
    _add_visual_box("Cour centre de santé", origin + Vector3(0, 0.025, 4.5), Vector3(9.0, 0.05, 3.0), Color(0.58, 0.46, 0.32))
    _create_street_name_marker("CENTRE DE SANTE", origin + Vector3(0, 4.35, -3.2))

func _create_neighborhood_school(origin: Vector3) -> void:
    _add_visual_box("École du quartier — bâtiment", origin + Vector3(0, 1.7, 0), Vector3(8.0, 3.4, 5.0), Color(0.76, 0.67, 0.48))
    _add_visual_box("Toit école", origin + Vector3(0, 3.52, 0), Vector3(8.3, 0.18, 5.3), Color(0.34, 0.37, 0.36))
    for i in range(4):
        _add_visual_box("Fenêtre école", origin + Vector3(4.06, 2.1, -1.8 + float(i) * 1.2), Vector3(0.1, 0.85, 0.75), Color(0.18, 0.28, 0.32))
    _add_visual_box("Porte école", origin + Vector3(4.08, 1.0, 0), Vector3(0.12, 2.0, 1.1), Color(0.28, 0.19, 0.12))
    _add_visual_box("Cour de récréation", origin + Vector3(0, 0.02, 5.0), Vector3(12.0, 0.04, 5.0), Color(0.59, 0.45, 0.29))
    _create_street_name_marker("ECOLE DU QUARTIER", origin + Vector3(0, 4.1, -2.9))

func _create_neighborhood_church(origin: Vector3) -> void:
    _add_visual_box("Église de quartier — salle", origin + Vector3(0, 2.0, 0), Vector3(7.0, 4.0, 6.0), Color(0.72, 0.68, 0.56))
    _add_visual_box("Toit église", origin + Vector3(0, 4.1, 0), Vector3(7.3, 0.18, 6.3), Color(0.3, 0.34, 0.35))
    _add_visual_box("Entrée église", origin + Vector3(3.56, 1.2, 0), Vector3(0.12, 2.4, 1.6), Color(0.26, 0.18, 0.12))
    _add_visual_box("Croix église verticale", origin + Vector3(3.8, 5.0, 0), Vector3(0.16, 1.1, 0.16), Color(0.82, 0.72, 0.48))
    _add_visual_box("Croix église horizontale", origin + Vector3(3.8, 5.12, 0), Vector3(0.16, 0.16, 0.7), Color(0.82, 0.72, 0.48))
    _create_street_name_marker("SALLE DE PRIERE", origin + Vector3(0, 5.8, -3.0))

func _create_football_space(origin: Vector3) -> void:
    _add_visual_box("Terrain de football quartier", origin + Vector3(0, 0.02, 0), Vector3(18.0, 0.05, 11.0), Color(0.3, 0.43, 0.22))
    _add_visual_box("Ligne centrale terrain", origin + Vector3(0, 0.06, 0), Vector3(0.08, 0.02, 10.8), Color(0.83, 0.82, 0.69))
    _add_visual_box("Ligne but gauche", origin + Vector3(-8.8, 0.06, 0), Vector3(0.08, 0.02, 10.8), Color(0.83, 0.82, 0.69))
    _add_visual_box("Ligne but droite", origin + Vector3(8.8, 0.06, 0), Vector3(0.08, 0.02, 10.8), Color(0.83, 0.82, 0.69))
    _add_visual_box("Poteau but 1", origin + Vector3(-8.6, 0.7, -1.2), Vector3(0.12, 1.4, 0.12), Color(0.82, 0.8, 0.7))
    _add_visual_box("Poteau but 2", origin + Vector3(-8.6, 0.7, 1.2), Vector3(0.12, 1.4, 0.12), Color(0.82, 0.8, 0.7))
    _add_visual_box("Barre but", origin + Vector3(-8.6, 1.38, 0), Vector3(0.12, 0.12, 2.4), Color(0.82, 0.8, 0.7))

func _create_water_point(origin: Vector3) -> void:
    _add_visual_box("Socle point d'eau", origin + Vector3(0, 0.35, 0), Vector3(1.5, 0.7, 1.2), Color(0.45, 0.43, 0.37))
    _add_visual_box("Cuve point d'eau", origin + Vector3(0, 1.55, 0), Vector3(1.1, 1.7, 1.0), Color(0.26, 0.42, 0.55))
    _add_visual_box("Robinet point d'eau", origin + Vector3(0.72, 1.0, 0.2), Vector3(0.55, 0.12, 0.12), Color(0.62, 0.65, 0.64))
    _create_street_name_marker("POINT D'EAU", origin + Vector3(0, 2.8, -0.9))

func _create_mapela_road_network() -> void:
    # Bilonda est documentée comme axe important de Mapela.
    _create_street_name_marker("AVENUE BILONDA", Vector3(-4.45, 2.1, -8.0))
    # OpenStreetMap indique Frontiere comme connectée à Bilonda et à Rue Imbali.
    # Les tracés ci-dessous sont des approximations de gameplay, pas un relevé cadastral.
    _add_visual_box("Ruelle Frontiere — tracé provisoire", Vector3(-10.5, 0.015, -50.0), Vector3(13.0, 0.07, 3.2), Color(0.34, 0.31, 0.27))
    _add_visual_box("Ruelle Imbali — tracé provisoire", Vector3(-17.0, 0.02, -44.5), Vector3(3.2, 0.07, 11.0), Color(0.34, 0.31, 0.27))
    _create_street_name_marker("FRONTIERE", Vector3(-10.5, 1.65, -52.0))
    _create_street_name_marker("RUE IMBALI", Vector3(-19.0, 1.65, -44.5))
    _add_visual_box("Accotement ruelle Frontiere", Vector3(-10.5, 0.02, -51.7), Vector3(13.0, 0.06, 0.18), Color(0.58, 0.43, 0.29))

func _create_street_name_marker(street_name: String, origin: Vector3) -> void:
    var post := MeshInstance3D.new()
    var post_mesh := CylinderMesh.new()
    post_mesh.top_radius = 0.045
    post_mesh.bottom_radius = 0.07
    post_mesh.height = 1.7
    post.mesh = post_mesh
    post.position = origin + Vector3(0, -0.8, 0)
    post.material_override = _material(Color(0.2, 0.21, 0.2))
    add_child(post)
    _add_visual_box("Plaque " + street_name, origin, Vector3(0.12, 0.52, 2.3), Color(0.1, 0.28, 0.2))
    var label := Label3D.new()
    label.text = street_name
    label.font_size = 28
    label.pixel_size = 0.012
    label.modulate = Color(0.96, 0.9, 0.72)
    label.position = origin + Vector3(0.08, 0, 0)
    label.rotation.y = PI / 2.0
    add_child(label)

func _create_rais_railway_remains() -> void:
    # Repère visuel de Raïs : morceaux de fer et traverses discontinus.
    # Aucun train ni circulation ferroviaire n'est représenté dans cette zone.
    var rail_x := 19.0
    for i in range(13):
        var z := -3.0 - float(i) * 5.7
        var sleeper := _add_visual_box("Traverse ancienne Raïs", Vector3(rail_x, 0.02, z), Vector3(2.2, 0.12, 0.42), Color(0.24, 0.2, 0.16))
        sleeper.rotation.y = 0.0
        if i % 3 != 1:
            _add_visual_box("Morceau de fer ancien Raïs", Vector3(rail_x - 0.55, 0.11, z + 0.1), Vector3(0.09, 0.12, 1.8), Color(0.28, 0.3, 0.29))
        if i % 4 == 0:
            _add_visual_box("Fer rouillé Raïs", Vector3(rail_x + 0.58, 0.13, z - 0.35), Vector3(0.12, 0.1, 0.95), Color(0.42, 0.22, 0.12))
    _create_street_name_marker("RAÏS — ANCIENNES TRACES", Vector3(19.0, 1.8, -2.2))

func _create_mapela_street_directory() -> void:
    # Les noms sont conservés sans inventer la position des rues non cartographiées.
    var board_position := Vector3(-5.7, 2.2, -19.0)
    _add_visual_box("Panneau repère Mapela", board_position, Vector3(0.18, 3.8, 4.8), Color(0.16, 0.18, 0.17))
    var directory := Label3D.new()
    directory.text = "MAPELA — RUES\nBilonda • Frontiere • Kahumba\nLufushi • Muteba • Ngufulu\nNtalu 1 • Ntalu 2 • Fatuma\nImbali • Inzia • Justice\nKikwit • Kotoko • Kulu\nMbula • Milundu • Travail\nSalongo • Yassa"
    directory.font_size = 25
    directory.pixel_size = 0.009
    directory.modulate = Color(0.95, 0.87, 0.68)
    directory.position = board_position + Vector3(0.11, 0, 0)
    directory.rotation.y = PI / 2.0
    add_child(directory)

func _create_mapela_houses() -> void:
    var wall_colors := [
        Color(0.72, 0.48, 0.31), Color(0.65, 0.68, 0.52),
        Color(0.76, 0.67, 0.52), Color(0.58, 0.61, 0.58),
        Color(0.72, 0.58, 0.42), Color(0.62, 0.66, 0.64)
    ]
    for i in range(6):
        var z := -5.0 - float(i) * 10.0
        _create_kinshasa_house("Parcelle gauche %d" % (i + 1), Vector3(-9.0, 0.0, z), wall_colors[i], true, i)
        _create_kinshasa_house("Parcelle droite %d" % (i + 1), Vector3(9.0, 0.0, z - 3.0), wall_colors[(i + 2) % wall_colors.size()], false, i + 1)

func _create_kinshasa_house(house_name: String, center: Vector3, wall_color: Color, faces_left: bool, variation: int) -> void:
    _add_box(house_name, center + Vector3(0, 2.0, 0), Vector3(6.0, 4.0, 7.0), wall_color)
    var front_x := center.x + (3.04 if faces_left else -3.04)
    var sign := 1.0 if faces_left else -1.0
    var door_z := center.z + (0.8 if variation % 2 == 0 else -0.8)
    _add_visual_box("Porte " + house_name, Vector3(front_x, 1.05, door_z), Vector3(0.12, 2.1, 1.15), Color(0.24, 0.16, 0.11))
    for offset in [-1.8, 1.8]:
        _add_visual_box("Fenêtre " + house_name, Vector3(front_x + sign * 0.08, 2.35, center.z + offset), Vector3(0.12, 1.0, 1.25), Color(0.16, 0.24, 0.27))
        _add_visual_box("Volet " + house_name, Vector3(front_x + sign * 0.16, 2.35, center.z + offset), Vector3(0.08, 1.08, 0.08), Color(0.32, 0.22, 0.15))
    _add_visual_box("Toit tôle " + house_name, center + Vector3(0, 4.18, 0), Vector3(6.5, 0.28, 7.5), Color(0.31, 0.34, 0.35))
    for rib in range(9):
        var rib_z := center.z - 3.35 + float(rib) * 0.82
        _add_visual_box("Nervure tôle", Vector3(center.x, 4.34, rib_z), Vector3(6.45, 0.035, 0.045), Color(0.48, 0.5, 0.49))
    _add_visual_box("Auvent " + house_name, Vector3(front_x + sign * 0.35, 3.1, center.z), Vector3(0.9, 0.12, 3.2), Color(0.43, 0.25, 0.13))
    _add_visual_box("Mur parcelle " + house_name, Vector3(center.x, 0.55, center.z + 4.0), Vector3(6.8, 1.1, 0.22), Color(0.55, 0.52, 0.45))
    for gate_z in [center.z - 2.0, center.z + 2.0]:
        _add_visual_box("Poteau parcelle", Vector3(front_x, 0.9, gate_z), Vector3(0.28, 1.8, 0.28), Color(0.42, 0.4, 0.36))

func _create_market_detail() -> void:
    for i in range(4):
        var x := -5.0 + float(i) * 3.2
        _add_box("Étal marché %d" % i, Vector3(x, 0.85, -21.0), Vector3(2.5, 1.7, 1.8), Color(0.56, 0.31, 0.17))
        var canopy_color: Color = [Color(0.72, 0.18, 0.12), Color(0.88, 0.72, 0.22), Color(0.18, 0.38, 0.28), Color(0.2, 0.32, 0.55)][i]
        _add_visual_box("Bâche marché %d" % i, Vector3(x, 2.35, -21.0), Vector3(2.9, 0.12, 2.4), canopy_color)
        for dx in [-1.25, 1.25]:
            for dz in [-1.0, 1.0]:
                _add_visual_box("Poteau étal", Vector3(x + dx, 1.55, -21.0 + dz), Vector3(0.09, 1.5, 0.09), Color(0.25, 0.2, 0.15))
        for item_index in range(3):
            var produce_color: Color = [Color(0.78, 0.15, 0.1), Color(0.82, 0.52, 0.12), Color(0.25, 0.55, 0.2)][item_index]
            _add_visual_box("Marchandise", Vector3(x - 0.65 + float(item_index) * 0.62, 1.82, -21.0), Vector3(0.42, 0.28, 0.48), produce_color)

func _create_roadside_environment() -> void:
    # Accotements en terre et caniveaux latéraux.
    _add_visual_box("Caniveau gauche", Vector3(-5.15, -0.12, -15.0), Vector3(0.3, 0.18, 80.0), Color(0.25, 0.24, 0.2))
    _add_visual_box("Caniveau droite", Vector3(5.15, -0.12, -15.0), Vector3(0.3, 0.18, 80.0), Color(0.25, 0.24, 0.2))
    _add_visual_box("Trottoir terre gauche", Vector3(-6.2, 0.0, -15.0), Vector3(1.8, 0.12, 80.0), Color(0.58, 0.43, 0.29))
    _add_visual_box("Trottoir terre droite", Vector3(6.2, 0.0, -15.0), Vector3(1.8, 0.12, 80.0), Color(0.58, 0.43, 0.29))
    # Quelques arbres et touffes de végétation pour casser la répétition.
    for i in range(7):
        var z := -3.0 - float(i) * 10.5
        _create_roadside_tree(Vector3(-13.2, 0.0, z), 1.0 + float(i % 3) * 0.12)
        if i % 2 == 0:
            _create_roadside_tree(Vector3(13.0, 0.0, z - 3.0), 0.9)
    # Panneaux fictifs : espaces de visibilité réservés aux marques du projet.
    _create_brand_sign("MOBONDO", Vector3(-7.2, 2.7, -12.0), Color(0.12, 0.12, 0.13))
    _create_brand_sign("KIRADESIGN", Vector3(7.2, 2.7, -30.0), Color(0.12, 0.12, 0.13))
    _create_brand_sign("KIRATECHNOLOGIE", Vector3(-7.2, 2.7, -48.0), Color(0.12, 0.12, 0.13))


func _create_road_markings_and_lights() -> void:
    # Marquage discret : route urbaine, pas une autoroute.
    for i in range(12):
        var z := -1.5 - float(i) * 6.0
        _add_visual_box("Trait central route", Vector3(0, 0.055, z), Vector3(0.12, 0.025, 2.2), Color(0.82, 0.72, 0.48))
    _add_visual_box("Bande bord route gauche", Vector3(-4.25, 0.055, -15.0), Vector3(0.07, 0.025, 80.0), Color(0.55, 0.53, 0.46))
    _add_visual_box("Bande bord route droite", Vector3(4.25, 0.055, -15.0), Vector3(0.07, 0.025, 80.0), Color(0.55, 0.53, 0.46))
    # Passage piéton à proximité du marché.
    for i in range(6):
        _add_visual_box("Passage piéton", Vector3(-3.6 + float(i) * 1.2, 0.06, -17.0), Vector3(0.72, 0.025, 2.2), Color(0.78, 0.76, 0.68))
    # Lampadaires simples, utiles pour les scènes nocturnes.
    _create_street_light(Vector3(-6.9, 0.0, -8.0))
    _create_street_light(Vector3(6.9, 0.0, -27.0))
    _create_street_light(Vector3(-6.9, 0.0, -47.0))

func _create_street_light(origin: Vector3) -> void:
    var pole := MeshInstance3D.new()
    var pole_mesh := CylinderMesh.new()
    pole_mesh.top_radius = 0.055
    pole_mesh.bottom_radius = 0.09
    pole_mesh.height = 5.2
    pole.mesh = pole_mesh
    pole.position = origin + Vector3(0, 2.6, 0)
    pole.material_override = _material(Color(0.22, 0.23, 0.22))
    add_child(pole)
    _add_visual_box("Bras lampadaire", origin + Vector3(0.35, 5.05, 0), Vector3(0.8, 0.08, 0.08), Color(0.22, 0.23, 0.22))
    var lamp := MeshInstance3D.new()
    var lamp_mesh := SphereMesh.new()
    lamp_mesh.radius = 0.16
    lamp_mesh.height = 0.22
    lamp.mesh = lamp_mesh
    lamp.position = origin + Vector3(0.72, 4.98, 0)
    var lamp_material := StandardMaterial3D.new()
    lamp_material.albedo_color = Color(1.0, 0.78, 0.42)
    lamp_material.emission_enabled = true
    lamp_material.emission = Color(1.0, 0.58, 0.2)
    lamp_material.emission_energy_multiplier = 0.6
    lamp.material_override = lamp_material
    add_child(lamp)

func _create_roadside_tree(origin: Vector3, scale_value: float) -> void:
    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.16 * scale_value
    trunk_mesh.bottom_radius = 0.24 * scale_value
    trunk_mesh.height = 2.0 * scale_value
    trunk.mesh = trunk_mesh
    trunk.position = origin + Vector3(0, scale_value, 0)
    trunk.material_override = _material(Color(0.3, 0.19, 0.11))
    add_child(trunk)
    var crown := MeshInstance3D.new()
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 1.05 * scale_value
    crown_mesh.height = 1.8 * scale_value
    crown.mesh = crown_mesh
    crown.position = origin + Vector3(0, 2.2 * scale_value, 0)
    crown.material_override = _material(Color(0.17, 0.38, 0.18))
    add_child(crown)

func _create_brand_sign(text_value: String, origin: Vector3, background_color: Color) -> void:
    _add_visual_box("Panneau " + text_value, origin, Vector3(0.16, 1.1, 3.0), background_color)
    var sign_text := Label3D.new()
    sign_text.text = text_value
    sign_text.font_size = 32
    sign_text.pixel_size = 0.012
    sign_text.modulate = Color(0.9, 0.68, 0.32)
    sign_text.position = origin + Vector3(0.1, 0, 0)
    sign_text.rotation.y = PI / 2.0
    add_child(sign_text)

func _add_visual_box(box_name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = box_name
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.position = pos
    item.material_override = _material(color)
    add_child(item)
    return item

func _create_menu_taxi() -> void:
    menu_taxi = Node3D.new()
    menu_taxi.name = "Taxi jaune animé"
    menu_taxi.position = Vector3(-4.8, 0.0, -8.0)
    add_child(menu_taxi)

    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = Vector3(2.2, 0.72, 3.8)
    body.mesh = body_mesh
    body.position.y = 0.72
    body.material_override = _material(Color(0.93, 0.68, 0.08))
    menu_taxi.add_child(body)

    var cabin := MeshInstance3D.new()
    var cabin_mesh := BoxMesh.new()
    cabin_mesh.size = Vector3(1.72, 0.72, 1.85)
    cabin.mesh = cabin_mesh
    cabin.position = Vector3(0, 1.38, -0.12)
    cabin.material_override = _material(Color(0.16, 0.22, 0.25))
    menu_taxi.add_child(cabin)

    var roof_sign := MeshInstance3D.new()
    var sign_mesh := BoxMesh.new()
    sign_mesh.size = Vector3(0.72, 0.2, 0.34)
    roof_sign.mesh = sign_mesh
    roof_sign.position = Vector3(0, 1.86, -0.12)
    roof_sign.material_override = _material(Color(0.95, 0.9, 0.72))
    menu_taxi.add_child(roof_sign)

    for x in [-0.92, 0.92]:
        for z in [-1.25, 1.25]:
            var wheel := MeshInstance3D.new()
            var wheel_mesh := CylinderMesh.new()
            wheel_mesh.top_radius = 0.34
            wheel_mesh.bottom_radius = 0.34
            wheel_mesh.height = 0.2
            wheel.mesh = wheel_mesh
            wheel.position = Vector3(x, 0.38, z)
            wheel.rotation.z = PI / 2.0
            wheel.material_override = _material(Color(0.055, 0.055, 0.06))
            menu_taxi.add_child(wheel)


func _create_pedestrians() -> void:
    var mado := _create_pedestrian("Mado", npc_position, Color(0.48, 0.2, 0.12), false, 0.0)
    mado.set_meta("character_id", "resident_mapela")
    _create_pedestrian("Passant 1", Vector3(-4.2, 0.0, -12.0), Color(0.18, 0.38, 0.62), true, 0.72)
    _create_pedestrian("Passant 2", Vector3(4.2, 0.0, -23.0), Color(0.22, 0.48, 0.3), true, 0.58)
    _create_pedestrian("Passant 3", Vector3(-3.8, 0.0, -34.0), Color(0.55, 0.34, 0.16), true, 0.66)
    var seller := _create_pedestrian("Mama Sifa", Vector3(-4.8, 0.0, -21.0), Color(0.55, 0.18, 0.16), false, 0.0)
    seller.set_meta("character_id", "seller_market")
    seller.set_meta("role", "seller")
    var customer := _create_pedestrian("Junior", Vector3(3.8, 0.0, -22.5), Color(0.18, 0.38, 0.62), false, 0.0)
    customer.set_meta("character_id", "customer_market")
    customer.set_meta("role", "customer")
    # Vie quotidienne : enfants près du terrain et habitants devant les parcelles.
    var child_one := _create_pedestrian("Enfant joueur 1", Vector3(-3.2, 0.0, -56.0), Color(0.82, 0.48, 0.12), true, 1.05)
    child_one.set_meta("role", "child")
    var child_two := _create_pedestrian("Enfant joueur 2", Vector3(3.0, 0.0, -58.0), Color(0.22, 0.42, 0.72), true, 0.92)
    child_two.set_meta("role", "child")
    var resident_one := _create_pedestrian("Habitant devant parcelle", Vector3(-7.2, 0.0, -7.0), Color(0.38, 0.28, 0.2), false, 0.0)
    resident_one.set_meta("role", "resident")
    var resident_two := _create_pedestrian("Habitante près maison", Vector3(7.1, 0.0, -37.0), Color(0.48, 0.2, 0.32), false, 0.0)
    resident_two.set_meta("role", "resident")
    _create_street_motos()

func _create_street_motos() -> void:
    street_moto = Node3D.new()
    street_moto.name = "Moto taxi de quartier"
    street_moto.position = Vector3(2.6, 0.0, -2.0)
    add_child(street_moto)

    var frame := MeshInstance3D.new()
    var frame_mesh := BoxMesh.new()
    frame_mesh.size = Vector3(0.34, 0.28, 1.35)
    frame.mesh = frame_mesh
    frame.position = Vector3(0, 0.78, 0)
    frame.material_override = _material(Color(0.16, 0.19, 0.2))
    street_moto.add_child(frame)

    var seat := MeshInstance3D.new()
    var seat_mesh := BoxMesh.new()
    seat_mesh.size = Vector3(0.48, 0.16, 0.58)
    seat.mesh = seat_mesh
    seat.position = Vector3(0, 1.02, 0.08)
    seat.material_override = _material(Color(0.12, 0.1, 0.09))
    street_moto.add_child(seat)

    for wheel_z in [-0.62, 0.62]:
        var wheel := MeshInstance3D.new()
        var wheel_mesh := CylinderMesh.new()
        wheel_mesh.top_radius = 0.34
        wheel_mesh.bottom_radius = 0.34
        wheel_mesh.height = 0.14
        wheel.mesh = wheel_mesh
        wheel.position = Vector3(0, 0.36, wheel_z)
        wheel.rotation.z = PI / 2.0
        wheel.material_override = _material(Color(0.045, 0.045, 0.05))
        street_moto.add_child(wheel)

    var handle := MeshInstance3D.new()
    var handle_mesh := BoxMesh.new()
    handle_mesh.size = Vector3(0.85, 0.08, 0.08)
    handle.mesh = handle_mesh
    handle.position = Vector3(0, 1.18, -0.58)
    handle.material_override = _material(Color(0.32, 0.32, 0.3))
    street_moto.add_child(handle)

    var headlight := MeshInstance3D.new()
    var light_mesh := SphereMesh.new()
    light_mesh.radius = 0.13
    light_mesh.height = 0.18
    headlight.mesh = light_mesh
    headlight.position = Vector3(0, 0.92, -0.72)
    headlight.material_override = _material(Color(0.95, 0.82, 0.48))
    street_moto.add_child(headlight)

func _create_pedestrian(person_name: String, origin: Vector3, shirt_color: Color, walks: bool, speed: float) -> Node3D:
    var person := Node3D.new()
    person.name = person_name
    person.position = origin
    add_child(person)

    var torso := MeshInstance3D.new()
    var torso_mesh := CapsuleMesh.new()
    torso_mesh.radius = 0.28
    torso_mesh.height = 0.95
    torso.mesh = torso_mesh
    torso.position.y = 1.0
    torso.material_override = _material(shirt_color)
    person.add_child(torso)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.2
    head_mesh.height = 0.4
    head.mesh = head_mesh
    head.position.y = 1.65
    head.material_override = _material(Color(0.32, 0.19, 0.12))
    person.add_child(head)

    var leg_material := _material(Color(0.12, 0.12, 0.14))
    for side in [-1.0, 1.0]:
        var leg := MeshInstance3D.new()
        var leg_mesh := CapsuleMesh.new()
        leg_mesh.radius = 0.105
        leg_mesh.height = 0.62
        leg.mesh = leg_mesh
        leg.position = Vector3(side * 0.13, 0.38, 0)
        leg.material_override = leg_material
        person.add_child(leg)

    person.set_meta("walks", walks)
    person.set_meta("role", "passer" if person_name.begins_with("Passant") else "resident")
    person.set_meta("active_walks", walks)
    person.set_meta("phase", float(pedestrian_nodes.size()) * 1.7)
    pedestrian_nodes.append(person)
    pedestrian_origins.append(origin)
    pedestrian_speeds.append(speed)
    return person

func _animate_street_life() -> void:
    if is_instance_valid(menu_taxi):
        menu_taxi.position.x = -4.8 + fposmod(menu_time * 1.35, 9.6)
    if is_instance_valid(street_moto):
        street_moto.position.z = -2.0 - fposmod(menu_time * 3.2, 68.0)
        street_moto.rotation.y = PI
    for i in range(pedestrian_nodes.size()):
        var person := pedestrian_nodes[i]
        if not is_instance_valid(person):
            continue
        if bool(person.get_meta("walks", false)):
            var phase: float = float(person.get_meta("phase", 0.0))
            var speed: float = pedestrian_speeds[i]
            var origin: Vector3 = pedestrian_origins[i]
            person.position.x = origin.x + sin(menu_time * speed + phase) * 1.15
            person.position.y = abs(sin(menu_time * speed * 2.0 + phase)) * 0.035
            person.rotation.y = 0.0 if cos(menu_time * speed + phase) >= 0.0 else PI
        else:
            person.position.y = abs(sin(menu_time * 1.8)) * 0.018


func _update_world_clock(delta: float) -> void:
    # Une seconde réelle représente une minute dans le monde du jeu.
    var previous_minutes := world_minutes
    world_minutes = fposmod(world_minutes + delta, 1440.0)
    if world_minutes < previous_minutes and is_instance_valid(economy_manager):
        economy_manager.reset_daily()
    var hour := int(world_minutes / 60.0)
    var minute := int(fposmod(world_minutes, 60.0))
    var period := "Butu" if hour < 6 or hour >= 19 else ("Mpokwa" if hour < 12 else ("Nsima ya midi" if hour < 15 else "Mpokwa ya sima"))
    if is_instance_valid(world_clock_label):
        world_clock_label.text = "%02d:%02d — %s" % [hour, minute, period]

    routine_refresh_timer += delta
    if routine_refresh_timer >= 2.0:
        routine_refresh_timer = 0.0
        _apply_npc_routines(hour)

    if is_instance_valid(sunlight):
        var daylight := clampf((sin((world_minutes / 1440.0) * TAU - PI / 2.0) + 0.18) * 1.35, 0.12, 1.0)
        sunlight.light_energy = 0.22 + daylight * 0.95
        sunlight.rotation_degrees.x = -10.0 - daylight * 48.0
        sunlight.light_color = Color(1.0, 0.66 + daylight * 0.18, 0.42 + daylight * 0.18)

func _apply_npc_routines(hour: int) -> void:
    for person in pedestrian_nodes:
        if not is_instance_valid(person):
            continue
        var role := str(person.get_meta("role", "resident"))
        match role:
            "seller":
                person.visible = hour >= 6 and hour < 19
            "customer":
                person.visible = hour >= 7 and hour < 18
            "passer":
                person.visible = hour >= 6 and hour < 22
            _:
                person.visible = true
        if role == "passer":
            person.set_meta("walks", hour >= 6 and hour < 22)

func _setup_player() -> void:
    player = PLAYER_SCENE.instantiate() as CharacterBody3D
    player.name = "Joueur"
    player.position = Vector3(0, 1, 0)
    player.visible = false
    player.set_physics_process(false)
    add_child(player)

    camera = Camera3D.new()
    camera.name = "CameraTroisiemePersonne"
    camera.current = true
    camera.position = Vector3(0, 5.6, 9.0)
    add_child(camera)
    player.set_movement_camera(camera)

func _setup_ui() -> void:
    var layer := CanvasLayer.new()
    game_ui_layer = layer
    layer.visible = false
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
    world_clock_label = Label.new()
    world_clock_label.text = "07:00 — Mokolo ya sika"
    world_clock_label.add_theme_color_override("font_color", Color(0.9, 0.72, 0.42))
    column.add_child(world_clock_label)
    wallet_label = Label.new()
    wallet_label.text = "Mbongo: 10 000 FC"
    column.add_child(wallet_label)

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
    jump_button.pressed.connect(player.request_jump)
    controls.add_child(jump_button)

    action_button = Button.new()
    action_button.text = "SALA"
    action_button.custom_minimum_size = Vector2(100, 56)
    action_button.pressed.connect(_perform_action)
    controls.add_child(action_button)

    _setup_dialogue_ui(layer)
    _setup_market_ui(layer)

func _setup_main_menu() -> void:
    menu_layer = CanvasLayer.new()
    menu_layer.layer = 20
    add_child(menu_layer)

    menu_root = Control.new()
    menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(menu_root)

    var backdrop := ColorRect.new()
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.color = Color(0.035, 0.045, 0.055, 0.78)
    menu_root.add_child(backdrop)

    var glow := ColorRect.new()
    glow.anchor_left = 0.0
    glow.anchor_top = 0.0
    glow.anchor_right = 1.0
    glow.anchor_bottom = 1.0
    glow.color = Color(0.34, 0.19, 0.07, 0.16)
    menu_glow = glow
    menu_root.add_child(glow)

    main_menu_panel = _create_menu_panel(menu_root)
    var main_column := VBoxContainer.new()
    main_column.add_theme_constant_override("separation", 14)
    main_menu_panel.add_child(main_column)

    var studio := Label.new()
    studio.text = "KIRATECHNOLOGIE PRÉSENTE"
    studio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    studio.add_theme_font_size_override("font_size", 13)
    studio.add_theme_color_override("font_color", Color(0.82, 0.61, 0.32))
    main_column.add_child(studio)

    var emblem := Control.new()
    emblem.set_script(MOBONDO_EMBLEM_SCRIPT)
    emblem.custom_minimum_size = Vector2(104, 92)
    menu_emblem = emblem
    main_column.add_child(emblem)

    var title := Label.new()
    title.text = "MOBONDO"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 42)
    title.add_theme_color_override("font_color", Color(0.94, 0.72, 0.36))
    main_column.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "MOKILI MOKO. BOMOI MOKO. LISOLO NA YO."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.add_theme_font_size_override("font_size", 12)
    subtitle.add_theme_color_override("font_color", Color(0.86, 0.82, 0.73))
    main_column.add_child(subtitle)

    var separator := HSeparator.new()
    main_column.add_child(separator)

    var play_button := _make_menu_button("BANDÁ KOSALA", true)
    play_button.pressed.connect(_show_mode_selection)
    main_column.add_child(play_button)

    var settings_button := _make_menu_button("PARAMÈTRES", false)
    settings_button.pressed.connect(_show_settings)
    main_column.add_child(settings_button)

    var footer := Label.new()
    footer.text = "KINSHASA • MAPELA–RAÏS"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 11)
    footer.add_theme_color_override("font_color", Color(0.68, 0.65, 0.58))
    main_column.add_child(footer)

    mode_panel = _create_menu_panel(menu_root)
    mode_panel.visible = false
    var mode_column := VBoxContainer.new()
    mode_column.add_theme_constant_override("separation", 12)
    mode_panel.add_child(mode_column)

    var mode_title := Label.new()
    mode_title.text = "PONA LOLENGE YA KOSakana"
    mode_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mode_title.add_theme_font_size_override("font_size", 21)
    mode_title.add_theme_color_override("font_color", Color(0.94, 0.72, 0.36))
    mode_column.add_child(mode_title)

    var story_button := _make_menu_button("MODE HISTOIRE", true)
    story_button.pressed.connect(func(): _start_game("histoire"))
    mode_column.add_child(story_button)

    var free_button := _make_menu_button("BOMOI YA LIBRE", false)
    free_button.pressed.connect(func(): _start_game("libre"))
    mode_column.add_child(free_button)

    var back_mode := _make_menu_button("ZONGA", false)
    back_mode.pressed.connect(_show_main_menu)
    mode_column.add_child(back_mode)

    settings_panel = _create_menu_panel(menu_root)
    settings_panel.visible = false
    var settings_column := VBoxContainer.new()
    settings_column.add_theme_constant_override("separation", 12)
    settings_panel.add_child(settings_column)

    var settings_title := Label.new()
    settings_title.text = "PARAMÈTRES"
    settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    settings_title.add_theme_font_size_override("font_size", 22)
    settings_title.add_theme_color_override("font_color", Color(0.94, 0.72, 0.36))
    settings_column.add_child(settings_title)

    var language_label := Label.new()
    language_label.text = "LOKOTA: LINGALA YA KINSHASA"
    language_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    language_label.add_theme_color_override("font_color", Color(0.9, 0.87, 0.8))
    settings_column.add_child(language_label)

    var language_note := Label.new()
    language_note.text = "Français : option à intégrer dans une prochaine version."
    language_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    language_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    language_note.add_theme_font_size_override("font_size", 12)
    language_note.add_theme_color_override("font_color", Color(0.72, 0.7, 0.65))
    settings_column.add_child(language_note)

    var settings_back := _make_menu_button("ZONGA", false)
    settings_back.pressed.connect(_show_main_menu)
    settings_column.add_child(settings_back)

    menu_message = Label.new()
    menu_message.text = "Version prototype — interface en construction"
    menu_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    menu_message.add_theme_font_size_override("font_size", 10)
    menu_message.add_theme_color_override("font_color", Color(0.7, 0.68, 0.62))
    menu_message.anchor_left = 0.05
    menu_message.anchor_right = 0.95
    menu_message.anchor_top = 0.94
    menu_message.anchor_bottom = 0.99
    menu_root.add_child(menu_message)

func _create_menu_panel(parent: Control) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.anchor_left = 0.08
    panel.anchor_top = 0.18
    panel.anchor_right = 0.92
    panel.anchor_bottom = 0.82
    panel.offset_left = 0
    panel.offset_top = 0
    panel.offset_right = 0
    panel.offset_bottom = 0
    panel.add_theme_stylebox_override("panel", _menu_panel_style())
    parent.add_child(panel)
    return panel

func _menu_panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.07, 0.075, 0.08, 0.96)
    style.border_color = Color(0.72, 0.48, 0.2, 0.9)
    style.set_border_width_all(2)
    style.set_corner_radius_all(14)
    style.content_margin_left = 24
    style.content_margin_right = 24
    style.content_margin_top = 24
    style.content_margin_bottom = 24
    return style

func _make_menu_button(caption: String, highlighted: bool) -> Button:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(0, 52)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", 16)
    if highlighted:
        button.add_theme_color_override("font_color", Color(0.08, 0.07, 0.05))
        button.add_theme_color_override("font_hover_color", Color(0.08, 0.07, 0.05))
        var normal := StyleBoxFlat.new()
        normal.bg_color = Color(0.82, 0.57, 0.24)
        normal.set_corner_radius_all(8)
        button.add_theme_stylebox_override("normal", normal)
        var hover := StyleBoxFlat.new()
        hover.bg_color = Color(0.95, 0.72, 0.36)
        hover.set_corner_radius_all(8)
        button.add_theme_stylebox_override("hover", hover)
    return button

func _show_mode_selection() -> void:
    main_menu_panel.visible = false
    mode_panel.visible = true
    settings_panel.visible = false

func _show_settings() -> void:
    main_menu_panel.visible = false
    mode_panel.visible = false
    settings_panel.visible = true

func _show_main_menu() -> void:
    main_menu_panel.visible = true
    mode_panel.visible = false
    settings_panel.visible = false

func _start_game(mode: String) -> void:
    if transition_active or not menu_active:
        return
    selected_mode = mode
    transition_active = true
    _play_start_transition()

func _play_start_transition() -> void:
    var transition_layer := CanvasLayer.new()
    transition_layer.layer = 30
    add_child(transition_layer)

    var veil := ColorRect.new()
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    veil.color = Color.BLACK
    veil.modulate.a = 0.0
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    transition_layer.add_child(veil)

    var fade_in := create_tween()
    fade_in.tween_property(veil, "modulate:a", 1.0, 0.45)
    await fade_in.finished

    menu_active = false
    menu_root.visible = false
    if is_instance_valid(player):
        player.global_position = Vector3(0, 1, 0)
        player.velocity = Vector3.ZERO
        player.visible = true
        player.set_physics_process(false)

    camera.global_position = Vector3(0, 6.5, 12.0)
    camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)

    var camera_move := create_tween()
    camera_move.set_trans(Tween.TRANS_CUBIC)
    camera_move.set_ease(Tween.EASE_OUT)
    camera_move.tween_property(camera, "global_position", Vector3(0, 4.2, 8.2), 1.8)
    await camera_move.finished
    camera.look_at(player.global_position + Vector3(0, 1.0, 0), Vector3.UP)

    if selected_mode == "histoire":
        status_label.text = "MODE HISTOIRE — Tokoba na eteni ya liboso."
        _refresh_mission()
    else:
        status_label.text = "BOMOI YA LIBRE — Ozali na bonsomi ya kotambola."

    var fade_out := create_tween()
    fade_out.tween_property(veil, "modulate:a", 0.0, 0.65)
    await fade_out.finished

    player.set_physics_process(true)
    game_ui_layer.visible = true
    transition_layer.queue_free()
    transition_active = false

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
    if speaker.begins_with("Mama Sifa") and not dialogue_manager.waiting_for_close:
        var market_button := Button.new()
        market_button.text = "Tala mpe somba biloko na zando"
        market_button.custom_minimum_size = Vector2(0, 44)
        market_button.pressed.connect(_open_market)
        dialogue_choices.add_child(market_button)
    if is_instance_valid(player):
        player.set_physics_process(false)

func _setup_market_ui(layer: CanvasLayer) -> void:
    market_panel = PanelContainer.new()
    market_panel.anchor_left = 0.08
    market_panel.anchor_top = 0.14
    market_panel.anchor_right = 0.92
    market_panel.anchor_bottom = 0.86
    market_panel.visible = false
    layer.add_child(market_panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    market_panel.add_child(column)
    var title := Label.new()
    title.text = "ZANDO YA MAMA SIFA"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    column.add_child(title)
    market_balance_label = Label.new()
    column.add_child(market_balance_label)
    market_inventory_label = Label.new()
    market_inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(market_inventory_label)
    var goods = [["Eau — 1 000 FC", "eau"], ["Pain — 1 500 FC", "pain"], ["Tomates — 2 000 FC", "tomates"]]
    for good in goods:
        var row := HBoxContainer.new()
        column.add_child(row)
        var buy_button := Button.new()
        buy_button.text = "Somba " + str(good[0])
        buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        buy_button.pressed.connect(_buy_market_item.bind(str(good[1])))
        row.add_child(buy_button)
        var sell_button := Button.new()
        sell_button.text = "Teka"
        sell_button.pressed.connect(_sell_market_item.bind(str(good[1])))
        row.add_child(sell_button)
    var job_button := Button.new()
    job_button.text = "Salisa komema biloko — zwa 4 000 FC"
    job_button.pressed.connect(_do_market_job)
    column.add_child(job_button)
    market_message_label = Label.new()
    market_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(market_message_label)
    var close_button := Button.new()
    close_button.text = "KANGA ZANDO"
    close_button.pressed.connect(_close_market)
    column.add_child(close_button)

func _open_market() -> void:
    if is_instance_valid(dialogue_manager) and not dialogue_manager.active_character_id.is_empty():
        dialogue_manager.close_dialogue()
    dialogue_panel.visible = false
    market_panel.visible = true
    if is_instance_valid(player):
        player.set_physics_process(false)
    _on_economy_updated(economy_manager.get_balance(), economy_manager.inventory, "Tala biloko oyo ezali na zando.")

func _close_market() -> void:
    market_panel.visible = false
    if is_instance_valid(player):
        player.set_physics_process(true)

func _buy_market_item(item_id: String) -> void:
    economy_manager.buy(item_id)

func _sell_market_item(item_id: String) -> void:
    economy_manager.sell(item_id)

func _do_market_job() -> void:
    economy_manager.do_market_job()

func _on_economy_updated(balance: int, inventory: Dictionary, message: String) -> void:
    if is_instance_valid(wallet_label):
        wallet_label.text = "Mbongo: %s FC" % _format_fc(balance)
    if is_instance_valid(market_balance_label):
        market_balance_label.text = "Portefeuille: %s FC" % _format_fc(balance)
    if is_instance_valid(market_inventory_label):
        market_inventory_label.text = "Biloko na yo: Eau %d | Pain %d | Tomates %d" % [int(inventory.get("eau", 0)), int(inventory.get("pain", 0)), int(inventory.get("tomates", 0))]
    if is_instance_valid(market_message_label):
        market_message_label.text = message

func _format_fc(amount: int) -> String:
    var raw := str(amount)
    var result := ""
    var count := 0
    for i in range(raw.length() - 1, -1, -1):
        result = raw.substr(i, 1) + result
        count += 1
        if count == 3 and i > 0:
            result = " " + result
            count = 0
    return result

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
    if _try_talk_to_nearby_npc():
        return
    if selected_mode == "libre":
        status_label.text = "Ozali na bomoi ya bonsomi. Pusana pene ya moto mpo na kosolola."
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

func _try_talk_to_nearby_npc() -> bool:
    var closest_id := ""
    var closest_distance := 3.6
    for person in pedestrian_nodes:
        if not is_instance_valid(person) or not person.has_meta("character_id"):
            continue
        var distance := player.global_position.distance_to(person.global_position)
        if distance < closest_distance:
            closest_distance = distance
            closest_id = str(person.get_meta("character_id"))
    if closest_id.is_empty():
        return false
    return dialogue_manager.start_dialogue(closest_id)

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
    if selected_mode == "libre":
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