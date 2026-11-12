extends Node
## Réputation de rue, incidents et pression policière de MOBONDO.
signal reputation_updated(reputation: int, police_heat: int, wanted_level: int, message: String)

const SAVE_PATH := "user://mobondo_reputation.json"
const MAX_REPUTATION := 100
const MAX_POLICE_HEAT := 100
const OFFENSES := {
    "provocation": {"label": "Scandale public", "reputation": 3, "heat": 5, "severity": 1},
    "intimidation": {"label": "Intimidation", "reputation": 5, "heat": 7, "severity": 1},
    "fight": {"label": "Affrontement", "reputation": 7, "heat": 12, "severity": 2},
    "assault": {"label": "Agression", "reputation": 9, "heat": 18, "severity": 3},
    "vehicle_theft": {"label": "Vol de véhicule", "reputation": 10, "heat": 22, "severity": 3},
    "police_attack": {"label": "Affrontement avec la police", "reputation": 12, "heat": 30, "severity": 4}
}

var street_reputation := 10
var police_heat := 0
var wanted_level := 0
var arrest_count := 0
var detention_minutes_remaining := 0
var incident_history: Array[Dictionary] = []
var _decay_accumulator := 0.0

func _ready() -> void:
    _load_state()
    _emit_update("Réputation et surveillance du quartier chargées.")

func record_offense(offense_id: String, witnessed: bool = true) -> bool:
    if not OFFENSES.has(offense_id):
        return false
    var offense: Dictionary = OFFENSES[offense_id]
    var reputation_gain := int(offense["reputation"])
    var heat_gain := int(offense["heat"])
    if not witnessed:
        heat_gain = maxi(1, int(round(heat_gain * 0.35)))
    street_reputation = clampi(street_reputation + reputation_gain, 0, MAX_REPUTATION)
    police_heat = clampi(police_heat + heat_gain, 0, MAX_POLICE_HEAT)
    incident_history.append({
        "id": offense_id,
        "label": str(offense["label"]),
        "witnessed": witnessed,
        "severity": int(offense["severity"])
    })
    if incident_history.size() > 40:
        incident_history.pop_front()
    _refresh_wanted_level()
    _save_state()
    _emit_update("%s signalé. Réputation +%d, pression policière +%d." % [str(offense["label"]), reputation_gain, heat_gain])
    return true

func apply_arrest() -> int:
    if detention_minutes_remaining > 0:
        return detention_minutes_remaining
    arrest_count += 1
    var severity_total := 0
    for incident in incident_history:
        severity_total += int(incident.get("severity", 0))
    detention_minutes_remaining = clampi(30 + police_heat + severity_total * 10, 30, 360)
    police_heat = maxi(15, int(police_heat * 0.45))
    wanted_level = 0
    _save_state()
    _emit_update("Oza mabɔkɔ. Détention prévue : %d minutes de jeu." % detention_minutes_remaining)
    return detention_minutes_remaining

func advance_game_minutes(minutes: float) -> void:
    if minutes <= 0.0:
        return
    if detention_minutes_remaining > 0:
        detention_minutes_remaining = maxi(0, detention_minutes_remaining - int(ceil(minutes)))
        if detention_minutes_remaining == 0:
            incident_history.clear()
            police_heat = maxi(0, int(police_heat * 0.25))
            _emit_update("Libération : ozongi na quartier. La surveillance diminue.")
    else:
        _decay_accumulator += minutes
        var decay_steps := int(_decay_accumulator / 10.0)
        if decay_steps > 0:
            _decay_accumulator = fposmod(_decay_accumulator, 10.0)
            police_heat = maxi(0, police_heat - decay_steps)
            _refresh_wanted_level()
    _save_state()

func get_status_text() -> String:
    if detention_minutes_remaining > 0:
        return "RÉPUTATION %d/100 | EN DÉTENTION : %d min" % [street_reputation, detention_minutes_remaining]
    return "RÉPUTATION %d/100 | POLICE %d/100 | ALERTE %d/5" % [street_reputation, police_heat, wanted_level]

func get_reputation_title() -> String:
    if street_reputation >= 80:
        return "Nom redouté"
    if street_reputation >= 60:
        return "Très connu"
    if street_reputation >= 35:
        return "Respecté / craint"
    if street_reputation >= 15:
        return "Connu du quartier"
    return "Inconnu"

func _refresh_wanted_level() -> void:
    wanted_level = clampi(int(ceil(float(police_heat) / 20.0)), 0, 5)

func _emit_update(message: String) -> void:
    reputation_updated.emit(street_reputation, police_heat, wanted_level, message)

func _save_state() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify({
        "street_reputation": street_reputation,
        "police_heat": police_heat,
        "wanted_level": wanted_level,
        "arrest_count": arrest_count,
        "detention_minutes_remaining": detention_minutes_remaining,
        "incident_history": incident_history
    }))
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
    street_reputation = clampi(int(parsed.get("street_reputation", 10)), 0, MAX_REPUTATION)
    police_heat = clampi(int(parsed.get("police_heat", 0)), 0, MAX_POLICE_HEAT)
    wanted_level = clampi(int(parsed.get("wanted_level", 0)), 0, 5)
    arrest_count = maxi(0, int(parsed.get("arrest_count", 0)))
    detention_minutes_remaining = maxi(0, int(parsed.get("detention_minutes_remaining", 0)))
    var saved_history = parsed.get("incident_history", [])
    incident_history.clear()
    if saved_history is Array:
        for entry in saved_history:
            if entry is Dictionary:
                incident_history.append(entry.duplicate(true))
