extends Node3D
## Modèle de personnage stylisé MOBONDO, construit en volumes articulés légers.
## Les pivots permettent d'ajouter ensuite un squelette/une animation importée sans
## modifier le contrôleur CharacterBody3D.

var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var torso: MeshInstance3D
var gait_time := 0.0

func _ready() -> void:
    _build_character()

func _process(delta: float) -> void:
    var body := get_parent() as CharacterBody3D
    if body == null:
        return
    var horizontal_speed := Vector2(body.velocity.x, body.velocity.z).length()
    if horizontal_speed > 0.25 and body.is_on_floor():
        gait_time += delta * (8.0 if horizontal_speed < 5.0 else 11.0)
        var swing := sin(gait_time) * minf(horizontal_speed / 4.0, 1.0) * 0.62
        left_leg.rotation.x = swing
        right_leg.rotation.x = -swing
        left_arm.rotation.x = -swing * 0.72
        right_arm.rotation.x = swing * 0.72
        torso.position.y = 1.04 + absf(sin(gait_time * 2.0)) * 0.035
    else:
        left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.0, delta * 10.0)
        right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.0, delta * 10.0)
        left_arm.rotation.x = lerpf(left_arm.rotation.x, 0.0, delta * 10.0)
        right_arm.rotation.x = lerpf(right_arm.rotation.x, 0.0, delta * 10.0)
        torso.position.y = lerpf(torso.position.y, 1.04, delta * 8.0)

func _build_character() -> void:
    var skin := _mat(Color(0.31, 0.18, 0.12))
    var shirt := _mat(Color(0.78, 0.72, 0.58))
    var trousers := _mat(Color(0.12, 0.15, 0.19))
    var shoes := _mat(Color(0.055, 0.052, 0.05))
    var hair := _mat(Color(0.045, 0.035, 0.03))

    torso = _capsule("Torse", 0.34, 0.82, shirt, Vector3(0, 1.04, 0))
    _capsule("Bassin", 0.29, 0.34, trousers, Vector3(0, 0.61, 0))
    _capsule("Tête", 0.225, 0.4, skin, Vector3(0, 1.78, 0))
    _sphere("Cheveux", 0.23, hair, Vector3(0, 1.94, 0))
    get_node("Cheveux").scale = Vector3(1.0, 0.42, 1.0)
    _capsule("Cou", 0.105, 0.18, skin, Vector3(0, 1.53, 0))

    # Visage lisible de face : yeux, sourcils, nez, bouche et oreilles.
    var eye_white := _mat(Color(0.91, 0.88, 0.78))
    var eye_dark := _mat(Color(0.035, 0.025, 0.02))
    var face_detail := _mat(Color(0.19, 0.105, 0.075))
    for eye_x in [-0.078, 0.078]:
        _sphere("Blanc oeil", 0.034, eye_white, Vector3(eye_x, 1.81, -0.198))
        _sphere("Pupille", 0.018, eye_dark, Vector3(eye_x, 1.81, -0.226))
        _box_child(self, "Sourcil", Vector3(0.075, 0.018, 0.025), hair, Vector3(eye_x, 1.865, -0.205))
    _sphere("Nez", 0.043, skin, Vector3(0, 1.735, -0.225))
    _box_child(self, "Bouche", Vector3(0.075, 0.018, 0.018), face_detail, Vector3(0, 1.665, -0.216))
    for ear_x in [-0.22, 0.22]:
        _sphere("Oreille", 0.055, skin, Vector3(ear_x, 1.78, 0))

    # Détails du vêtement : col, poche, boutons et ceinture.
    _capsule("Col chemise", 0.12, 0.12, shirt, Vector3(0, 1.43, -0.015))
    _box_child(self, "Poche poitrine", Vector3(0.13, 0.16, 0.025), _mat(Color(0.65, 0.59, 0.47)), Vector3(0.19, 1.16, -0.315))
    for button_index in range(3):
        _sphere("Bouton chemise", 0.018, _mat(Color(0.88, 0.82, 0.68)), Vector3(0, 1.22 - float(button_index) * 0.13, -0.337))
    _box_child(self, "Ceinture", Vector3(0.42, 0.07, 0.31), _mat(Color(0.055, 0.045, 0.035)), Vector3(0, 0.68, -0.01))

    left_arm = _limb_pivot("Bras gauche", Vector3(-0.39, 1.34, 0))
    right_arm = _limb_pivot("Bras droit", Vector3(0.39, 1.34, 0))
    _capsule_child(left_arm, "Manche", 0.12, 0.34, shirt, Vector3(0, -0.12, 0))
    _capsule_child(right_arm, "Manche", 0.12, 0.34, shirt, Vector3(0, -0.12, 0))
    _capsule_child(left_arm, "Avant-bras", 0.095, 0.38, skin, Vector3(0, -0.43, 0))
    _capsule_child(right_arm, "Avant-bras", 0.095, 0.38, skin, Vector3(0, -0.43, 0))
    _sphere_child(left_arm, "Main", 0.105, skin, Vector3(0, -0.67, 0))
    _sphere_child(right_arm, "Main", 0.105, skin, Vector3(0, -0.67, 0))

    left_leg = _limb_pivot("Jambe gauche", Vector3(-0.16, 0.55, 0))
    right_leg = _limb_pivot("Jambe droite", Vector3(0.16, 0.55, 0))
    for pivot in [left_leg, right_leg]:
        _capsule_child(pivot, "Pantalon", 0.14, 0.42, trousers, Vector3(0, -0.16, 0))
        _capsule_child(pivot, "Tibia", 0.105, 0.34, trousers, Vector3(0, -0.43, 0))
        _box_child(pivot, "Chaussure", Vector3(0.23, 0.13, 0.36), shoes, Vector3(0, -0.45, -0.07))
        _box_child(pivot, "Semelle", Vector3(0.24, 0.045, 0.37), _mat(Color(0.018, 0.018, 0.02)), Vector3(0, -0.515, -0.07))

func _limb_pivot(node_name: String, pivot_position: Vector3) -> Node3D:
    var pivot := Node3D.new()
    pivot.name = node_name
    pivot.position = pivot_position
    add_child(pivot)
    return pivot

func _capsule(node_name: String, radius: float, height: float, material: Material, pos: Vector3) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = node_name
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    item.mesh = mesh
    item.position = pos
    item.material_override = material
    add_child(item)
    return item

func _capsule_child(parent: Node3D, node_name: String, radius: float, height: float, material: Material, pos: Vector3) -> void:
    var item := MeshInstance3D.new()
    item.name = node_name
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    item.mesh = mesh
    item.position = pos
    item.material_override = material
    parent.add_child(item)

func _sphere(node_name: String, radius: float, material: Material, pos: Vector3) -> void:
    _sphere_child(self, node_name, radius, material, pos)

func _sphere_child(parent: Node3D, node_name: String, radius: float, material: Material, pos: Vector3) -> void:
    var item := MeshInstance3D.new()
    item.name = node_name
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    item.mesh = mesh
    item.position = pos
    item.material_override = material
    parent.add_child(item)

func _box_child(parent: Node3D, node_name: String, size: Vector3, material: Material, pos: Vector3) -> void:
    var item := MeshInstance3D.new()
    item.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.position = pos
    item.material_override = material
    parent.add_child(item)

func _mat(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.82
    return material
