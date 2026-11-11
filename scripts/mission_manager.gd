extends Node
## Gestion centralisée des épisodes et objectifs de MOBONDO.
## Compatible Godot 4.2.2.

signal mission_updated(title: String, objective: String, objective_id: String, index: int, total: int)
signal mission_completed(episode_title: String)
signal mission_failed(reason: String)
signal mission_message(message: String)

const SAVE_PATH := "user://mobondo_missions.json"

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
var episode_failed: bool = false

func _ready() -> void:
    _load_progress()
    _emit_current_mission()

func get_current_episode() -> Dictionary:
    if current_episode_index < 0 or current_episode_index >= EPISODES.size():
        return {}
    return EPISODES[current_episode_index]

func get_current_objective() -> Dictionary:
    var episode := get_current_episode()
    var objectives: Array = episode.get("objectives", [])
    if objective_index < 0 or objective_index >= objectives.size():
        return {}
    return objectives[objective_index]

func get_current_objective_id() -> String:
    return str(get_current_objective().get("id", ""))

func get_mission_title() -> String:
    var episode := get_current_episode()
    if episode.is_empty():
        return "MOBONDO"
    return "SAISON 1 · " + str(episode.get("title", "Mission"))

func get_objective_text() -> String:
    var objective := get_current_objective()
    if objective.is_empty():
        if is_current_episode_completed():
            return "Episodi esili. Episodi oyo ekolanda ezali naino na préparation."
        return "Mission oyo ezali naino na préparation."
    return str(objective.get("title", "")) + "\n" + str(objective.get("description", ""))

func is_current_episode_completed() -> bool:
    var episode := get_current_episode()
    return not episode.is_empty() and completed_episode_ids.has(str(episode.get("id", "")))

func is_campaign_complete() -> bool:
    return completed_episode_ids.size() >= EPISODES.size()

func complete_objective(objective_id: String) -> bool:
    if episode_failed or is_current_episode_completed():
        return false
    var objective := get_current_objective()
    if objective.is_empty() or str(objective.get("id", "")) != objective_id:
        return false

    objective_index += 1
    var episode := get_current_episode()
    var objectives: Array = episode.get("objectives", [])
    if objective_index >= objectives.size():
        var episode_id := str(episode.get("id", ""))
        if not completed_episode_ids.has(episode_id):
            completed_episode_ids.append(episode_id)
        _save_progress()
        mission_completed.emit(str(episode.get("title", "Mission")))
        mission_message.emit("Malamu! Osilisi épisode oyo.")
        _emit_current_mission()
        return true

    _save_progress()
    _emit_current_mission()
    return true

func fail_episode(reason: String) -> void:
    if is_current_episode_completed():
        return
    episode_failed = true
    mission_failed.emit(reason)
    mission_message.emit("Mission elongi te. Tokobanda lisusu épisode oyo.")
    restart_episode()

func restart_episode() -> void:
    objective_index = 0
    episode_failed = false
    _save_progress()
    _emit_current_mission()

func _emit_current_mission() -> void:
    var episode := get_current_episode()
    if episode.is_empty():
        mission_updated.emit("MOBONDO", "Aucune mission disponible.", "", 0, 0)
        return
    var objectives: Array = episode.get("objectives", [])
    if objectives.is_empty() or is_current_episode_completed():
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
        "completed_episode_ids": completed_episode_ids
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

    var objectives: Array = EPISODES[current_episode_index].get("objectives", [])
    objective_index = clampi(int(parsed.get("objective_index", 0)), 0, objectives.size())
