extends Node

const Models = preload("res://scripts/models.gd")

var day: int = 1
var station := Models.Station.new()
var competitors: Array[Models.Competitor] = []
var content_offers: Array = []
var transmission_offers: Array = []
var difficulty: String = "Rookie"
var save_path: String = "user://madtv_save.json"
var betty_interest: int = 0
var win_conditions: Array = []
var competitor_reports: Array[String] = []

func _ready() -> void:
	_load_data()
	_seed_schedule()

func _load_data() -> void:
	station.library = _load_programs()
	station.ads = _load_ads()
	station.staff = _load_staff()
	competitors = _load_competitors()
	content_offers = _load_content_offers()
	transmission_offers = _load_transmission_offers()
	win_conditions = _load_win_conditions()

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

func _load_transmission_offers() -> Array:
	return _load_json("res://data/transmission_stations.json")

func _load_win_conditions() -> Array:
	return [
		{
			"id": "betty",
			"title": "Win Betty's Heart",
			"requirement": "Reach 0.7 reputation and 0.18 audience share.",
		},
		{
			"id": "ratings",
			"title": "Ratings Titan",
			"requirement": "Reach 0.25 audience share.",
		},
		{
			"id": "mogul",
			"title": "Station Mogul",
			"requirement": "Reach $150000 cash.",
		},
	]

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
		var audience = (program.audience_score() + station.reputation * 0.2 + _station_signal_bonus()) * difficulty_mod.audience
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
	_process_competitor_ai()
	_update_betty_interest(results["total_revenue"])
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

func buy_transmission_station(station_id: String) -> bool:
	for offer in transmission_offers:
		if offer.id == station_id and not station.transmission_stations.has(station_id):
			if station.cash < int(offer.cost):
				return false
			station.cash -= int(offer.cost)
			station.transmission_stations.append(station_id)
			station.audience_share = min(0.5, station.audience_share + float(offer.audience_boost) * 0.5)
			return true
	return false

func buy_next_transmission_station() -> String:
	var offers = transmission_offers.duplicate()
	offers.sort_custom(func(a, b): return int(a.cost) < int(b.cost))
	for offer in offers:
		if station.transmission_stations.has(offer.id):
			continue
		if buy_transmission_station(offer.id):
			return "Purchased %s." % offer.name
		return "Not enough cash for %s." % offer.name
	return "All transmission stations acquired."

func buy_best_transmission_station() -> String:
	var offers = transmission_offers.duplicate()
	offers.sort_custom(func(a, b): return float(a.audience_boost) > float(b.audience_boost))
	for offer in offers:
		if station.transmission_stations.has(offer.id):
			continue
		if buy_transmission_station(offer.id):
			return "Purchased %s." % offer.name
		return "Not enough cash for %s." % offer.name
	return "All transmission stations acquired."

func _station_signal_bonus() -> float:
	var bonus := 0.0
	for offer in transmission_offers:
		if station.transmission_stations.has(offer.id):
			bonus += float(offer.audience_boost)
	return bonus

func _process_competitor_ai() -> void:
	competitor_reports = []
	for rival in competitors:
		var pick := rival.pick_program(station.library)
		if pick == null:
			continue
		if rival.aggressiveness > 0.6 and pick.popularity > 0.7:
			station.reputation = max(0.0, station.reputation - 0.01)
			station.audience_share = max(0.05, station.audience_share - 0.005)
			competitor_reports.append("%s outbid on %s." % [rival.name, pick.title])
		else:
			station.reputation = min(1.0, station.reputation + 0.005)
			competitor_reports.append("%s played it safe with %s." % [rival.name, pick.title])

func _update_betty_interest(revenue: int) -> void:
	if station.reputation >= 0.5:
		betty_interest += 1
	if revenue > 3000:
		betty_interest += 1
	if station.audience_share >= 0.18:
		betty_interest += 1

func check_win_conditions() -> Array:
	var wins: Array = []
	if station.reputation >= 0.7 and station.audience_share >= 0.18:
		wins.append("betty")
	if station.audience_share >= 0.25:
		wins.append("ratings")
	if station.cash >= 150000:
		wins.append("mogul")
	return wins

func ad_tier_label() -> String:
	var reach = station.audience_share + _station_signal_bonus()
	if reach >= 0.25:
		return "Premium"
	if reach >= 0.18:
		return "Gold"
	if reach >= 0.12:
		return "Silver"
	return "Local"

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
		"betty_interest": betty_interest,
		"station": {
			"cash": station.cash,
			"debt": station.debt,
			"reputation": station.reputation,
			"audience_share": station.audience_share,
			"transmission_stations": station.transmission_stations,
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
	betty_interest = parsed.get("betty_interest", betty_interest)
	var station_data: Dictionary = parsed.get("station", {})
	station.cash = station_data.get("cash", station.cash)
	station.debt = station_data.get("debt", station.debt)
	station.reputation = station_data.get("reputation", station.reputation)
	station.audience_share = station_data.get("audience_share", station.audience_share)
	station.transmission_stations = station_data.get("transmission_stations", [])
	station.schedule = []
	for slot_data in parsed.get("schedule", []):
		station.schedule.append(Models.ScheduleSlot.new(slot_data))
	return true
