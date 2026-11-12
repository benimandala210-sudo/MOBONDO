extends Node
## Portefeuille et échanges simples du quartier MOBONDO.
signal economy_updated(balance: int, inventory: Dictionary, message: String)

const SAVE_PATH := "user://mobondo_economy.json"
const ITEMS := {
    "eau": {"name": "Eau", "price": 1000, "sell": 700},
    "pain": {"name": "Pain", "price": 1500, "sell": 1000},
    "tomates": {"name": "Tomates", "price": 2000, "sell": 1400},
    "carburant": {"name": "Carburant", "price": 3000, "sell": 2000}
}
var balance: int = 10000
var inventory: Dictionary = {}
var helped_today := false
var completed_jobs_today: Array[String] = []
var work_experience := 0
var work_level := 1

const DAILY_JOBS := {
    "porter": {"name": "Transporter les marchandises", "reward": 4000, "experience": 30},
    "cleaning": {"name": "Nettoyer les abords du marché", "reward": 2500, "experience": 20},
    "delivery": {"name": "Effectuer une livraison locale", "reward": 6000, "experience": 40}
}

func _ready() -> void:
    _load_state()
    _emit_update("Mbongo oyo ozali na yango: %d FC." % balance)

func buy(item_id: String) -> bool:
    if not ITEMS.has(item_id):
        return false
    var item: Dictionary = ITEMS[item_id]
    var price := int(item["price"])
    if balance < price:
        _emit_update("Mbongo ekoki te mpo na kosomba %s." % str(item["name"]))
        return false
    balance -= price
    inventory[item_id] = int(inventory.get(item_id, 0)) + 1
    _save_state()
    _emit_update("Osombi %s. -%d FC." % [str(item["name"]), price])
    return true

func use_item(item_id: String) -> bool:
    if not ITEMS.has(item_id) or int(inventory.get(item_id, 0)) <= 0:
        _emit_update("Ozali na eloko yango te. Kende kosomba yango na zando.")
        return false
    inventory[item_id] = int(inventory.get(item_id, 0)) - 1
    _save_state()
    var item: Dictionary = ITEMS[item_id]
    _emit_update("Osaleli %s." % str(item["name"]))
    return true

func sell(item_id: String) -> bool:
    if not ITEMS.has(item_id) or int(inventory.get(item_id, 0)) <= 0:
        _emit_update("Ozali na biloko yango te mpo na koteka.")
        return false
    var item: Dictionary = ITEMS[item_id]
    inventory[item_id] = int(inventory[item_id]) - 1
    balance += int(item["sell"])
    _save_state()
    _emit_update("Oteki %s. +%d FC." % [str(item["name"]), int(item["sell"])])
    return true

func reset_daily() -> void:
    helped_today = false
    completed_jobs_today.clear()
    _save_state()
    _emit_update("Mokolo ya sika ebandi. Misala ya zando ezali lisusu.")

func do_job(job_id: String) -> bool:
    if not DAILY_JOBS.has(job_id):
        return false
    if completed_jobs_today.has(job_id):
        _emit_update("Osilisi mosala oyo lelo. Zonga lobi.")
        return false
    var job: Dictionary = DAILY_JOBS[job_id]
    var reward := int(job["reward"])
    var gained_xp := int(job["experience"])
    completed_jobs_today.append(job_id)
    helped_today = true
    balance += reward
    work_experience += gained_xp
    work_level = mini(10, 1 + int(work_experience / 100))
    _save_state()
    _emit_update("%s esili. Ozwaki %s FC mpe %d XP. Niveau mosala: %d." % [
        str(job["name"]), _format_amount(reward), gained_xp, work_level
    ])
    return true

func do_market_job() -> bool:
    return do_job("porter")

func get_work_progress_text() -> String:
    var progress := work_experience % 100
    return "Niveau mosala %d — XP %d/100" % [work_level, progress]

func _format_amount(amount: int) -> String:
    var raw := str(amount)
    var result := ""
    var count := 0
    for i in range(raw.length() - 1, -1, -1):
        result = raw.substr(i, 1) + result
        count += 1
        if count == 3 and i > 0:
            result = " " + result
            count = 0
    return result

func get_balance() -> int:
    return balance

func get_inventory_text() -> String:
    var parts: Array[String] = []
    for item_id in ITEMS.keys():
        var item: Dictionary = ITEMS[item_id]
        parts.append("%s: %d" % [str(item["name"]), int(inventory.get(item_id, 0))])
    return "Biloko: " + " | ".join(parts)

func _emit_update(message: String) -> void:
    economy_updated.emit(balance, inventory.duplicate(true), message)

func _save_state() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify({
        "balance": balance,
        "inventory": inventory,
        "helped_today": helped_today,
        "completed_jobs_today": completed_jobs_today,
        "work_experience": work_experience,
        "work_level": work_level
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
    balance = maxi(0, int(parsed.get("balance", 10000)))
    var saved_inventory = parsed.get("inventory", {})
    if saved_inventory is Dictionary:
        inventory = saved_inventory
    helped_today = bool(parsed.get("helped_today", false))
    var saved_jobs = parsed.get("completed_jobs_today", [])
    completed_jobs_today.clear()
    if saved_jobs is Array:
        for job_id in saved_jobs:
            if typeof(job_id) == TYPE_STRING and DAILY_JOBS.has(job_id) and not completed_jobs_today.has(job_id):
                completed_jobs_today.append(job_id)
    work_experience = maxi(0, int(parsed.get("work_experience", 0)))
    work_level = clampi(int(parsed.get("work_level", 1)), 1, 10)
