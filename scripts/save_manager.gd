extends Node

const SLOT_COUNT: int = 10
const FORMAT_VERSION: int = 1
const START_YEAR: int = 1440
const GLOBAL_FIELDS = [
	"year", "month", "day", "week_index", "father_name", "money", "health_index",
	"already_talk", "visited_shops", "flags", "affection", "month_plan",
	"month_end_day", "schedule_plan_index", "is_outing_mode", "outing_actions_left",
	"growth_rates", "category_stage", "art_painting_level", "triggered_vacation_events",
	"completed_vacation_months"
]
const DAUGHTER_FIELDS = [
	"firstname", "secondname", "attributes", "age", "age_stage", "current_clothes_id",
	"current_clothes_name", "birth_year", "birth_month", "birth_day", "is_ill",
	"bloodtype", "body_stats", "clothing_bonus", "equipped_gear"
]

var save_directory: String = "user://saves"
var ending_collection_path: String = "user://ending_gallery.cfg"
var restoring_save: bool = false

func ReadEndingCollection() -> ConfigFile:
	var collection := ConfigFile.new()
	var error := collection.load(ending_collection_path)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("Could not read ending collection: %s" % error_string(error))
	return collection

func RecordEnding(id: String, daughter_name: String) -> Error:
	var collection := ConfigFile.new()
	var load_error := collection.load(ending_collection_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		return load_error
	if collection.has_section_key("endings", id):
		return OK
	collection.set_value("endings", id, daughter_name)
	var temporary_path := ending_collection_path + ".tmp"
	var error := collection.save(temporary_path)
	if error == OK:
		error = DirAccess.rename_absolute(temporary_path, ending_collection_path)
	if error != OK:
		DirAccess.remove_absolute(temporary_path)
	return error

func SlotPath(slot: int) -> String:
	return save_directory.path_join("slot_%02d.json" % (slot + 1))

func CaptureFields(node: Node, fields: Array) -> Dictionary:
	var data: Dictionary = {}
	for field in fields:
		data[field] = node.get(field)
	return data.duplicate(true)

func CaptureGame() -> Dictionary:
	var items: Array = []
	for slot in Inventory.slots:
		items.append({"id": slot["item"].id, "count": slot["count"]})
	return {
		"format_version": FORMAT_VERSION,
		"metadata": {
			"saved_at": Time.get_datetime_string_from_system(false, true).replace("-", "/"),
			"saved_at_unix": Time.get_unix_time_from_system(),
			"year": Global.year,
			"game_year": maxi(1, Global.year - START_YEAR + 1),
			"month": Global.month,
			"day": Global.day,
			"age": Daughterstatus.age,
			"father_name": Global.father_name,
			"daughter_name": Daughterstatus.firstname,
			"family_name": Daughterstatus.secondname
		},
		"state": {
			"global": CaptureFields(Global, GLOBAL_FIELDS),
			"daughter": CaptureFields(Daughterstatus, DAUGHTER_FIELDS),
			"inventory": items
		}
	}

func ReadSlot(slot: int) -> Dictionary:
	if slot < 0 or slot >= SLOT_COUNT:
		return {}
	var file = FileAccess.open(SlotPath(slot), FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or data.get("format_version") != FORMAT_VERSION:
		return {}
	var metadata = data.get("metadata")
	var state = data.get("state")
	if not metadata is Dictionary or not state is Dictionary:
		return {}
	for field in ["saved_at", "father_name", "daughter_name", "age", "game_year", "month", "day"]:
		if not metadata.has(field):
			return {}
	if not state.get("global") is Dictionary or not state.get("daughter") is Dictionary or not state.get("inventory") is Array:
		return {}
	# Older version-1 records predate equipment bonuses; retain their stored stats.
	if not state["daughter"].has("clothing_bonus"):
		state["daughter"]["clothing_bonus"] = {}
	if not state["daughter"].has("equipped_gear"):
		state["daughter"]["equipped_gear"] = {"weapon": "", "armor": ""}
	if not state["global"].has("completed_vacation_months"):
		# A calendar-year winter flag alone cannot determine the vacation month.
		state["global"]["completed_vacation_months"] = {}
	for field in ["saved_at", "father_name", "daughter_name"]:
		if not metadata[field] is String:
			return {}
	for field in ["age", "game_year", "month", "day"]:
		if not IsNumber(metadata[field]):
			return {}
	if not ValidateState(state):
		return {}
	MigrateWinterVacationRewards(state["global"])
	var date: Dictionary = state["global"]
	var daughter: Dictionary = state["daughter"]
	metadata["age"] = Daughterstatus.age_on(
		date["year"], date["month"], date["day"],
		daughter["birth_year"], daughter["birth_month"], daughter["birth_day"]
	)
	return data

func MigrateWinterVacationRewards(game: Dictionary) -> void:
	var visits: Dictionary = game["completed_vacation_months"]
	var rewards: Dictionary = game["triggered_vacation_events"]
	var first_winter_month_by_year := {}
	for date_key in visits:
		if not str(date_key).is_valid_int() or not visits[date_key]:
			continue
		var date := int(date_key)
		var month := date % 100
		var year := floori(date / 100.0)
		if month in [1, 2, 12] and rewards.get("%d_3" % year, false):
			first_winter_month_by_year[year] = mini(month, first_winter_month_by_year.get(year, month))
	for year in first_winter_month_by_year:
		rewards[Global.GetWinterVacationKey(year, first_winter_month_by_year[year])] = true

func IsNumber(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func MatchesShape(value: Variant, example: Variant) -> bool:
	if IsNumber(example):
		return IsNumber(value)
	if typeof(value) != typeof(example):
		return false
	if example is Dictionary:
		for key in example:
			if not value.has(key) or not MatchesShape(value[key], example[key]):
				return false
	elif example is Array and not example.is_empty():
		if value.size() != example.size():
			return false
		for index in range(example.size()):
			if not MatchesShape(value[index], example[index]):
				return false
	return true

func ValidateFields(data: Dictionary, defaults: Node, fields: Array) -> bool:
	for field in fields:
		if not data.has(field) or not MatchesShape(data[field], defaults.get(field)):
			return false
		if defaults.get(field) is int and float(data[field]) != floor(float(data[field])):
			return false
	return true

func ValidateState(state: Dictionary) -> bool:
	var global_defaults = Global.get_script().new()
	var daughter_defaults = Daughterstatus.get_script().new()
	var valid = ValidateFields(state["global"], global_defaults, GLOBAL_FIELDS) and ValidateFields(state["daughter"], daughter_defaults, DAUGHTER_FIELDS)
	global_defaults.free()
	daughter_defaults.free()
	if not valid:
		return false
	var game = state["global"]
	var daughter = state["daughter"]
	if game["year"] < 1 or game["month"] < 1 or game["month"] > 12:
		return false
	if game["day"] < 1 or game["day"] > Global.get_days_in_month(int(game["year"]), int(game["month"])):
		return false
	if game["health_index"] < 0 or game["health_index"] >= Global.health_tactics.size():
		return false
	if daughter["age_stage"] < 0 or daughter["age_stage"] >= Daughterstatus.age_stage_names.size():
		return false
	for key in daughter["clothing_bonus"]:
		if not Daughterstatus.attributes.has(key) or not IsNumber(daughter["clothing_bonus"][key]):
			return false
	for progress in game["category_stage"].values():
		if not progress is Array or progress.size() != 2:
			return false
		for value in progress:
			if not IsNumber(value) or float(value) != floor(float(value)):
				return false
	var owned_items := {}
	for entry in state["inventory"]:
		if not entry is Dictionary or not entry.get("id") is String or not IsNumber(entry.get("count")):
			return false
		if not Globaljson.items.has(entry["id"]) or entry["count"] < 1 or entry["count"] != floor(entry["count"]):
			return false
		owned_items[entry["id"]] = true
	for gear_slot in ["weapon", "armor"]:
		var item_id: String = daughter["equipped_gear"][gear_slot]
		if not item_id.is_empty():
			var item: Item = Globaljson.items.get(item_id)
			if item == null or not owned_items.has(item_id) or Inventory.GearSlot(item) != gear_slot:
				return false
	return true

func RestoreFields(node: Node, data: Dictionary, fields: Array) -> void:
	for field in fields:
		var value = data[field]
		if node.get(field) is int:
			value = int(value)
		elif value is Dictionary or value is Array:
			value = value.duplicate(true)
		node.set(field, value)

func StartNewGame() -> void:
	var global_defaults = Global.get_script().new()
	var daughter_defaults = Daughterstatus.get_script().new()
	RestoreFields(Global, CaptureFields(global_defaults, GLOBAL_FIELDS), GLOBAL_FIELDS)
	RestoreFields(Daughterstatus, CaptureFields(daughter_defaults, DAUGHTER_FIELDS), DAUGHTER_FIELDS)
	global_defaults.free()
	daughter_defaults.free()
	Inventory.ResetSlots()
	Global.month_end_day = Global.get_current_month_end_day()
	Global.sync_calendar()
	Global.UpdateGrowthRates()
	restoring_save = false

func LoadSlot(slot: int) -> Error:
	if slot < 0 or slot >= SLOT_COUNT:
		return ERR_INVALID_PARAMETER
	var data = ReadSlot(slot)
	if data.is_empty():
		return ERR_FILE_CORRUPT if FileAccess.file_exists(SlotPath(slot)) else ERR_FILE_NOT_FOUND
	# Validate the entire record before changing any live game data.
	var state = data["state"]
	RestoreFields(Global, state["global"], GLOBAL_FIELDS)
	RestoreFields(Daughterstatus, state["daughter"], DAUGHTER_FIELDS)
	# JSON numbers are floats; course stages are used as array indexes.
	for category in Global.category_stage:
		Global.category_stage[category] = [int(Global.category_stage[category][0]), int(Global.category_stage[category][1])]
		Global.UpdateCourseRank(category)
	Inventory.RestoreSlots(state["inventory"])
	Global.sync_calendar()
	Global.UpdateGrowthRates()
	restoring_save = true
	return OK

func GetSlotInfo(slot: int) -> Dictionary:
	var exists = FileAccess.file_exists(SlotPath(slot))
	var data = ReadSlot(slot) if exists else {}
	return {"exists": exists, "valid": not data.is_empty(), "metadata": data.get("metadata", {})}

func SaveSlot(slot: int, overwrite: bool = false) -> Error:
	if slot < 0 or slot >= SLOT_COUNT:
		return ERR_INVALID_PARAMETER
	var path = SlotPath(slot)
	if FileAccess.file_exists(path) and not overwrite:
		return ERR_ALREADY_EXISTS
	var error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_directory))
	if error != OK:
		return error
	# Write a complete temporary file before replacing the previous record.
	var temporary_path = path + ".tmp"
	var file = FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(CaptureGame(), "\t"))
	file.flush()
	error = file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary_path), ProjectSettings.globalize_path(path))
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
	return error
