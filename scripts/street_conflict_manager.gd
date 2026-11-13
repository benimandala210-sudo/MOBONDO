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
var weapon_order := ["machette", "pierre", "lame"]
var selected_weapon := "machette"
var stones_remaining := 8
var weapon_specs := {
    "machette": {"label": "MACHETTE", "range": 2.7, "damage": 2, "cooldown": 0.9},
    "pierre": {"label": "PIERRE", "range": 8.0, "damage": 1, "cooldown": 1.25},
    "lame": {"label": "GILETTE", "range": 1.8, "damage": 1, "cooldown": 0.65}
}

func configure(player_node: Node3D, needs_node, reputation_node) -> void:
    player = player_node
    needs_manager = needs_node
    reputation_manager = reputation_node

func create_rival(rival_name: String, spawn: Vector3, shirt_color: Color, group_id: String = "groupe_mapela") -> Node3D:
    var rival := Node3D.new()
    rival.name = rival_name
    rival.position = spawn
    rival.set_meta("health", 3)
    rival.set_meta("state", "idle")
    rival.set_meta("group_id", group_id)
    rival.set_meta("group_alerted", false)
    rival.set_meta("alert_time", 0.0)
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

func cycle_weapon() -> String:
    var index := weapon_order.find(selected_weapon)
    index = (index + 1) % weapon_order.size()
    selected_weapon = weapon_order[index]
    conflict_message.emit("Arme sélectionnée : " + get_weapon_label())
    return get_weapon_label()

func get_weapon_label() -> String:
    var spec: Dictionary = weapon_specs.get(selected_weapon, weapon_specs["machette"])
    if selected_weapon == "pierre":
        return "%s (%d)" % [str(spec["label"]), stones_remaining]
    return str(spec["label"])

func get_weapon_range() -> float:
    var spec: Dictionary = weapon_specs.get(selected_weapon, weapon_specs["machette"])
    return float(spec["range"])

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
    if selected_weapon == "pierre" and stones_remaining <= 0:
        conflict_message.emit("Ozali lisusu na mabanga te.")
        return false
    var spec: Dictionary = weapon_specs.get(selected_weapon, weapon_specs["machette"])
    var target: Node3D = null
    var nearest := float(spec["range"])
    for rival in rivals:
        if not is_instance_valid(rival) or not rival.visible:
            continue
        var distance := _distance_to_player(rival)
        if distance <= nearest:
            nearest = distance
            target = rival
    if not is_instance_valid(target):
        conflict_message.emit("Rival azali mosika mpo na " + get_weapon_label() + ".")
        return false
    player_cooldown = float(spec["cooldown"])
    if selected_weapon == "pierre":
        stones_remaining -= 1
    _alert_group(str(target.get_meta("group_id", "groupe_mapela")))
    var remaining := maxi(0, int(target.get_meta("health", 3)) - int(spec["damage"]))
    target.set_meta("health", remaining)
    if remaining <= 0:
        target.visible = false
        target.queue_free()
        if is_instance_valid(reputation_manager):
            reputation_manager.record_offense("fight", true)
        conflict_message.emit("Rival neutralisé. Bato ya quartier bamoni mobulu.")
    else:
        conflict_message.emit("%s utilisé. État du rival : %d/3." % [get_weapon_label(), remaining])
    return true

func _alert_group(group_id: String) -> void:
    for rival in rivals:
        if not is_instance_valid(rival) or not rival.visible:
            continue
        if str(rival.get_meta("group_id", "")) == group_id:
            rival.set_meta("group_alerted", true)
            rival.set_meta("alert_time", 15.0)
            rival.set_meta("state", "alerted")
    conflict_message.emit("Groupe rival alerte : ses compagnons arrivent.")

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
        var alert_time := maxf(0.0, float(rival.get_meta("alert_time", 0.0)) - delta)
        rival.set_meta("alert_time", alert_time)
        var alerted := bool(rival.get_meta("group_alerted", false))
        if not alerted and distance <= 3.5:
            _alert_group(str(rival.get_meta("group_id", "groupe_mapela")))
            alerted = true
            alert_time = 15.0
        if alerted and (alert_time <= 0.0 or distance > 18.0):
            rival.set_meta("group_alerted", false)
            rival.set_meta("state", "idle")
            alerted = false
        if alerted and distance > 1.45 and distance <= 18.0:
            var destination := Vector3(player.global_position.x, rival.global_position.y, player.global_position.z)
            rival.global_position = rival.global_position.move_toward(destination, 1.8 * delta)
            var direction := destination - rival.global_position
            if Vector2(direction.x, direction.z).length() > 0.05:
                rival.rotation.y = atan2(-direction.x, -direction.z)
            rival.set_meta("state", "approach")
        elif alerted and distance <= 1.45 and cooldown <= 0.0:
            rival_cooldowns[key] = 2.1
            needs_manager.apply_damage(8.0)
            conflict_message.emit("%s t'a frappé. Santé diminuée." % rival.name)
        elif not alerted:
            rival.set_meta("state", "idle")

func _distance_to_player(rival: Node3D) -> float:
    return Vector2(rival.global_position.x - player.global_position.x, rival.global_position.z - player.global_position.z).length()
