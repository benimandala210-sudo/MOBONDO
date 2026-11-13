extends Node
## Système de dialogues à choix pour MOBONDO.
## Les textes destinés au joueur sont en lingala.

signal dialogue_updated(speaker: String, text: String, choices: Array)
signal dialogue_closed
signal conversation_finished(character_id: String, choice_id: String)

const SAVE_PATH := "user://mobondo_dialogues.json"

const CONVERSATIONS := {
    "seller_market": {
        "speaker": "Mama Sifa — moteki ya zando",
        "opening": "Mbote ndeko! Ozali koluka nini awa na zando?",
        "choices": [
            {"id": "ask_market_goods", "text": "Nalingi kotala biloko oyo ozali koteka.", "reply": "Nazali na biloko ya kolia mpe mwa biloko ya ndako. Tala malamu, soki olingi eloko moko loba na ngai.", "affinity": 1, "flag": "met_market_seller"},
            {"id": "ask_market_job", "text": "Mosala ezali awa na zando?", "reply": "Na ntango mosusu tozalaka na besoin ya lisalisi. Yaka lisusu tongo, okoki kokuta chance.", "affinity": 2, "flag": "heard_seller_job"}
        ]
    },
    "customer_market": {
        "speaker": "Junior — mosombi",
        "opening": "Yo ndeko! Zando etondi lelo, bato bazali kosomba mingi.",
        "choices": [
            {"id": "ask_market_day", "text": "Zando ezalaka boye mikolo nyonso?", "reply": "Mingi ya mikolo ezalaka na mouvement, kasi na mikolo mosusu bato bazalaka mingi koleka.", "affinity": 1, "flag": "knows_market_rhythm"},
            {"id": "say_goodbye", "text": "Malamu, tokutana.", "reply": "Tokutana ndeko, kende malamu!", "affinity": 1, "flag": "greeted_junior"}
        ]
    },
    "resident_mapela": {
        "speaker": "Mado",
        "opening": "Mbote, ndeko! Oyebi quartier oyo malamu to ozali naino mopaya?",
        "choices": [
            {
                "id": "ask_neighborhood",
                "text": "Nalingi koyeba quartier malamu.",
                "reply": "Ah, ozali malamu! Oyo nde Mapela. Soki olingi koyeba ba coins ya quartier, tuna ba ndeko. Bato ya awa bakoki ko lakisa yo.",
                "affinity": 2,
                "flag": "knows_mapela"
            },
            {
                "id": "ask_work",
                "text": "Yango, oyebi mwa plan ya mosala?",
                "reply": "Nayoki na zando bazali na besoin ya mutu ya kosalisa. Kende ko check kuna, solola na ba vendeurs. Peut-être okokuta mwa chance.",
                "affinity": 1,
                "flag": "heard_market_work"
            },
            {
                "id": "greet_only",
                "text": "Nayei kaka ko pesa mbote, ndeko.",
                "reply": "Merci mingi, ndeko! Mbote ezali kitoko. Tokomonana lisusu, tika te!",
                "affinity": 1,
                "flag": "greeted_mado"
            }
        ]
    }
,
    "passer_1": {
        "speaker": "Patrick — passant",
        "opening": "Mbote ndeko! Nazali kokende na mosala. Quartier ezali kolamuka.",
        "choices": [
            {"id": "ask_route", "text": "Nzela nini ekendaka na zando?", "reply": "Kende liboso, na sima landa nzela ya kati. Soki obungi, tuna bato ya quartier.", "affinity": 1, "flag": "knows_market_route"},
            {"id": "wish_good_day", "text": "Mosala malamu, ndeko!", "reply": "Matondo! Yo mpe mokolo malamu.", "affinity": 1, "flag": "greeted_patrick"}
        ]
    },
    "passer_2": {
        "speaker": "David — mwana quartier",
        "opening": "Eh ndeko, mbote! Ozali moto ya sika awa?",
        "choices": [
            {"id": "ask_neighborhood_news", "text": "Nini ezali koleka na quartier?", "reply": "Lelo bato bazali mingi na zando. Na sima ya midi, okoki kokuta bato mingi na libanda.", "affinity": 1, "flag": "heard_neighborhood_news"},
            {"id": "greet_david", "text": "Nasepeli komona yo.", "reply": "Ngai mpe ndeko. Tokutana lisusu!", "affinity": 1, "flag": "greeted_david"}
        ]
    },
    "passer_3": {
        "speaker": "Alain — passant",
        "opening": "Mbote! Ozali kotambola kaka to ozali koluka esika moko?",
        "choices": [
            {"id": "ask_local_places", "text": "Esika ya kopema ezali wapi?", "reply": "Okoki kopema pembeni ya bandako. Kasi tika nzela polele mpo na bato nyonso.", "affinity": 1, "flag": "knows_rest_spots"},
            {"id": "say_hello_alain", "text": "Nazali kaka kotala quartier.", "reply": "Kitoko! Kotambola esalisaka mpo oyeba esika ofandi.", "affinity": 1, "flag": "greeted_alain"}
        ]
    },
    "resident_1": {
        "speaker": "Papa Kanku — mofandi ya Mapela",
        "opening": "Mbote mwana na ngai. Esengo komona yo na quartier.",
        "choices": [
            {"id": "ask_life", "text": "Bomoi ezali ndenge nini awa?", "reply": "Bomoi ezali kosenga kosala makasi. Bato basalisanaka, yango nde esalisaka quartier ekola.", "affinity": 2, "flag": "learned_community"},
            {"id": "offer_help", "text": "Soki ozali na posa ya lisalisi, loba na ngai.", "reply": "Matondo mingi. Kobatela boyokani na bato ezali na motuya.", "affinity": 2, "flag": "offered_help_kanku"}
        ]
    },
    "resident_2": {
        "speaker": "Mama Nzambe — mofandi ya quartier",
        "opening": "Mbote ndeko! Ozali komona ndenge quartier ezali na bomoi?",
        "choices": [
            {"id": "ask_needs", "text": "Bato ya quartier bazali na posa ya nini?", "reply": "Bato bazali na posa ya misala, kimia mpe nzela ya malamu. Moto na moto akoki kopesa maboko.", "affinity": 2, "flag": "learned_neighborhood_needs"},
            {"id": "greet_mama", "text": "Nayei kopesa yo mbote.", "reply": "Yambá mbote na ngai mpe. Nzambe apambola mokolo na yo.", "affinity": 1, "flag": "greeted_mama_nzambe"}
        ]
    }

}

var active_character_id: String = ""
var active_speaker: String = ""
var active_choices: Array = []
var relationship_scores: Dictionary = {}
var story_flags: Array[String] = []
var dialogue_history: Array[String] = []
var npc_memories: Dictionary = {}
var waiting_for_close: bool = false

func _ready() -> void:
    _load_state()

func start_dialogue(character_id: String, opening_override: String = "") -> bool:
    if waiting_for_close:
        return false
    if not CONVERSATIONS.has(character_id):
        return false
    if not can_talk_to(character_id):
        return false

    active_character_id = character_id
    var conversation: Dictionary = CONVERSATIONS[character_id]
    active_speaker = str(conversation.get("speaker", ""))
    active_choices = conversation.get("choices", []).duplicate(true)
    waiting_for_close = false
    var opening := str(conversation.get("opening", "")) if opening_override.is_empty() else opening_override
    if opening_override.is_empty():
        opening = get_social_opening(character_id, opening)
    dialogue_updated.emit(active_speaker, opening, active_choices)
    return true

func choose_option(index: int) -> bool:
    if active_character_id.is_empty() or waiting_for_close:
        return false
    if index < 0 or index >= active_choices.size():
        return false

    var choice: Dictionary = active_choices[index]
    var choice_id := str(choice.get("id", ""))
    var affinity := int(choice.get("affinity", 0))
    var flag := str(choice.get("flag", ""))
    var first_time := flag.is_empty() or not story_flags.has(flag)
    if first_time:
        relationship_scores[active_character_id] = int(relationship_scores.get(active_character_id, 0)) + affinity
        if not flag.is_empty():
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

func record_npc_incident(character_id: String, incident_type: String, severity: int = 1) -> void:
    if character_id.is_empty() or not CONVERSATIONS.has(character_id):
        return
    var memory: Dictionary = npc_memories.get(character_id, {}).duplicate(true)
    var fear_gain := 12 * maxi(1, severity)
    var hostility_gain := 5 * maxi(1, severity)
    if incident_type == "vehicle_theft":
        fear_gain += 8
    memory["fear"] = clampi(int(memory.get("fear", 0)) + fear_gain, 0, 100)
    memory["hostility"] = clampi(int(memory.get("hostility", 0)) + hostility_gain, 0, 100)
    memory["incident_count"] = int(memory.get("incident_count", 0)) + 1
    memory["last_incident"] = incident_type
    npc_memories[character_id] = memory
    _save_state()

func get_npc_social_state(character_id: String) -> Dictionary:
    var memory: Dictionary = npc_memories.get(character_id, {})
    return {
        "fear": clampi(int(memory.get("fear", 0)), 0, 100),
        "hostility": clampi(int(memory.get("hostility", 0)), 0, 100),
        "incident_count": maxi(0, int(memory.get("incident_count", 0))),
        "last_incident": str(memory.get("last_incident", ""))
    }

func can_talk_to(character_id: String) -> bool:
    return int(get_npc_social_state(character_id).get("fear", 0)) < 65

func get_refusal_message(character_id: String) -> String:
    if int(get_npc_social_state(character_id).get("fear", 0)) >= 65:
        return "Loba na ngai te! Nazali kobanga yo. Tika ngai na kimia."
    return ""

func get_social_opening(character_id: String, default_opening: String) -> String:
    var state := get_npc_social_state(character_id)
    var fear := int(state.get("fear", 0))
    var hostility := int(state.get("hostility", 0))
    if fear >= 35:
        return "Ndeko, nazali komikanga motema mpo na kosolola na yo. Nalingi mobulu ezonga lisusu te."
    if hostility >= 20:
        return "Nayebi makambo osalaki awa. Tosolola, kasi boyokani na biso ebebi naino te."
    return default_opening

func get_relationship_score(character_id: String) -> int:
    return int(relationship_scores.get(character_id, 0))

func has_story_flag(flag: String) -> bool:
    return story_flags.has(flag)

func _save_state() -> void:
    var data := {
        "relationship_scores": relationship_scores,
        "story_flags": story_flags,
        "dialogue_history": dialogue_history,
        "npc_memories": npc_memories
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
    var memories = parsed.get("npc_memories", {})
    npc_memories.clear()
    if memories is Dictionary:
        for character_id in memories:
            if typeof(memories[character_id]) == TYPE_DICTIONARY:
                npc_memories[str(character_id)] = memories[character_id].duplicate(true)
    var history = parsed.get("dialogue_history", [])
    dialogue_history.clear()
    if history is Array:
        for entry in history:
            if typeof(entry) == TYPE_STRING:
                dialogue_history.append(entry)
