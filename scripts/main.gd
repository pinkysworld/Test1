extends Control

const GameState = preload("res://scripts/game_state.gd")
const AudioManager = preload("res://scripts/audio_manager.gd")

@onready var hub_panel: Control = %HubPanel
@onready var screens_panel: Control = %ScreensPanel
@onready var menu_panel: Control = %MenuPanel
@onready var config_panel: Control = %ConfigPanel
@onready var screen_title: Label = %ScreenTitle
@onready var screen_body: RichTextLabel = %ScreenBody
@onready var action_row: HBoxContainer = %ActionRow
@onready var primary_action_button: Button = %PrimaryActionButton
@onready var secondary_action_button: Button = %SecondaryActionButton
@onready var schedule_body: RichTextLabel = %ScheduleBody
@onready var sim_body: RichTextLabel = %SimBody
@onready var end_body: RichTextLabel = %EndBody
@onready var cash_label: Label = %CashLabel
@onready var day_label: Label = %DayLabel
@onready var status_label: Label = %StatusLabel
@onready var difficulty_select: OptionButton = %DifficultySelect
@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_slider: HSlider = %MusicSlider

var game_state := GameState.new()
var audio_manager := AudioManager.new()
var current_screen_id: String = ""

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
	music_slider.value = audio_manager.music_volume_db

func _update_status(message: String = "") -> void:
	cash_label.text = "Cash: $%s" % game_state.station.cash
	day_label.text = "Day %s" % game_state.day
	status_label.text = message

func _show_hub() -> void:
	_set_all_panels_hidden()
	hub_panel.visible = true

func _show_screen(title: String, body: String, screen_id: String = "") -> void:
	_set_all_panels_hidden()
	screens_panel.visible = true
	screen_title.text = title
	screen_body.text = body
	current_screen_id = screen_id
	_configure_screen_actions()

func _show_schedule() -> void:
	_set_all_panels_hidden()
	%SchedulePanel.visible = true
	_update_schedule_view()

func _update_schedule_view() -> void:
	var lines: Array[String] = []
	for slot in game_state.station.schedule:
		var program = game_state.station.find_program(slot.program_id)
		var title = program.title if program != null else slot.program_id
		lines.append("%02d:00 - %02d:00 | %s" % [slot.start_time, slot.end_time, title])
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
	var lines: Array[String] = []
	lines.append("Payroll: $%d" % summary.payroll)
	lines.append("Cash: $%d" % summary.cash)
	lines.append("Now entering Day %d" % summary.day)
	lines.append("")
	lines.append("Ad tier: %s" % game_state.ad_tier_label())
	lines.append("Betty interest: %d" % game_state.betty_interest)
	var wins = game_state.check_win_conditions()
	if not wins.is_empty():
		lines.append("Win paths achieved: %s" % ", ".join(wins))
	if not game_state.competitor_reports.is_empty():
		lines.append("")
		lines.append("Competitor recap:")
		for report in game_state.competitor_reports:
			lines.append("- %s" % report)
	end_body.text = "\n".join(lines)
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
	action_row.visible = false

func _on_hub_button_pressed(location: String) -> void:
	_play_location_sound(location)
	match location:
		"staff":
			_show_screen("Staff Office", _staff_body(), "staff")
		"programming":
			_show_screen("Programming Library", _program_body(), "programming")
		"news":
			_show_screen("News Desk", "Wire reports are buzzing. Assign a researcher to scout fresh segments.", "news")
		"ads":
			_show_screen("Ad Sales", _ads_body(), "ads")
		"finance":
			_show_screen("Finance", _finance_body(), "finance")
		"intel":
			_show_screen("Competitor Intel", _intel_body(), "intel")
		"agency":
			_show_screen("Advertisement Agency", _agency_body(), "agency")
		"market":
			_show_screen("Movie Market", _market_body(), "market")
		"content":
			_show_screen("Content Agency", _content_body(), "content")
		"transmission":
			_show_screen("Transmission Office", _transmission_body(), "transmission")
		"pr":
			_show_screen("PR Studio", _pr_body(), "pr")
		"archive":
			_show_screen("Archive Vault", _archive_body(), "archive")
		"research":
			_show_screen("Research Lab", _research_body(), "research")
		"lounge":
			_show_screen("Staff Lounge", _lounge_body(), "lounge")
		"talent":
			_show_screen("Talent Agency", _talent_body(), "talent")
		"studio":
			_show_screen("Studio Lot", _studio_body(), "studio")
		"betty":
			_show_screen("Betty's Lounge", _betty_body(), "betty")
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

func _on_music_volume_changed(value: float) -> void:
	audio_manager.set_music_volume(value)

func _on_schedule_action(action: String) -> void:
	match action:
		"auto":
			game_state.auto_plan_day()
			_update_status("Auto-planned today's schedule.")
			_update_schedule_view()
		"clear":
			game_state.clear_schedule()
			_update_status("Schedule cleared.")
			_update_schedule_view()

func _on_screen_action(action: String) -> void:
	match current_screen_id:
		"news":
			if action == "primary":
				var boosted = game_state.refresh_news()
				_update_status("Refreshed %d news blocks." % boosted)
				_show_screen("News Desk", "Fresh segments delivered to the newsroom.", "news")
		"ads":
			var message := ""
			if action == "primary":
				message = game_state.accept_best_ad_offer()
			else:
				message = game_state.accept_next_ad_offer()
			_update_status(message)
			_show_screen("Ad Sales", _ads_body(), "ads")
		"transmission":
			var message := ""
			if action == "primary":
				message = game_state.buy_next_transmission_station()
			else:
				message = game_state.buy_best_transmission_station()
			_update_status(message)
			_show_screen("Transmission Office", _transmission_body(), "transmission")
		"betty":
			_update_status("Betty is impressed by your dedication!")
			_show_screen("Betty's Lounge", _betty_body(), "betty")

func _configure_screen_actions() -> void:
	action_row.visible = false
	primary_action_button.visible = false
	secondary_action_button.visible = false
	match current_screen_id:
		"news":
			action_row.visible = true
			primary_action_button.visible = true
			primary_action_button.text = "Refresh News"
		"ads":
			action_row.visible = true
			primary_action_button.visible = true
			secondary_action_button.visible = true
			primary_action_button.text = "Sign Best Payout"
			secondary_action_button.text = "Sign Next Offer"
		"transmission":
			action_row.visible = true
			primary_action_button.visible = true
			secondary_action_button.visible = true
			primary_action_button.text = "Buy Next Tower"
			secondary_action_button.text = "Buy Best Boost"
		"betty":
			action_row.visible = true
			primary_action_button.visible = true
			primary_action_button.text = "Cheer Betty"

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
		"content": 580.0,
		"transmission": 460.0,
		"pr": 620.0,
		"archive": 340.0,
		"research": 700.0,
		"lounge": 300.0,
		"talent": 660.0,
		"studio": 520.0,
		"betty": 740.0,
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
		lines.append("%s [%s] | Airing $%d | %s | Pop %.2f | Fresh %.2f" % [
			program.title,
			program.category,
			program.cost,
			license,
			program.popularity,
			program.freshness,
		])
	return "\n".join(lines)

func _ads_body() -> String:
	var lines: Array[String] = ["Active contracts:"]
	for ad in game_state.station.ads:
		lines.append("%s | Slots %d | $%d" % [ad.advertiser_name, ad.required_slots, ad.payout])
	lines.append("")
	lines.append("Available offers:")
	for offer in game_state.ad_offers:
		lines.append("%s | Slots %d | $%d | Deadline %d" % [offer.advertiser_name, offer.required_slots, offer.payout, offer.deadline_day])
	if game_state.ad_offers.is_empty():
		lines.append("No offers available today.")
	return "\n".join(lines)

func _agency_body() -> String:
	var lines: Array[String] = [
		"Agency perks: negotiate bonuses, extend deadlines, and swap slots.",
		"Ad tier: %s | Audience Share: %.2f" % [game_state.ad_tier_label(), game_state.station.audience_share],
	]
	for ad in game_state.station.ads:
		var windows = ", ".join(ad.constraints.get("time_windows", []))
		var genres = ", ".join(ad.constraints.get("genre_restrictions", []))
		lines.append("%s | Target %s | Slots %d | Payout $%d | Window %s | Genres %s" % [
			ad.advertiser_name,
			", ".join(ad.target_demo),
			ad.required_slots,
			ad.payout,
			windows,
			genres,
		])
	return "\n".join(lines)

func _market_body() -> String:
	var lines: Array[String] = ["Available rentals and purchases:"]
	for program in game_state.station.library:
		if program.category == "movie":
			lines.append("%s | %s for $%d" % [program.title, program.license_type, program.purchase_price])
	return "\n".join(lines)

func _content_body() -> String:
	var lines: Array[String] = ["Content Agency offers fresh packages for rent or sale:"]
	for offer in game_state.content_offers:
		lines.append("%s [%s] | %s $%d | Pop %.2f" % [offer.title, offer.category, offer.license_type, offer.price, offer.popularity])
	return "\n".join(lines)

func _transmission_body() -> String:
	var lines: Array[String] = ["Buy transmission stations to expand reach:"]
	for offer in game_state.transmission_offers:
		var owned = game_state.station.transmission_stations.has(offer.id)
		var status = "Owned" if owned else "$%d" % int(offer.cost)
		lines.append("%s | Boost %.2f | %s" % [offer.name, offer.audience_boost, status])
	lines.append("Use the action buttons to purchase the next tower or the best boost.")
	return "\n".join(lines)

func _pr_body() -> String:
	return "PR stunts raise reputation. Book interviews, viral teasers, and scandal control."

func _archive_body() -> String:
	return "Archive Vault stores reruns and classic specials. Unlock retro marathons here."

func _research_body() -> String:
	return "Research Lab tracks viewer trends and competitor habits. Assign analysts for new intel."

func _lounge_body() -> String:
	return "Staff Lounge restores morale. Add snacks, arcade breaks, and pep talks."

func _talent_body() -> String:
	return "Talent Agency recruits hosts and celebrity guests. Negotiate contracts for boosts."

func _studio_body() -> String:
	return "Studio Lot produces original shows. Invest in sets, pilots, and live events."

func _betty_body() -> String:
	var wins = game_state.check_win_conditions()
	var lines: Array[String] = [
		"Betty watches the ratings with interest.",
		"Interest points: %d" % game_state.betty_interest,
	]
	for goal in game_state.win_conditions:
		lines.append("Goal: %s | %s" % [goal.title, goal.requirement])
	if not wins.is_empty():
		lines.append("Win paths achieved: %s" % ", ".join(wins))
	return "\n".join(lines)

func _finance_body() -> String:
	return "Cash: $%d\nDebt: $%d\nReputation: %.2f" % [game_state.station.cash, game_state.station.debt, game_state.station.reputation]

func _intel_body() -> String:
	var lines: Array[String] = ["Competitor notes:"]
	for rival in game_state.competitors:
		lines.append("%s | Aggression %.2f" % [rival.name, rival.aggressiveness])
	if not game_state.competitor_reports.is_empty():
		lines.append("Recent moves:")
		for report in game_state.competitor_reports:
			lines.append("- %s" % report)
	return "\n".join(lines)
