extends Control

const GameState = preload("res://scripts/game_state.gd")

@onready var hub_panel: Control = %HubPanel
@onready var screens_panel: Control = %ScreensPanel
@onready var screen_title: Label = %ScreenTitle
@onready var screen_body: RichTextLabel = %ScreenBody
@onready var schedule_body: RichTextLabel = %ScheduleBody
@onready var sim_body: RichTextLabel = %SimBody
@onready var end_body: RichTextLabel = %EndBody
@onready var cash_label: Label = %CashLabel
@onready var day_label: Label = %DayLabel

var game_state := GameState.new()

func _ready() -> void:
	add_child(game_state)
	_update_status()
	_show_hub()

func _update_status() -> void:
	cash_label.text = "Cash: $%s" % game_state.station.cash
	day_label.text = "Day %s" % game_state.day

func _show_hub() -> void:
	_set_all_panels_hidden()
	hub_panel.visible = true

func _show_screen(title: String, body: String) -> void:
	_set_all_panels_hidden()
	screens_panel.visible = true
	screen_title.text = title
	screen_body.text = body

func _show_schedule() -> void:
	_set_all_panels_hidden()
	%SchedulePanel.visible = true
	_update_schedule_view()

func _update_schedule_view() -> void:
	var lines: Array[String] = []
	for slot in game_state.station.schedule:
		lines.append("%02d:00 - %02d:00 | %s" % [slot.start_time, slot.end_time, slot.program_id])
	if lines.is_empty():
		lines.append("No programs scheduled yet. Drag shows in a future build!")
	schedule_body.text = "\n".join(lines)

func _show_simulation() -> void:
	_set_all_panels_hidden()
	%SimPanel.visible = true
	_update_sim_view()

func _update_sim_view() -> void:
	var results := game_state.simulate_day()
	var lines: Array[String] = []
	for slot in results["slots"]:
		lines.append("%s | Audience: %.2f | Revenue: $%d" % [slot.program, slot.audience, slot.revenue])
	lines.append("Total Revenue: $%d" % results["total_revenue"])
	lines.append("Total Cost: $%d" % results["total_cost"])
	sim_body.text = "\n".join(lines)
	_update_status()

func _show_end_of_day() -> void:
	_set_all_panels_hidden()
	%EndPanel.visible = true
	var summary := game_state.end_of_day()
	end_body.text = "Payroll: $%d\nCash: $%d\nNow entering Day %d" % [summary.payroll, summary.cash, summary.day]
	_update_status()

func _set_all_panels_hidden() -> void:
	hub_panel.visible = false
	screens_panel.visible = false
	%SchedulePanel.visible = false
	%SimPanel.visible = false
	%EndPanel.visible = false

func _on_hub_button_pressed(location: String) -> void:
	match location:
		"staff":
			_show_screen("Staff Office", _staff_body())
		"programming":
			_show_screen("Programming Library", _program_body())
		"news":
			_show_screen("News Desk", "Wire reports are buzzing. Assign a researcher to scout fresh segments.")
		"ads":
			_show_screen("Ad Sales", _ads_body())
		"finance":
			_show_screen("Finance", _finance_body())
		"intel":
			_show_screen("Competitor Intel", _intel_body())
		"plan":
			_show_schedule()
		"simulate":
			_show_simulation()
		"end":
			_show_end_of_day()
		"back":
			_show_hub()

func _staff_body() -> String:
	var lines: Array[String] = []
	for member in game_state.station.staff:
		lines.append("%s (%s) | Skill %d | $%d/day" % [member.name, member.role, member.skill, member.wage])
	return "\n".join(lines)

func _program_body() -> String:
	var lines: Array[String] = []
	for program in game_state.station.library:
		lines.append("%s [%s] | $%d | Pop %.2f" % [program.title, program.category, program.cost, program.popularity])
	return "\n".join(lines)

func _ads_body() -> String:
	var lines: Array[String] = []
	for ad in game_state.station.ads:
		lines.append("%s | Slots %d | $%d" % [ad.advertiser_name, ad.required_slots, ad.payout])
	return "\n".join(lines)

func _finance_body() -> String:
	return "Cash: $%d\nDebt: $%d\nReputation: %.2f" % [game_state.station.cash, game_state.station.debt, game_state.station.reputation]

func _intel_body() -> String:
	var lines: Array[String] = []
	for rival in game_state.competitors:
		lines.append("%s | Aggression %.2f" % [rival.name, rival.aggressiveness])
	return "\n".join(lines)
