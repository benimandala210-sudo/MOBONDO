extends Node
## Besoins vitaux persistants du personnage joueur.
signal needs_updated(hunger: float, thirst: float, energy: float, health: float, hygiene: float)

const SAVE_PATH := "user://mobondo_needs.json"
var hunger := 92.0
var thirst := 90.0
var energy := 88.0
var health := 100.0
var hygiene := 95.0
var save_minutes := 0.0

func _ready() -> void:
    _load_state()
    _emit_update()

func advance(game_minutes: float) -> void:
    if game_minutes <= 0.0:
        return
    hunger = maxf(0.0, hunger - 0.045 * game_minutes)
    thirst = maxf(0.0, thirst - 0.075 * game_minutes)
    energy = maxf(0.0, energy - 0.032 * game_minutes)
    hygiene = maxf(0.0, hygiene - 0.012 * game_minutes)
    if hunger <= 5.0 or thirst <= 5.0:
        health = maxf(0.0, health - 0.035 * game_minutes)
    elif hunger > 35.0 and thirst > 35.0:
        health = minf(100.0, health + 0.004 * game_minutes)
    save_minutes += game_minutes
    if save_minutes >= 10.0:
        save_minutes = 0.0
        save_state()
    _emit_update()

func drink() -> void:
    thirst = minf(100.0, thirst + 42.0)
    _emit_update()

func eat() -> void:
    hunger = minf(100.0, hunger + 38.0)
    energy = minf(100.0, energy + 4.0)
    _emit_update()

func rest() -> void:
    energy = minf(100.0, energy + 18.0)
    health = minf(100.0, health + 2.0)
    _emit_update()

func apply_damage(amount: float) -> void:
    if amount <= 0.0 or health <= 0.0:
        return
    health = maxf(0.0, health - amount)
    save_state()
    _emit_update()

func receive_treatment(amount: float = 40.0) -> void:
    health = minf(100.0, health + maxf(0.0, amount))
    energy = minf(100.0, energy + 5.0)
    _emit_update()

func exercise() -> void:
    energy = maxf(0.0, energy - 12.0)
    health = minf(100.0, health + 3.0)
    hygiene = maxf(0.0, hygiene - 4.0)
    _emit_update()

func meditate() -> void:
    energy = minf(100.0, energy + 15.0)
    _emit_update()

func take_shower() -> void:
    hygiene = minf(100.0, hygiene + 55.0)
    _emit_update()

func sleep(hours: float = 8.0) -> float:
    var duration := clampf(hours, 1.0, 12.0) * 60.0
    # Le personnage continue à avoir faim et soif pendant la nuit,
    # mais récupère son énergie au lieu de la perdre.
    hunger = maxf(0.0, hunger - 0.045 * duration)
    thirst = maxf(0.0, thirst - 0.075 * duration)
    hygiene = maxf(0.0, hygiene - 0.012 * duration)
    energy = minf(100.0, energy + duration * 0.18)
    if hunger <= 5.0 or thirst <= 5.0:
        health = maxf(0.0, health - 0.035 * duration)
    else:
        health = minf(100.0, health + duration * 0.018)
    save_state()
    _emit_update()
    return duration

func get_summary() -> String:
    return "Faim %d%%  •  Soif %d%%  •  Énergie %d%%\nSanté %d%%  •  Hygiène %d%%" % [
        roundi(hunger), roundi(thirst), roundi(energy), roundi(health), roundi(hygiene)
    ]

func save_state() -> void:
    var data := {
        "hunger": hunger,
        "thirst": thirst,
        "energy": energy,
        "health": health,
        "hygiene": hygiene
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("MOBONDO: impossible d'enregistrer les besoins du joueur.")
        return
    file.store_string(JSON.stringify(data))
    file.close()

func _load_state() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    hunger = clampf(float(parsed.get("hunger", hunger)), 0.0, 100.0)
    thirst = clampf(float(parsed.get("thirst", thirst)), 0.0, 100.0)
    energy = clampf(float(parsed.get("energy", energy)), 0.0, 100.0)
    health = clampf(float(parsed.get("health", health)), 0.0, 100.0)
    hygiene = clampf(float(parsed.get("hygiene", hygiene)), 0.0, 100.0)

func _emit_update() -> void:
    needs_updated.emit(hunger, thirst, energy, health, hygiene)
