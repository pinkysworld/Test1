extends Control

const GameState = preload("res://scripts/game_state.gd")
const AudioManager = preload("res://scripts/audio_manager.gd")

@onready var hub_panel: Control = %HubPanel
@onready var screens_panel: Control = %ScreensPanel
@onready var menu_panel: Control = %MenuPanel
@onready var config_panel: Control = %ConfigPanel
@onready var screen_title: Label = %ScreenTitle
@onready var screen_body: RichTextLabel = %ScreenBody
@onready var schedule_body: RichTextLabel = %ScheduleBody
@onready var sim_body: RichTextLabel = %SimBody
@onready var end_body: RichTextLabel = %EndBody
@onready var cash_label: Label = %CashLabel
@onready var day_label: Label = %DayLabel
@onready var status_label: Label = %StatusLabel
@onready var difficulty_select: OptionButton = %DifficultySelect
@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SfxSlider

var game_state := GameState.new()
var audio_manager := AudioManager.new()

func _ready() -> void:
	add_child(game_state)
	add_child(audio_manager)
	_setup_config()
	_update_status()
	_show_hub()

func _setup_config() -> void:
	difficulty_select.clear()
	var options = ["Rookie", "Primetime Pro", "Ratings Monster"]
	for option in options:
		difficulty_select.add_item(option)
	var selected_index = options.find(game_state.difficulty)
	difficulty_select.select(max(selected_index, 0))
	master_slider.value = audio_manager.master_volume_db
	sfx_slider.value = audio_manager.sfx_volume_db

func _update_status(message: String = "") -> void:
	cash_label.text = "Cash: $%s" % game_state.station.cash
	day_label.text = "Day %s" % game_state.day
	status_label.text = message

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
	_update_status("Simulation complete!")

func _show_end_of_day() -> void:
	_set_all_panels_hidden()
	%EndPanel.visible = true
	var summary := game_state.end_of_day()
	end_body.text = "Payroll: $%d\nCash: $%d\nNow entering Day %d" % [summary.payroll, summary.cash, summary.day]
	_update_status("Day wrapped. New day, new ratings drama!")

func _show_menu() -> void:
	_set_all_panels_hidden()
	menu_panel.visible = true

func _show_config() -> void:
	_set_all_panels_hidden()
	config_panel.visible = true

func _set_all_panels_hidden() -> void:
	hub_panel.visible = false
	screens_panel.visible = false
	menu_panel.visible = false
	config_panel.visible = false
	%SchedulePanel.visible = false
	%SimPanel.visible = false
	%EndPanel.visible = false

func _on_hub_button_pressed(location: String) -> void:
	_play_location_sound(location)
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
		"agency":
			_show_screen("Advertisement Agency", _agency_body())
		"market":
			_show_screen("Movie Market", _market_body())
		"plan":
			_show_schedule()
		"simulate":
			_show_simulation()
		"end":
			_show_end_of_day()
		"back":
			_show_hub()

func _on_menu_button_pressed() -> void:
	_play_location_sound("menu")
	_show_menu()

func _on_menu_action(action: String) -> void:
	match action:
		"config":
			_show_config()
		"save":
			if game_state.save_game():
				_update_status("Game saved to %s" % game_state.save_path)
			else:
				_update_status("Save failed. Check permissions.")
		"load":
			if game_state.load_game():
				_update_status("Game loaded.")
				_show_hub()
			else:
				_update_status("No save found yet.")
		"back":
			_show_hub()

func _on_difficulty_selected(index: int) -> void:
	var value = difficulty_select.get_item_text(index)
	game_state.set_difficulty(value)
	_update_status("Difficulty set to %s" % value)

func _on_master_volume_changed(value: float) -> void:
	audio_manager.set_master_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	audio_manager.set_sfx_volume(value)

func _play_location_sound(location: String) -> void:
	var tones = {
		"staff": 440.0,
		"programming": 520.0,
		"news": 600.0,
		"ads": 480.0,
		"finance": 360.0,
		"intel": 560.0,
		"agency": 640.0,
		"market": 400.0,
		"plan": 500.0,
		"simulate": 720.0,
		"end": 300.0,
		"menu": 660.0,
	}
	audio_manager.play_blip(tones.get(location, 420.0))

func _staff_body() -> String:
	var lines: Array[String] = []
	for member in game_state.station.staff:
		lines.append("%s (%s) | Skill %d | $%d/day" % [member.name, member.role, member.skill, member.wage])
	return "\n".join(lines)

func _program_body() -> String:
	var lines: Array[String] = []
	for program in game_state.station.library:
		var license = "%s ($%d)" % [program.license_type.capitalize(), program.purchase_price]
		lines.append("%s [%s] | Airing $%d | %s | Pop %.2f" % [program.title, program.category, program.cost, license, program.popularity])
	return "\n".join(lines)

func _ads_body() -> String:
	var lines: Array[String] = []
	for ad in game_state.station.ads:
		lines.append("%s | Slots %d | $%d" % [ad.advertiser_name, ad.required_slots, ad.payout])
	return "\n".join(lines)

func _agency_body() -> String:
	var lines: Array[String] = ["Agency perks: negotiate bonuses, extend deadlines, and swap slots."]
	for ad in game_state.station.ads:
		lines.append("%s | Target %s | Deadline Day %d" % [ad.advertiser_name, ", ".join(ad.target_demo), ad.deadline_day])
	return "\n".join(lines)

func _market_body() -> String:
	var lines: Array[String] = ["Available rentals and purchases:"]
	for program in game_state.station.library:
		if program.category == "movie":
			lines.append("%s | %s for $%d" % [program.title, program.license_type, program.purchase_price])
	return "\n".join(lines)

func _finance_body() -> String:
	return "Cash: $%d\nDebt: $%d\nReputation: %.2f" % [game_state.station.cash, game_state.station.debt, game_state.station.reputation]

func _intel_body() -> String:
	var lines: Array[String] = []
	for rival in game_state.competitors:
		lines.append("%s | Aggression %.2f" % [rival.name, rival.aggressiveness])
	return "\n".join(lines)
