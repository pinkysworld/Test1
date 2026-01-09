extends RefCounted

class_name Program

var id: String
var title: String
var category: String
var duration: int
var cost: int
var popularity: float
var target_demo_tags: Array[String]
var freshness: float
var repeat_penalty: float
var license_type: String
var purchase_price: int

func _init(data: Dictionary) -> void:
	id = data.get("id", "")
	title = data.get("title", "Untitled")
	category = data.get("category", "movie")
	duration = data.get("duration", 60)
	cost = data.get("cost", 0)
	popularity = data.get("popularity", 0.5)
	target_demo_tags = data.get("target_demo_tags", [])
	freshness = data.get("freshness", 1.0)
	repeat_penalty = data.get("repeat_penalty", 0.1)
	license_type = data.get("license_type", "rent")
	purchase_price = data.get("purchase_price", 0)

func audience_score() -> float:
	return popularity * freshness

class ScheduleSlot:
	var start_time: int
	var end_time: int
	var program_id: String
	var attached_ads: Array[String]

	func _init(data: Dictionary) -> void:
		start_time = data.get("start_time", 0)
		end_time = data.get("end_time", 0)
		program_id = data.get("program_id", "")
		attached_ads = data.get("attached_ads", [])

class AdContract:
	var id: String
	var advertiser_name: String
	var required_slots: int
	var deadline_day: int
	var payout: int
	var penalty: int
	var target_demo: Array[String]
	var constraints: Dictionary

	func _init(data: Dictionary) -> void:
		id = data.get("id", "")
		advertiser_name = data.get("advertiser_name", "Unknown")
		required_slots = data.get("required_slots", 1)
		deadline_day = data.get("deadline_day", 1)
		payout = data.get("payout", 0)
		penalty = data.get("penalty", 0)
		target_demo = data.get("target_demo", [])
		constraints = data.get("constraints", {})

class Staff:
	var id: String
	var name: String
	var role: String
	var skill: int
	var wage: int
	var morale: float

	func _init(data: Dictionary) -> void:
		id = data.get("id", "")
		name = data.get("name", "Staffer")
		role = data.get("role", "producer")
		skill = data.get("skill", 1)
		wage = data.get("wage", 100)
		morale = data.get("morale", 0.8)

class Station:
	var cash: int
	var debt: int
	var reputation: float
	var audience_share: float
	var library: Array[Program]
	var staff: Array[Staff]
	var schedule: Array[ScheduleSlot]
	var ads: Array[AdContract]
	var transmission_stations: Array[String]

	func _init() -> void:
		cash = 50000
		debt = 10000
		reputation = 0.4
		audience_share = 0.1
		library = []
		staff = []
		schedule = []
		ads = []
		transmission_stations = []

	func total_payroll() -> int:
		var total := 0
		for member in staff:
			total += member.wage
		return total

	func find_program(program_id: String) -> Program:
		for item in library:
			if item.id == program_id:
				return item
		return null

	func revenue_for_ads(ad_ids: Array[String]) -> int:
		var revenue := 0
		for ad_id in ad_ids:
			for ad in ads:
				if ad.id == ad_id:
					revenue += ad.payout
		return revenue

class Competitor:
	var name: String
	var aggressiveness: float

	func _init(data: Dictionary) -> void:
		name = data.get("name", "Rival")
		aggressiveness = data.get("aggressiveness", 0.5)

	func pick_program(programs: Array[Program]) -> Program:
		if programs.is_empty():
			return null
		programs.sort_custom(func(a, b): return a.audience_score() > b.audience_score())
		return programs[0]
