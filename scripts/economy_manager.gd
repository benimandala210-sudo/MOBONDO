extends Node
## Portefeuille et échanges simples du quartier MOBONDO.
signal economy_updated(balance: int, inventory: Dictionary, message: String)

const SAVE_PATH := "user://mobondo_economy.json"
const ITEMS := {
    "eau": {"name": "Eau", "price": 1000, "sell": 700},
    "pain": {"name": "Pain", "price": 1500, "sell": 1000},
    "tomates": {"name": "Tomates", "price": 2000, "sell": 1400}
}
var balance: int = 10000
var inventory: Dictionary = {}
var helped_today := false

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
    _save_state()

func do_market_job() -> bool:
    if helped_today:
        _emit_update("Osalisi Mama Sifa lelo. Yaka lobi mpo na mosala mosusu.")
        return false
    helped_today = true
    balance += 4000
    _save_state()
    _emit_update("Osalisi na komema biloko. Mama Sifa apesi yo 4 000 FC.")
    return true

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
        "helped_today": helped_today
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
