extends Node

const Models = preload("res://scripts/models.gd")

var day: int = 1
var station := Models.Station.new()
var competitors: Array[Models.Competitor] = []

func _ready() -> void:
	_load_data()
	_seed_schedule()

func _load_data() -> void:
	station.library = _load_programs()
	station.ads = _load_ads()
	station.staff = _load_staff()
	competitors = _load_competitors()

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
	for slot in station.schedule:
		var program := station.find_program(slot.program_id)
		if program == null:
			continue
		var audience = program.audience_score() + station.reputation * 0.2
		var revenue = station.revenue_for_ads(slot.attached_ads)
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
