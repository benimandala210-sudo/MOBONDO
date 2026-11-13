extends Node
## Affrontements de rue non graphiques : détection, coups, dégâts et conséquences.
signal conflict_message(message: String)

var player: Node3D
var needs_manager
var reputation_manager
var active := false
var player_cooldown := 0.0
var rivals: Array[Node3D] = []
var rival_cooldowns: Dictionary = {}

func configure(player_node: Node3D, needs_node, reputation_node) -> void:
    player = player_node
    needs_manager = needs_node
    reputation_manager = reputation_node

func create_rival(rival_name: String, spawn: Vector3, shirt_color: Color) -> Node3D:
    var rival := Node3D.new()
    rival.name = rival_name
    rival.position = spawn
    rival.set_meta("health", 3)
    rival.set_meta("state", "idle")
    var shirt := StandardMaterial3D.new()
    shirt.albedo_color = shirt_color
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color(0.30, 0.17, 0.11)
    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color(0.08, 0.075, 0.07)

    var torso := MeshInstance3D.new()
    var torso_mesh := CapsuleMesh.new()
    torso_mesh.radius = 0.29
    torso_mesh.height = 0.95
    torso.mesh = torso_mesh
    torso.position.y = 1.0
    torso.material_override = shirt
    rival.add_child(torso)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.21
    head_mesh.height = 0.42
    head.mesh = head_mesh
    head.position.y = 1.67
    head.material_override = skin
    rival.add_child(head)

    for side in [-1.0, 1.0]:
        var leg := MeshInstance3D.new()
        var leg_mesh := CapsuleMesh.new()
        leg_mesh.radius = 0.11
        leg_mesh.height = 0.68
        leg.mesh = leg_mesh
        leg.position = Vector3(side * 0.14, 0.36, 0.0)
        leg.material_override = dark
        rival.add_child(leg)
        var arm := MeshInstance3D.new()
        var arm_mesh := CapsuleMesh.new()
        arm_mesh.radius = 0.10
        arm_mesh.height = 0.64
        arm.mesh = arm_mesh
        arm.position = Vector3(side * 0.36, 1.0, 0.0)
        arm.material_override = shirt
        rival.add_child(arm)

    add_child(rival)
    rivals.append(rival)
    rival_cooldowns[rival.get_instance_id()] = 0.8
    return rival

func set_active(value: bool) -> void:
    active = value

func get_nearest_rival_distance() -> float:
    if not is_instance_valid(player):
        return 9999.0
    var nearest := 9999.0
    for rival in rivals:
        if is_instance_valid(rival) and rival.visible:
            nearest = minf(nearest, _distance_to_player(rival))
    return nearest

func player_attack() -> bool:
    if not active or not is_instance_valid(player) or not is_instance_valid(needs_manager):
        return false
    if player_cooldown > 0.0:
        return false
    var target: Node3D = null
    var nearest := 2.45
    for rival in rivals:
        if not is_instance_valid(rival) or not rival.visible:
            continue
        var distance := _distance_to_player(rival)
        if distance < nearest:
            nearest = distance
            target = rival
    if not is_instance_valid(target):
        conflict_message.emit("Pusana penepene ya rival mpo na kobunda.")
        return false
    player_cooldown = 0.72
    var remaining := maxi(0, int(target.get_meta("health", 3)) - 1)
    target.set_meta("health", remaining)
    if remaining <= 0:
        target.visible = false
        target.queue_free()
        if is_instance_valid(reputation_manager):
            reputation_manager.record_offense("fight", true)
        conflict_message.emit("Rival akwei na mabele. Bato ya quartier bamoni mobulu.")
    else:
        conflict_message.emit("Obeti rival. Makasi na ye etikali %d/3." % remaining)
    return true

func _process(delta: float) -> void:
    if player_cooldown > 0.0:
        player_cooldown = maxf(0.0, player_cooldown - delta)
    if not active or not is_instance_valid(player) or not player.visible:
        return
    for i in range(rivals.size() - 1, -1, -1):
        var rival := rivals[i]
        if not is_instance_valid(rival):
            rivals.remove_at(i)
            continue
        var key := rival.get_instance_id()
        var cooldown := maxf(0.0, float(rival_cooldowns.get(key, 0.0)) - delta)
        rival_cooldowns[key] = cooldown
        var distance := _distance_to_player(rival)
        if distance <= 8.0 and distance > 1.45:
            var destination := Vector3(player.global_position.x, rival.global_position.y, player.global_position.z)
            rival.global_position = rival.global_position.move_toward(destination, 1.65 * delta)
            var direction := destination - rival.global_position
            if Vector2(direction.x, direction.z).length() > 0.05:
                rival.rotation.y = atan2(-direction.x, -direction.z)
            rival.set_meta("state", "approach")
        elif distance <= 1.45 and cooldown <= 0.0:
            rival_cooldowns[key] = 2.1
            needs_manager.apply_damage(8.0)
            conflict_message.emit("%s t'a frappé. Santé diminuée." % rival.name)
        elif distance > 8.0:
            rival.set_meta("state", "idle")

func _distance_to_player(rival: Node3D) -> float:
    return Vector2(rival.global_position.x - player.global_position.x, rival.global_position.z - player.global_position.z).length()
