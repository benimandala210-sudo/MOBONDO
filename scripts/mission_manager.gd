extends Node
## Gestion centralisée des épisodes, objectifs et issues terminales de MOBONDO.
## Godot 4.2.2 — une mission ne peut se terminer qu'une seule fois.

signal mission_updated(title: String, objective: String, objective_id: String, index: int, total: int)
signal mission_completed(episode_title: String)
signal mission_failed(reason: String)
signal mission_message(message: String)
signal mission_ended(outcome: String, episode_title: String, reason: String, reward: int)
signal mission_restarted(episode_title: String)

const SAVE_PATH := "user://mobondo_missions.json"
const STATE_ACTIVE := "active"
const STATE_VICTORY := "victory"
const STATE_ARRESTED := "arrested"
const STATE_DEAD := "dead"

const BASE_EPISODE_REWARD := 1000
const OPTIONAL_OBJECTIVE_REWARD := 250

const EPISODES := [
    {
        "id": "S1E01",
        "title": "Ebandeli",
        "subtitle": "Les premiers pas",
        "description": "Koyeba Mapela mpe bato ya quartier.",
        "available": true,
        "objectives": [
            {"id": "reach_market", "title": "Kende na zando", "description": "Kende pene ya zando ya Mapela.", "optional": false},
            {"id": "talk_resident", "title": "Solola na moto ya quartier", "description": "Pusana pene ya moto ya quartier mpe solola na ye.", "optional": false},
            {"id": "collect_parcel", "title": "Kamata colis", "description": "Kende kozwa colis oyo batikelaki yo.", "optional": false}
        ]
    },
    {"id": "S1E02", "title": "Kobika mokolo na mokolo", "subtitle": "Survivre au quotidien", "available": false, "objectives": []},
    {"id": "S1E03", "title": "Bato oyo tokutanaka na bango", "subtitle": "Les fréquentations", "available": false, "objectives": []},
    {"id": "S1E04", "title": "Boyokani", "subtitle": "Les alliances", "available": false, "objectives": []},
    {"id": "S1E05", "title": "Mikakatano", "subtitle": "La pression", "available": false, "objectives": []},
    {"id": "S1E06", "title": "Libaku ya sika", "subtitle": "Une nouvelle opportunité", "available": false, "objectives": []},
    {"id": "S1E07", "title": "Ntalo ya mikano", "subtitle": "Le prix des décisions", "available": false, "objectives": []},
    {"id": "S1E08", "title": "Mbongwana", "subtitle": "Le tournant", "available": false, "objectives": []}
]

var current_episode_index: int = 0
var objective_index: int = 0
var completed_episode_ids: Array[String] = []
var unlocked_episode_ids: Array[String] = ["S1E01"]
var completed_optional_objective_ids: Array[String] = []
var episode_failed: bool = false
var mission_state: String = STATE_ACTIVE
var last_outcome: String = ""
var last_failure_reason: String = ""

func _ready() -> void:
    _load_progress()
    _emit_current_mission()

func is_mission_active() -> bool:
    return mission_state == STATE_ACTIVE and not is_current_episode_completed()

func get_mission_state() -> String:
    return mission_state

func get_current_episode() -> Dictionary:
    if current_episode_index < 0 or current_episode_index >= EPISODES.size():
        return {}
    return EPISODES[current_episode_index]

func _get_required_objectives() -> Array:
    var required: Array = []
    for objective in get_current_episode().get("objectives", []):
        if not bool(objective.get("optional", false)):
            required.append(objective)
    return required

func get_optional_objectives() -> Array:
    var remaining: Array = []
    for objective in get_current_episode().get("objectives", []):
        var objective_id := str(objective.get("id", ""))
        if bool(objective.get("optional", false)) and not completed_optional_objective_ids.has(objective_id):
            remaining.append(objective)
    return remaining

func complete_optional_objective(objective_id: String) -> bool:
    if not is_mission_active():
        return false
    for objective in get_current_episode().get("objectives", []):
        if str(objective.get("id", "")) == objective_id and bool(objective.get("optional", false)):
            if completed_optional_objective_ids.has(objective_id):
                return false
            completed_optional_objective_ids.append(objective_id)
            _save_progress()
            mission_message.emit("Malamu! Osilisi mokano ya kobakisa.")
            return true
    return false

func is_episode_unlocked(episode_id: String) -> bool:
    return unlocked_episode_ids.has(episode_id)

func get_current_objective() -> Dictionary:
    var objectives := _get_required_objectives()
    if objective_index < 0 or objective_index >= objectives.size():
        return {}
    return objectives[objective_index]

func get_current_objective_index() -> int:
    var objectives := _get_required_objectives()
    if objectives.is_empty():
        return 0
    return mini(objective_index + 1, objectives.size())

func get_current_objective_total() -> int:
    return _get_required_objectives().size()

func get_current_objective_id() -> String:
    return str(get_current_objective().get("id", ""))

func get_mission_title() -> String:
    var episode := get_current_episode()
    if episode.is_empty():
        return "MOBONDO"
    return "MOBONDO · Eteni ya %d · %s" % [current_episode_index + 1, str(episode.get("title", "Mission"))]

func get_objective_text() -> String:
    if mission_state == STATE_ARRESTED:
        return "MISSION TERMINÉE — ARRESTATION"
    if mission_state == STATE_DEAD:
        return "MISSION TERMINÉE — JOUEUR TUÉ"
    if mission_state == STATE_VICTORY:
        return "MISSION ACCOMPLIE — ÉPISODE VALIDÉ"
    var objective := get_current_objective()
    if objective.is_empty():
        if is_current_episode_completed():
            return "Eteni oyo esili. Oyo ekolanda ebongisami naino te."
        return "Mission oyo ebongisami naino te."
    return str(objective.get("title", "")) + "\n" + str(objective.get("description", ""))

func is_current_episode_completed() -> bool:
    var episode := get_current_episode()
    return not episode.is_empty() and completed_episode_ids.has(str(episode.get("id", "")))

func is_campaign_complete() -> bool:
    return completed_episode_ids.size() >= EPISODES.size()

func get_current_episode_id() -> String:
    return str(get_current_episode().get("id", ""))

func get_completed_optional_count() -> int:
    var count := 0
    for objective in get_current_episode().get("objectives", []):
        if bool(objective.get("optional", false)) and completed_optional_objective_ids.has(str(objective.get("id", ""))):
            count += 1
    return count

func get_episode_reward() -> int:
    return BASE_EPISODE_REWARD + get_completed_optional_count() * OPTIONAL_OBJECTIVE_REWARD

func complete_objective(objective_id: String) -> bool:
    if not is_mission_active():
        return false
    var objective := get_current_objective()
    if objective.is_empty() or str(objective.get("id", "")) != objective_id:
        return false

    objective_index += 1
    var objectives := _get_required_objectives()
    if objective_index >= objectives.size():
        _finish_victory()
        return true

    _save_progress()
    _emit_current_mission()
    return true

func _finish_victory() -> void:
    if not is_mission_active():
        return
    var episode := get_current_episode()
    var episode_id := str(episode.get("id", ""))
    var episode_title := str(episode.get("title", "Mission"))
    var reward := get_episode_reward()
    mission_state = STATE_VICTORY
    last_outcome = STATE_VICTORY
    last_failure_reason = ""
    if not completed_episode_ids.has(episode_id):
        completed_episode_ids.append(episode_id)
    if current_episode_index + 1 < EPISODES.size():
        var next_episode_id := str(EPISODES[current_episode_index + 1].get("id", ""))
        if not unlocked_episode_ids.has(next_episode_id):
            unlocked_episode_ids.append(next_episode_id)
    _save_progress()
    mission_completed.emit(episode_title)
    mission_ended.emit(STATE_VICTORY, episode_title, "Objectif principal accompli.", reward)
    mission_message.emit("Malamu! Osilisi eteni oyo.")
    _emit_current_mission()

func fail_episode(reason: String, outcome: String = STATE_ARRESTED) -> bool:
    if not is_mission_active():
        return false
    if outcome != STATE_ARRESTED and outcome != STATE_DEAD:
        push_warning("MOBONDO: issue d'échec inconnue : " + outcome)
        return false
    var episode_title := str(get_current_episode().get("title", "Mission"))
    mission_state = outcome
    episode_failed = true
    last_outcome = outcome
    last_failure_reason = reason
    _save_progress()
    mission_failed.emit(reason)
    mission_ended.emit(outcome, episode_title, reason, 0)
    mission_message.emit("Mission elongi te. Eteni ekobanda lisusu.")
    _emit_current_mission()
    return true

func restart_episode() -> bool:
    if mission_state != STATE_ARRESTED and mission_state != STATE_DEAD and not episode_failed:
        return false
    var episode := get_current_episode()
    var episode_title := str(episode.get("title", "Mission"))
    objective_index = 0
    episode_failed = false
    mission_state = STATE_ACTIVE
    last_outcome = ""
    last_failure_reason = ""
    for objective in episode.get("objectives", []):
        if bool(objective.get("optional", false)):
            completed_optional_objective_ids.erase(str(objective.get("id", "")))
    _save_progress()
    mission_restarted.emit(episode_title)
    _emit_current_mission()
    return true

func start_next_episode() -> bool:
    if mission_state != STATE_VICTORY:
        return false
    if current_episode_index + 1 >= EPISODES.size():
        return false
    var next_index := current_episode_index + 1
    var next_id := str(EPISODES[next_index].get("id", ""))
    if not unlocked_episode_ids.has(next_id):
        return false
    current_episode_index = next_index
    objective_index = 0
    episode_failed = false
    mission_state = STATE_ACTIVE
    last_outcome = ""
    last_failure_reason = ""
    _save_progress()
    _emit_current_mission()
    return true

func _emit_current_mission() -> void:
    var episode := get_current_episode()
    if episode.is_empty():
        mission_updated.emit("MOBONDO", "Mission ezali te.", "", 0, 0)
        return
    var objectives := _get_required_objectives()
    if mission_state != STATE_ACTIVE or objectives.is_empty() or is_current_episode_completed():
        mission_updated.emit(get_mission_title(), get_objective_text(), "", 0, objectives.size())
        return
    var objective := get_current_objective()
    mission_updated.emit(
        get_mission_title(),
        get_objective_text(),
        str(objective.get("id", "")),
        objective_index + 1,
        objectives.size()
    )

func _save_progress() -> void:
    var data := {
        "current_episode_index": current_episode_index,
        "objective_index": objective_index,
        "completed_episode_ids": completed_episode_ids,
        "unlocked_episode_ids": unlocked_episode_ids,
        "completed_optional_objective_ids": completed_optional_objective_ids,
        "mission_state": mission_state,
        "last_outcome": last_outcome,
        "last_failure_reason": last_failure_reason
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))
        file.close()

func _load_progress() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return

    current_episode_index = clampi(int(parsed.get("current_episode_index", 0)), 0, EPISODES.size() - 1)
    var raw_completed = parsed.get("completed_episode_ids", [])
    completed_episode_ids.clear()
    if raw_completed is Array:
        for episode_id in raw_completed:
            if typeof(episode_id) == TYPE_STRING and not completed_episode_ids.has(episode_id):
                completed_episode_ids.append(episode_id)

    var raw_unlocked = parsed.get("unlocked_episode_ids", ["S1E01"])
    unlocked_episode_ids.clear()
    if raw_unlocked is Array:
        for episode_id in raw_unlocked:
            if typeof(episode_id) == TYPE_STRING and not unlocked_episode_ids.has(episode_id):
                unlocked_episode_ids.append(episode_id)
    if not unlocked_episode_ids.has("S1E01"):
        unlocked_episode_ids.append("S1E01")

    var raw_optional = parsed.get("completed_optional_objective_ids", [])
    completed_optional_objective_ids.clear()
    if raw_optional is Array:
        for objective_id in raw_optional:
            if typeof(objective_id) == TYPE_STRING and not completed_optional_objective_ids.has(objective_id):
                completed_optional_objective_ids.append(objective_id)

    var objectives := _get_required_objectives()
    objective_index = clampi(int(parsed.get("objective_index", 0)), 0, objectives.size())
    mission_state = str(parsed.get("mission_state", STATE_ACTIVE))
    if mission_state not in [STATE_ACTIVE, STATE_VICTORY, STATE_ARRESTED, STATE_DEAD]:
        mission_state = STATE_ACTIVE
    last_outcome = str(parsed.get("last_outcome", ""))
    last_failure_reason = str(parsed.get("last_failure_reason", ""))
    episode_failed = mission_state == STATE_ARRESTED or mission_state == STATE_DEAD
    if is_current_episode_completed():
        mission_state = STATE_VICTORY
