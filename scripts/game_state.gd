extends Node

const Models = preload("res://scripts/models.gd")

var day: int = 1
var station := Models.Station.new()
var competitors: Array[Models.Competitor] = []
var content_offers: Array = []
var difficulty: String = "Rookie"
var save_path: String = "user://madtv_save.json"

func _ready() -> void:
	_load_data()
	_seed_schedule()

func _load_data() -> void:
	station.library = _load_programs()
	station.ads = _load_ads()
	station.staff = _load_staff()
	competitors = _load_competitors()
	content_offers = _load_content_offers()

func _load_json(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing data file: %s" % path)
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Invalid data in %s" % path)
		return []
	return parsed

func _load_programs() -> Array[Models.Program]:
	var programs: Array[Models.Program] = []
	for entry in _load_json("res://data/programs.json"):
		programs.append(Models.Program.new(entry))
	return programs

func _load_ads() -> Array[Models.AdContract]:
	var ads: Array[Models.AdContract] = []
	for entry in _load_json("res://data/ads.json"):
		ads.append(Models.AdContract.new(entry))
	return ads

func _load_staff() -> Array[Models.Staff]:
	var staff_list: Array[Models.Staff] = []
	for entry in _load_json("res://data/staff.json"):
		staff_list.append(Models.Staff.new(entry))
	return staff_list

func _load_competitors() -> Array[Models.Competitor]:
	var list: Array[Models.Competitor] = []
	for entry in _load_json("res://data/competitors.json"):
		list.append(Models.Competitor.new(entry))
	return list

func _load_content_offers() -> Array:
	return _load_json("res://data/content_agency.json")

func _seed_schedule() -> void:
	if station.library.is_empty():
		return
	station.schedule = []
	station.schedule.append(Models.ScheduleSlot.new({
		"start_time": 8,
		"end_time": 10,
		"program_id": station.library[0].id,
		"attached_ads": ["ad_juice"],
	}))
	if station.library.size() > 1:
		station.schedule.append(Models.ScheduleSlot.new({
			"start_time": 10,
			"end_time": 12,
			"program_id": station.library[1].id,
			"attached_ads": ["ad_tacos"],
		}))

func simulate_day() -> Dictionary:
	var results := {
		"slots": [],
		"total_revenue": 0,
		"total_cost": 0,
	}
	var difficulty_mod := _difficulty_modifier()
	for slot in station.schedule:
		var program := station.find_program(slot.program_id)
		if program == null:
			continue
		var audience = (program.audience_score() + station.reputation * 0.2) * difficulty_mod.audience
		var revenue = int(station.revenue_for_ads(slot.attached_ads) * difficulty_mod.revenue)
		var cost = program.cost
		results["slots"].append({
			"program": program.title,
			"audience": audience,
			"revenue": revenue,
			"cost": cost,
		})
		results["total_revenue"] += revenue
		results["total_cost"] += cost
	station.cash += results["total_revenue"] - results["total_cost"]
	return results

func end_of_day() -> Dictionary:
	var payroll := station.total_payroll()
	station.cash -= payroll
	day += 1
	return {
		"payroll": payroll,
		"cash": station.cash,
		"day": day,
	}

func set_difficulty(value: String) -> void:
	difficulty = value

func _difficulty_modifier() -> Dictionary:
	match difficulty:
		"Primetime Pro":
			return {"audience": 0.95, "revenue": 0.9}
		"Ratings Monster":
			return {"audience": 0.85, "revenue": 0.8}
		_:
			return {"audience": 1.0, "revenue": 1.0}

func save_game() -> bool:
	var data := {
		"day": day,
		"difficulty": difficulty,
		"station": {
			"cash": station.cash,
			"debt": station.debt,
			"reputation": station.reputation,
			"audience_share": station.audience_share,
		},
		"schedule": [],
	}
	for slot in station.schedule:
		data["schedule"].append({
			"start_time": slot.start_time,
			"end_time": slot.end_time,
			"program_id": slot.program_id,
			"attached_ads": slot.attached_ads,
		})
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to save game.")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	day = parsed.get("day", day)
	difficulty = parsed.get("difficulty", difficulty)
	var station_data: Dictionary = parsed.get("station", {})
	station.cash = station_data.get("cash", station.cash)
	station.debt = station_data.get("debt", station.debt)
	station.reputation = station_data.get("reputation", station.reputation)
	station.audience_share = station_data.get("audience_share", station.audience_share)
	station.schedule = []
	for slot_data in parsed.get("schedule", []):
		station.schedule.append(Models.ScheduleSlot.new(slot_data))
	return true
