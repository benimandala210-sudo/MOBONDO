extends Node
## Système de dialogues à choix pour MOBONDO.
## Les textes destinés au joueur sont en lingala.

signal dialogue_updated(speaker: String, text: String, choices: Array)
signal dialogue_closed
signal conversation_finished(character_id: String, choice_id: String)

const SAVE_PATH := "user://mobondo_dialogues.json"

const CONVERSATIONS := {
    "resident_mapela": {
        "speaker": "Mado",
        "opening": "Mbote, moninga! Oyebi quartier oyo malamu?",
        "choices": [
            {
                "id": "ask_neighborhood",
                "text": "Nalingi koyeba quartier.",
                "reply": "Malamu. Oyo ezali Mapela. Soki ozali na posa ya koyeba bisika, tuna bato na limemya. Bato mingi bakoki kosalisa yo.",
                "affinity": 2,
                "flag": "knows_mapela"
            },
            {
                "id": "ask_work",
                "text": "Oyebi mosala moko ya kosala?",
                "reply": "Nayoki ete bato bazali koluka moto ya kosalisa na zando. Kende kotala kuna, mpe solola na bateki.",
                "affinity": 1,
                "flag": "heard_market_work"
            },
            {
                "id": "greet_only",
                "text": "Nayei kaka kopesa mbote.",
                "reply": "Matondo, moninga. Mbote na yo epesi ngai esengo. Tokomonana lisusu!",
                "affinity": 1,
                "flag": "greeted_mado"
            }
        ]
    }
}

var active_character_id: String = ""
var active_speaker: String = ""
var active_choices: Array = []
var relationship_scores: Dictionary = {}
var story_flags: Array[String] = []
var dialogue_history: Array[String] = []
var waiting_for_close: bool = false

func _ready() -> void:
    _load_state()

func start_dialogue(character_id: String) -> bool:
    if waiting_for_close:
        return false
    if not CONVERSATIONS.has(character_id):
        return false

    active_character_id = character_id
    var conversation: Dictionary = CONVERSATIONS[character_id]
    active_speaker = str(conversation.get("speaker", ""))
    active_choices = conversation.get("choices", []).duplicate(true)
    waiting_for_close = false
    dialogue_updated.emit(active_speaker, str(conversation.get("opening", "")), active_choices)
    return true

func choose_option(index: int) -> bool:
    if active_character_id.is_empty() or waiting_for_close:
        return false
    if index < 0 or index >= active_choices.size():
        return false

    var choice: Dictionary = active_choices[index]
    var choice_id := str(choice.get("id", ""))
    var affinity := int(choice.get("affinity", 0))
    relationship_scores[active_character_id] = int(relationship_scores.get(active_character_id, 0)) + affinity

    var flag := str(choice.get("flag", ""))
    if not flag.is_empty() and not story_flags.has(flag):
        story_flags.append(flag)

    dialogue_history.append(active_character_id + ":" + choice_id)
    _save_state()

    waiting_for_close = true
    dialogue_updated.emit(
        active_speaker,
        str(choice.get("reply", "")),
        [{"id": "close", "text": "Tokende"}]
    )
    return true

func close_dialogue() -> void:
    if active_character_id.is_empty():
        return
    var character_id := active_character_id
    var last_choice_id := ""
    if not dialogue_history.is_empty():
        var last_entry := dialogue_history[dialogue_history.size() - 1]
        if last_entry.begins_with(character_id + ":"):
            last_choice_id = last_entry.get_slice(":", 1)

    active_character_id = ""
    active_speaker = ""
    active_choices.clear()
    waiting_for_close = false
    dialogue_closed.emit()
    conversation_finished.emit(character_id, last_choice_id)

func get_relationship_score(character_id: String) -> int:
    return int(relationship_scores.get(character_id, 0))

func has_story_flag(flag: String) -> bool:
    return story_flags.has(flag)

func _save_state() -> void:
    var data := {
        "relationship_scores": relationship_scores,
        "story_flags": story_flags,
        "dialogue_history": dialogue_history
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
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

    var scores = parsed.get("relationship_scores", {})
    if scores is Dictionary:
        relationship_scores = scores
    var flags = parsed.get("story_flags", [])
    story_flags.clear()
    if flags is Array:
        for flag in flags:
            if typeof(flag) == TYPE_STRING and not story_flags.has(flag):
                story_flags.append(flag)
    var history = parsed.get("dialogue_history", [])
    dialogue_history.clear()
    if history is Array:
        for entry in history:
            if typeof(entry) == TYPE_STRING:
                dialogue_history.append(entry)
