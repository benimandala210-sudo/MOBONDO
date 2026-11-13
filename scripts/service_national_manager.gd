extends Node3D
## Figurants du Service national : les Bâtisseurs en opération d'assainissement.
## Référence visuelle documentée : tenue bleue et bottes jaunes (opération à Masina, juillet 2026).

const BLUE := Color(0.035, 0.12, 0.31)
const BLUE_DARK := Color(0.025, 0.07, 0.19)
const YELLOW := Color(0.92, 0.68, 0.08)
const SKIN := [Color(0.25, 0.13, 0.085), Color(0.34, 0.19, 0.12), Color(0.19, 0.105, 0.07)]
const BROOM_WOOD := Color(0.43, 0.25, 0.12)
const BROOM_STRAW := Color(0.72, 0.57, 0.28)
var workers: Array[Node3D] = []
var arm_pivots: Array[Node3D] = []
var elapsed := 0.0

func _ready() -> void:
    _build_cleanup_site()

func _process(delta: float) -> void:
    elapsed += delta
    for i in range(arm_pivots.size()):
        var pivot := arm_pivots[i]
        if is_instance_valid(pivot):
            pivot.rotation.x = sin(elapsed * 1.7 + float(i) * 1.8) * 0.22
            pivot.rotation.z = sin(elapsed * 1.15 + float(i)) * 0.12

func _build_cleanup_site() -> void:
    var positions := [Vector3(5.6, 0.0, -49.0), Vector3(7.1, 0.0, -47.0), Vector3(5.8, 0.0, -45.0)]
    for i in range(positions.size()):
        var worker := _build_worker("Bâtisseur %02d" % (i + 1), i)
        worker.position = positions[i]
        worker.rotation.y = -0.55 + float(i) * 0.48
        add_child(worker)
        workers.append(worker)
    _add_debris(Vector3(6.8, 0.0, -50.0))
    _add_wheelbarrow(Vector3(8.1, 0.0, -46.2))
    _add_sign(Vector3(8.0, 1.45, -51.0))

func _build_worker(label: String, index: int) -> Node3D:
    var root := Node3D.new()
    root.name = label
    var skin: Color = SKIN[index % SKIN.size()]
    _box(root, "Veste bleue de travail", Vector3(0, 1.2, 0), Vector3(0.58, 0.7, 0.32), BLUE)
    _box(root, "Pantalon bleu", Vector3(-0.16, 0.52, 0), Vector3(0.2, 0.62, 0.23), BLUE_DARK)
    _box(root, "Pantalon bleu", Vector3(0.16, 0.52, 0), Vector3(0.2, 0.62, 0.23), BLUE_DARK)
    _box(root, "Botte jaune", Vector3(-0.16, 0.12, -0.05), Vector3(0.24, 0.2, 0.38), YELLOW)
    _box(root, "Botte jaune", Vector3(0.16, 0.12, -0.05), Vector3(0.24, 0.2, 0.38), YELLOW)
    _box(root, "Col de travail", Vector3(0, 1.57, -0.02), Vector3(0.28, 0.12, 0.34), BLUE_DARK)
    _sphere(root, "Tête", Vector3(0, 1.77, 0), Vector3(0.24, 0.29, 0.23), skin)
    _box(root, "Bras gauche", Vector3(-0.38, 1.18, -0.02), Vector3(0.18, 0.58, 0.2), BLUE)
    var shoulder := Node3D.new()
    shoulder.position = Vector3(0.34, 1.48, -0.02)
    root.add_child(shoulder)
    _box(shoulder, "Bras droit", Vector3(0.04, -0.24, 0), Vector3(0.17, 0.5, 0.19), BLUE)
    _sphere(shoulder, "Main", Vector3(0.04, -0.49, -0.015), Vector3(0.1, 0.11, 0.1), skin)
    arm_pivots.append(shoulder)
    _box(root, "Poche poitrine", Vector3(-0.17, 1.34, -0.17), Vector3(0.14, 0.16, 0.035), BLUE_DARK)
    var tag := Label3D.new()
    tag.text = "SN"
    tag.font_size = 24
    tag.pixel_size = 0.009
    tag.position = Vector3(0, 1.43, -0.18)
    tag.modulate = Color(0.96, 0.91, 0.7)
    root.add_child(tag)
    if index == 0:
        _add_broom(root, shoulder)
    elif index == 1:
        _add_shovel(root, shoulder)
    else:
        _add_rake(root, shoulder)
    return root

func _add_broom(root: Node3D, shoulder: Node3D) -> void:
    _box(shoulder, "Manche balai", Vector3(0.02, -0.73, -0.12), Vector3(0.055, 0.95, 0.055), BROOM_WOOD)
    _box(shoulder, "Brosse balai", Vector3(0.02, -1.2, -0.12), Vector3(0.28, 0.15, 0.11), BROOM_STRAW)

func _add_shovel(root: Node3D, shoulder: Node3D) -> void:
    _box(shoulder, "Manche pelle", Vector3(0.0, -0.76, -0.1), Vector3(0.06, 1.0, 0.06), BROOM_WOOD)
    _box(shoulder, "Lame pelle", Vector3(0.0, -1.25, -0.1), Vector3(0.25, 0.22, 0.07), Color(0.42, 0.45, 0.46))

func _add_rake(root: Node3D, shoulder: Node3D) -> void:
    _box(shoulder, "Manche râteau", Vector3(0.0, -0.76, -0.1), Vector3(0.055, 1.0, 0.055), BROOM_WOOD)
    _box(shoulder, "Tête râteau", Vector3(0.0, -1.25, -0.1), Vector3(0.38, 0.07, 0.08), Color(0.38, 0.4, 0.42))
    for i in range(5):
        _box(shoulder, "Dent râteau", Vector3(-0.15 + float(i) * 0.075, -1.34, -0.1), Vector3(0.035, 0.13, 0.055), Color(0.38, 0.4, 0.42))

func _add_debris(origin: Vector3) -> void:
    for i in range(5):
        var sack := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.28
        mesh.height = 0.52
        sack.mesh = mesh
        sack.scale = Vector3(0.8, 0.85, 0.75)
        sack.position = origin + Vector3(float(i % 3) * 0.42, 0.22, float(i / 3) * 0.42)
        sack.material_override = _mat(Color(0.38, 0.39, 0.31))
        add_child(sack)
    _box(self, "Tas de déchets ramassés", origin + Vector3(1.0, 0.12, 0.55), Vector3(0.6, 0.2, 0.42), Color(0.25, 0.27, 0.22))

func _add_wheelbarrow(origin: Vector3) -> void:
    _box(self, "Brouette caisse", origin + Vector3(0, 0.48, 0), Vector3(0.65, 0.28, 0.95), Color(0.38, 0.4, 0.41))
    _box(self, "Brouette pied gauche", origin + Vector3(-0.28, 0.2, 0.3), Vector3(0.07, 0.35, 0.07), Color(0.23, 0.24, 0.24))
    _box(self, "Brouette pied droit", origin + Vector3(0.28, 0.2, 0.3), Vector3(0.07, 0.35, 0.07), Color(0.23, 0.24, 0.24))
    var wheel := MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.1
    mesh.outer_radius = 0.19
    wheel.mesh = mesh
    wheel.position = origin + Vector3(0, 0.22, -0.55)
    wheel.material_override = _mat(Color(0.04, 0.045, 0.05))
    add_child(wheel)

func _add_sign(origin: Vector3) -> void:
    _box(self, "Panneau Service national", origin, Vector3(0.12, 1.1, 1.9), BLUE_DARK)
    var label := Label3D.new()
    label.text = "SERVICE NATIONAL\nLES BÂTISSEURS"
    label.font_size = 26
    label.pixel_size = 0.009
    label.position = origin + Vector3(0.08, 0, 0)
    label.rotation.y = PI / 2.0
    label.modulate = Color(0.98, 0.9, 0.68)
    add_child(label)

func _box(parent: Node3D, label: String, pos: Vector3, size: Vector3, color: Color) -> void:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = pos
    node.material_override = _mat(color)
    parent.add_child(node)

func _sphere(parent: Node3D, label: String, pos: Vector3, size: Vector3, color: Color) -> void:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    node.mesh = mesh
    node.position = pos
    node.scale = size
    node.material_override = _mat(color)
    parent.add_child(node)

func _mat(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    return material
