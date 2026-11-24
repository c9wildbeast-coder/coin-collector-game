
extends Node2D

# =====================================================
# COIN COLLECTOR
# CLASSIC MODE + MAZE MODE (99 LEVELS)
# =====================================================

var screen_size = Vector2(720, 1280)
var state = "menu"
var animation_time = 0.0
var player_speed = 350.0
var player_position = Vector2.ZERO
var is_moving = false

var score = 0
var best_score = 0
var lives = 3
var max_lives = 5
var wallet_coins = 0

var coins: Array[Vector2] = []
var rocks: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var floating_texts: Array[Dictionary] = []

var transition_alpha = 1.0
var ui_button_scale = 1.0
var ui_tween: Tween

var display_score = 0.0
var display_wallet = 0.0
var hud_pulse_timer = 0.0

# =====================================================
# JOYSTICK
# =====================================================

var joystick_center = Vector2.ZERO
var joystick_vector = Vector2.ZERO
var joystick_radius = 82.0
var joystick_active = false
var joystick_touch_index = -1
var joystick_mouse_active = false

# =====================================================
# CLASSIC MODE
# =====================================================

var rock_spawn_timer = 1.5
var rock_spawn_interval = 4.0
var invulnerability_timer = 0.0

var magnet_timer = 0.0
var speed_timer = 0.0
var shield_active = false

# =====================================================
# SHOP
# =====================================================

var inventory = {
	"magnet": 0,
	"shield": 0,
	"speed": 0,
	"life": 0
}

var item_order = ["magnet", "shield", "speed", "life"]

var item_names = {
	"magnet": "COIN MAGNET",
	"shield": "SHIELD",
	"speed": "SPEED BOOST",
	"life": "EXTRA LIFE"
}

var item_descriptions = {
	"magnet": "Attracts nearby coins for 8 seconds.",
	"shield": "Blocks one falling rock hit.",
	"speed": "Move faster for 8 seconds.",
	"life": "Adds one extra life during a run."
}

var item_prices = {
	"magnet": 100,
	"shield": 150,
	"speed": 200,
	"life": 250
}

var item_buy_buttons = {}
var item_use_buttons = {}

# =====================================================
# MAZE MODE
# =====================================================

var maze_level = 1
var unlocked_maze_level = 1

var maze_cols = 21
var maze_rows = 31
var maze_cell_size = 28.0

var maze_grid: Array = []
var maze_seen: Array = []
var maze_fog_alpha: Array = []
var maze_origin = Vector2.ZERO

var maze_player_cell = Vector2i(1, 1)
var maze_exit_cell = Vector2i.ZERO
var maze_player_position = Vector2.ZERO

# Smooth movement
var maze_move_target = Vector2.ZERO
var maze_is_moving = false
var maze_move_speed = 400.0

# Camera
var maze_camera_offset = Vector2.ZERO

var maze_reward = 0
var maze_vision_radius = 2

# Fog animation speed
var maze_fog_speed = 3.0

# =====================================================
# BUTTONS
# =====================================================

var play_button = Rect2()
var shop_button = Rect2()
var shop_back_button = Rect2()

var pause_button = Rect2()
var resume_button = Rect2()
var restart_button = Rect2()
var home_button = Rect2()
var music_button = Rect2()

var classic_mode_button = Rect2()
var maze_mode_button = Rect2()
var mode_back_button = Rect2()

var maze_play_button = Rect2()
var maze_back_button = Rect2()
var maze_next_button = Rect2()
var maze_select_button = Rect2()

# =====================================================
# AUDIO
# =====================================================

var coin_sound_player: AudioStreamPlayer
var button_sound_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var music_enabled = true

# =====================================================
# DAILY REWARDS
# =====================================================

var daily_reward_button = Rect2()
var daily_claim_button = Rect2()
var daily_back_button = Rect2()

var daily_next_day = 1
var daily_last_claim_date = ""
var daily_streak = 0
var daily_rewards = [25, 35, 50, 65, 80, 100, 200]

# =====================================================
# ACHIEVEMENTS - COIN COLLECTOR MILESTONES
# =====================================================

var achievement_button = Rect2()
var achievement_back_button = Rect2()
var achievement_previous_button = Rect2()
var achievement_next_button = Rect2()
var achievement_page = 0
var total_coins_collected = 0
var coin_achievement_thresholds = [
	5000, 10000, 20000, 30000, 40000, 50000,
	75000, 100000, 150000, 200000, 300000, 400000,
	500000, 750000, 1000000, 1500000, 2000000, 3000000,
	4000000, 5000000, 7500000, 10000000
]
var coin_achievement_rewards = [
	100, 150, 250, 350, 450, 500,
	750, 1000, 1500, 2000, 3000, 4000,
	5000, 7500, 10000, 15000, 20000, 30000,
	40000, 50000, 75000, 100000
]
var coin_achievement_claimed: Array[bool] = []


# =====================================================
# READY
# =====================================================

func _ready():
	randomize()
	screen_size = get_viewport_rect().size

	load_best_score()
	load_shop_data()
	load_maze_data()
	load_daily_reward_data()
	load_achievement_data()

	display_score = float(score)
	display_wallet = float(wallet_coins)

	update_buttons()
	setup_audio()
	begin_fade()
	queue_redraw()


func change_state(new_state: String):
	state = new_state
	begin_fade()


func begin_fade():
	transition_alpha = 0.0
	var tween = create_tween()
	tween.tween_property(self, "transition_alpha", 1.0, 0.3)


func animate_button_press():
	if ui_tween and ui_tween.is_running():
		ui_tween.kill()

	ui_button_scale = 1.0
	ui_tween = create_tween()
	ui_tween.tween_property(self, "ui_button_scale", 0.94, 0.07)
	ui_tween.tween_property(self, "ui_button_scale", 1.0, 0.13)


# =====================================================
# BUTTON POSITIONS
# =====================================================

func update_buttons():
	var center = screen_size.x / 2.0
	joystick_center = Vector2(center, screen_size.y - 140)

	play_button = Rect2(center - 140, screen_size.y * 0.48, 280, 75)
	shop_button = Rect2(center - 140, screen_size.y * 0.58, 280, 75)
	daily_reward_button = Rect2(center - 140, screen_size.y * 0.68, 280, 75)
	achievement_button = Rect2(center - 140, screen_size.y * 0.78, 280, 75)
	achievement_back_button = Rect2(center - 140, screen_size.y - 125, 280, 70)
	achievement_previous_button = Rect2(center - 145, screen_size.y - 225, 125, 65)
	achievement_next_button = Rect2(center + 20, screen_size.y - 225, 125, 65)
	shop_back_button = Rect2(center - 140, screen_size.y - 145, 280, 75)

	daily_claim_button = Rect2(center - 145, screen_size.y * 0.73, 290, 85)
	daily_back_button = Rect2(center - 140, screen_size.y * 0.84, 280, 70)

	classic_mode_button = Rect2(center - 160, screen_size.y * 0.43, 320, 85)
	maze_mode_button = Rect2(center - 160, screen_size.y * 0.56, 320, 85)
	mode_back_button = Rect2(center - 140, screen_size.y * 0.72, 280, 70)

	maze_play_button = Rect2(center - 160, screen_size.y * 0.55, 320, 85)
	maze_back_button = Rect2(center - 140, screen_size.y * 0.70, 280, 70)

	maze_next_button = Rect2(center - 140, screen_size.y * 0.58, 280, 75)
	maze_select_button = Rect2(center - 140, screen_size.y * 0.70, 280, 75)

	pause_button = Rect2(screen_size.x - 105, 25, 80, 65)
	music_button = Rect2(screen_size.x - 205, 25, 90, 65)

	resume_button = Rect2(center - 140, screen_size.y * 0.38, 280, 75)
	restart_button = Rect2(center - 140, screen_size.y * 0.51, 280, 75)
	home_button = Rect2(center - 140, screen_size.y * 0.64, 280, 75)

	item_buy_buttons.clear()
	item_use_buttons.clear()

	for i in range(item_order.size()):
		var item = item_order[i]
		var card_y = 220 + i * 205

		item_buy_buttons[item] = Rect2(
			screen_size.x - 210, card_y + 95, 175, 65
		)

		item_use_buttons[item] = Rect2(
			screen_size.x - 125, 230 + i * 88, 110, 70
		)


# =====================================================
# AUDIO SYSTEM
# =====================================================

func setup_audio():
	coin_sound_player = AudioStreamPlayer.new()
	button_sound_player = AudioStreamPlayer.new()
	music_player = AudioStreamPlayer.new()

	add_child(coin_sound_player)
	add_child(button_sound_player)
	add_child(music_player)

	coin_sound_player.stream = make_tone(0.20, 850.0, 1450.0, 0.35)
	button_sound_player.stream = make_tone(0.09, 520.0, 330.0, 0.25)

	music_player.stream = make_music()
	music_player.volume_db = -15.0

	if music_enabled:
		music_player.play()


func make_tone(duration: float, start_frequency: float, end_frequency: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var sample_count = int(duration * sample_rate)
	var audio_data = PackedByteArray()
	audio_data.resize(sample_count * 2)
	var phase = 0.0

	for i in range(sample_count):
		var progress = float(i) / sample_count
		var frequency = lerpf(start_frequency, end_frequency, progress)
		phase += TAU * frequency / sample_rate

		var envelope = 1.0 - progress
		envelope *= minf(progress * 15.0, 1.0)

		var sample = sin(phase) * volume * envelope
		audio_data.encode_s16(i * 2, int(sample * 32767.0))

	var sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = sample_rate
	sound.stereo = false
	sound.data = audio_data
	return sound


func make_music() -> AudioStreamWAV:
	var sample_rate = 22050
	var note_duration = 0.32

	var notes = [
		523.25, 659.25, 783.99, 659.25,
		587.33, 698.46, 880.00, 698.46,
		523.25, 659.25, 783.99, 1046.50,
		880.00, 783.99, 659.25, 523.25
	]

	var samples_per_note = int(note_duration * sample_rate)
	var total_samples = samples_per_note * notes.size()
	var audio_data = PackedByteArray()
	audio_data.resize(total_samples * 2)
	var phase = 0.0

	for i in range(total_samples):
		var note_index = int(i / samples_per_note)
		var local_sample = i % samples_per_note
		var frequency = notes[note_index]

		phase += TAU * frequency / sample_rate

		var progress = float(local_sample) / samples_per_note
		var envelope = minf(progress * 15.0, 1.0)
		envelope *= minf((1.0 - progress) * 8.0, 1.0)

		var main_tone = sin(phase)
		var soft_harmony = sin(phase * 2.0) * 0.20
		var sample = (main_tone + soft_harmony) * 0.12 * envelope

		audio_data.encode_s16(i * 2, int(sample * 32767.0))

	var music = AudioStreamWAV.new()
	music.format = AudioStreamWAV.FORMAT_16_BITS
	music.mix_rate = sample_rate
	music.stereo = false
	music.data = audio_data
	music.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.loop_begin = 0
	music.loop_end = total_samples
	return music


func play_coin_sound():
	if coin_sound_player:
		coin_sound_player.play()


func play_button_sound():
	if button_sound_player:
		button_sound_player.play()


func toggle_music():
	music_enabled = not music_enabled

	if music_enabled:
		if not music_player.playing:
			music_player.play()
	else:
		music_player.stop()


# =====================================================
# SAVING SYSTEM
# =====================================================

func save_best_score():
	var file = FileAccess.open("user://coin_save.cfg", FileAccess.WRITE)
	if file:
		file.store_32(best_score)


func load_best_score():
	if FileAccess.file_exists("user://coin_save.cfg"):
		var file = FileAccess.open("user://coin_save.cfg", FileAccess.READ)
		if file:
			best_score = file.get_32()


func save_shop_data():
	var config = ConfigFile.new()
	config.set_value("wallet", "coins", wallet_coins)

	for item in item_order:
		config.set_value("inventory", item, inventory[item])

	config.save("user://coin_shop.cfg")


func load_shop_data():
	var config = ConfigFile.new()

	if config.load("user://coin_shop.cfg") == OK:
		wallet_coins = config.get_value("wallet", "coins", 0)

		for item in item_order:
			inventory[item] = config.get_value("inventory", item, 0)


func get_daily_date_string(date_dict: Dictionary) -> String:
	return "%04d-%02d-%02d" % [
		int(date_dict["year"]),
		int(date_dict["month"]),
		int(date_dict["day"])
	]


func get_today_date_string() -> String:
	return get_daily_date_string(Time.get_date_dict_from_system())


func get_yesterday_date_string() -> String:
	var today_dict = Time.get_date_dict_from_system()
	var today_timestamp = Time.get_unix_time_from_datetime_dict(today_dict)
	var yesterday_dict = Time.get_datetime_dict_from_unix_time(
		int(today_timestamp - 86400)
	)
	return get_daily_date_string(yesterday_dict)


func refresh_daily_reward_status():
	var today = get_today_date_string()
	var yesterday = get_yesterday_date_string()

	if daily_last_claim_date == today:
		return

	if daily_last_claim_date != yesterday:
		daily_next_day = 1
		daily_streak = 0


func save_daily_reward_data():
	var config = ConfigFile.new()
	config.set_value("daily", "next_day", daily_next_day)
	config.set_value("daily", "last_claim_date", daily_last_claim_date)
	config.set_value("daily", "streak", daily_streak)
	config.save("user://daily_rewards.cfg")


func load_daily_reward_data():
	var config = ConfigFile.new()

	if config.load("user://daily_rewards.cfg") == OK:
		daily_next_day = int(config.get_value("daily", "next_day", 1))
		daily_last_claim_date = str(
			config.get_value("daily", "last_claim_date", "")
		)
		daily_streak = int(config.get_value("daily", "streak", 0))

	daily_next_day = clampi(daily_next_day, 1, 7)
	daily_streak = max(0, daily_streak)
	refresh_daily_reward_status()


func can_claim_daily_reward() -> bool:
	return daily_last_claim_date != get_today_date_string()


func claim_daily_reward():
	refresh_daily_reward_status()

	if not can_claim_daily_reward():
		return

	var reward_index = daily_next_day - 1
	var reward_amount = daily_rewards[reward_index]
	var yesterday = get_yesterday_date_string()

	if daily_last_claim_date == yesterday:
		daily_streak += 1
	else:
		daily_streak = 1

	var streak_bonus = 0
	if daily_streak == 7:
		streak_bonus = 150
	elif daily_streak == 14:
		streak_bonus = 300
	elif daily_streak == 30:
		streak_bonus = 1000

	wallet_coins += reward_amount + streak_bonus
	daily_last_claim_date = get_today_date_string()

	if daily_next_day >= 7:
		daily_next_day = 1
	else:
		daily_next_day += 1

	save_daily_reward_data()
	save_shop_data()
	play_coin_sound()


func save_achievement_data():
	var config = ConfigFile.new()
	config.set_value("coins", "total_collected", total_coins_collected)
	config.set_value("coins", "claimed", coin_achievement_claimed)
	config.save("user://coin_achievements.cfg")


func load_achievement_data():
	coin_achievement_claimed.clear()
	for i in range(coin_achievement_thresholds.size()):
		coin_achievement_claimed.append(false)

	var config = ConfigFile.new()
	if config.load("user://coin_achievements.cfg") == OK:
		total_coins_collected = int(config.get_value("coins", "total_collected", 0))
		var saved_claims = config.get_value("coins", "claimed", [])
		for i in range(min(saved_claims.size(), coin_achievement_claimed.size())):
			coin_achievement_claimed[i] = bool(saved_claims[i])

	total_coins_collected = max(0, total_coins_collected)


func check_coin_achievements():
	var reward_earned = false
	for i in range(coin_achievement_thresholds.size()):
		if total_coins_collected >= coin_achievement_thresholds[i] and not coin_achievement_claimed[i]:
			coin_achievement_claimed[i] = true
			wallet_coins += coin_achievement_rewards[i]
			reward_earned = true

	if reward_earned:
		save_achievement_data()
		save_shop_data()
		play_coin_sound()


func format_achievement_number(value: int) -> String:
	if value >= 1000000:
		var millions = float(value) / 1000000.0
		if is_equal_approx(millions, roundf(millions)):
			return str(int(roundf(millions))) + "M"
		return ("%.1f" % millions) + "M"
	if value >= 1000:
		var thousands = float(value) / 1000.0
		if is_equal_approx(thousands, roundf(thousands)):
			return str(int(roundf(thousands))) + "K"
		return ("%.1f" % thousands) + "K"
	return str(value)


func save_maze_data():
	var config = ConfigFile.new()
	config.set_value("maze", "unlocked_level", unlocked_maze_level)
	config.save("user://maze_save.cfg")


func load_maze_data():
	var config = ConfigFile.new()

	if config.load("user://maze_save.cfg") == OK:
		unlocked_maze_level = int(
			config.get_value("maze", "unlocked_level", 1)
		)

	unlocked_maze_level = clampi(unlocked_maze_level, 1, 99)


# =====================================================
# SHOP SYSTEM
# =====================================================

func buy_item(item: String):
	var price = item_prices[item]

	if wallet_coins < price:
		return

	wallet_coins -= price
	inventory[item] += 1
	save_shop_data()
	play_button_sound()


func activate_item(item: String):
	if state != "playing":
		return

	if inventory[item] <= 0:
		return

	if item == "magnet":
		magnet_timer = 8.0
	elif item == "shield":
		shield_active = true
	elif item == "speed":
		speed_timer = 8.0
	elif item == "life":
		if lives >= max_lives:
			return
		lives += 1

	inventory[item] -= 1
	save_shop_data()
	play_button_sound()


# =====================================================
# CLASSIC MODE SETUP
# =====================================================

func start_game():
	score = 0
	lives = 3
	display_score = 0.0

	coins.clear()
	rocks.clear()
	particles.clear()
	floating_texts.clear()

	player_position = screen_size / 2.0
	is_moving = false

	stop_joystick()

	rock_spawn_timer = 1.5
	rock_spawn_interval = 4.0
	invulnerability_timer = 0.0

	magnet_timer = 0.0
	speed_timer = 0.0
	shield_active = false

	for i in range(10):
		spawn_coin()

	change_state("playing")


func spawn_coin():
	var margin = 60.0
	var coin = Vector2(
		randf_range(margin, screen_size.x - margin),
		randf_range(150, screen_size.y - margin)
	)
	coins.append(coin)


# =====================================================
# FALLING ROCK SYSTEM
# =====================================================

func spawn_rock():
	var target_position = Vector2(
		randf_range(75, screen_size.x - 75),
		randf_range(260, screen_size.y - 100)
	)

	rocks.append({
		"position": Vector2(target_position.x, -100),
		"target": target_position,
		"phase": "warning",
		"timer": 0.9,
		"speed": randf_range(900.0, 1150.0),
		"size": randf_range(32.0, 45.0)
	})


func update_rocks(delta):
	rock_spawn_timer -= delta

	if rock_spawn_timer <= 0:
		spawn_rock()
		rock_spawn_interval = maxf(2.0, 4.0 - score * 0.035)
		rock_spawn_timer = rock_spawn_interval

	for i in range(rocks.size() - 1, -1, -1):
		var rock = rocks[i]

		if rock["phase"] == "warning":
			rock["timer"] -= delta
			if rock["timer"] <= 0:
				rock["phase"] = "falling"

		elif rock["phase"] == "falling":
			rock["position"].y += rock["speed"] * delta

			if rock["position"].y >= rock["target"].y:
				var impact_position: Vector2 = rock["target"]
				var rock_size: float = rock["size"]

				create_rock_impact(impact_position)

				if player_position.distance_to(impact_position) < rock_size + 32:
					damage_player()

				rocks.remove_at(i)


func damage_player():
	if invulnerability_timer > 0:
		return

	if shield_active:
		shield_active = false
		invulnerability_timer = 0.8
		create_rock_impact(player_position)
		return

	lives -= 1
	invulnerability_timer = 1.5
	stop_joystick()

	if lives <= 0:
		change_state("game_over")


func create_rock_impact(pos: Vector2):
	for i in range(20):
		var angle = randf_range(0.0, TAU)
		var speed = randf_range(100.0, 320.0)
		var velocity = Vector2(cos(angle), sin(angle)) * speed

		var colors = [
			Color("#777777"),
			Color("#a0a0a0"),
			Color("#6b5544"),
			Color("#c2b8a5")
		]

		particles.append({
			"position": pos,
			"velocity": velocity,
			"life": 0.65,
			"max_life": 0.65,
			"color": colors[randi() % colors.size()],
			"size": randf_range(4.0, 9.0)
		})


# =====================================================
# COLLECTION EFFECTS
# =====================================================

func create_collection_effect(pos: Vector2):
	for i in range(16):
		var angle = randf_range(0.0, TAU)
		var speed = randf_range(80.0, 230.0)
		var velocity = Vector2(cos(angle), sin(angle)) * speed

		var colors = [
			Color("#ffe66d"),
			Color("#ffffff"),
			Color("#ffb830"),
			Color("#fff3a3")
		]

		particles.append({
			"position": pos,
			"velocity": velocity,
			"life": 0.55,
			"max_life": 0.55,
			"color": colors[randi() % colors.size()],
			"size": randf_range(3.0, 7.0)
		})

	floating_texts.append({
		"position": pos + Vector2(0, -25),
		"life": 0.8,
		"max_life": 0.8
	})


func update_effects(delta):
	for i in range(particles.size() - 1, -1, -1):
		particles[i]["life"] -= delta
		particles[i]["position"] += particles[i]["velocity"] * delta
		particles[i]["velocity"] *= 0.96

		if particles[i]["life"] <= 0:
			particles.remove_at(i)

	for i in range(floating_texts.size() - 1, -1, -1):
		floating_texts[i]["life"] -= delta
		floating_texts[i]["position"] += Vector2(0, -65 * delta)

		if floating_texts[i]["life"] <= 0:
			floating_texts.remove_at(i)


# =====================================================
# COIN COLLECTION
# =====================================================

func collect_coin(index: int):
	var collected_position = coins[index]
	coins.remove_at(index)

	create_collection_effect(collected_position)
	play_coin_sound()

	score += 1
	wallet_coins += 1
	total_coins_collected += 1
	check_coin_achievements()
	save_achievement_data()
	hud_pulse_timer = 0.18

	if score > best_score:
		best_score = score
		save_best_score()

	save_shop_data()
	spawn_coin()


func update_coins(delta):
	for i in range(coins.size() - 1, -1, -1):
		if magnet_timer > 0:
			if player_position.distance_to(coins[i]) < 220:
				coins[i] = coins[i].move_toward(
					player_position, 550.0 * delta
				)

		if player_position.distance_to(coins[i]) < 50:
			collect_coin(i)


# =====================================================
# MAZE MODE: LEVEL DIFFICULTY
# =====================================================

func get_maze_difficulty() -> String:
	if maze_level <= 20:
		return "EASY"
	elif maze_level <= 40:
		return "MODERATE"
	elif maze_level <= 60:
		return "HARD"
	elif maze_level <= 80:
		return "HARDER"
	else:
		return "EXTREME"


func get_maze_vision_radius() -> int:
	if maze_level <= 20:
		return 3
	elif maze_level <= 40:
		return 2
	elif maze_level <= 60:
		return 2
	elif maze_level <= 80:
		return 1
	else:
		return 1


func start_maze():
	maze_level = unlocked_maze_level
	generate_maze()

	maze_player_cell = Vector2i(1, 1)
	maze_player_position = maze_cell_center(maze_player_cell)
	maze_move_target = maze_player_position
	maze_is_moving = false

	maze_reward = 10 + maze_level * 2

	particles.clear()
	floating_texts.clear()

	stop_joystick()
	reveal_maze_area(maze_player_cell)
	initialize_maze_fog()

	update_maze_camera()
	change_state("maze_playing")


# =====================================================
# MAZE GENERATION
# DENSE CORRIDOR STYLE - 99 LEVELS
# =====================================================

func generate_maze():
	# Larger grids create longer and more detailed corridors.
	if maze_level <= 20:
		maze_cols = 21
		maze_rows = 31
	elif maze_level <= 40:
		maze_cols = 25
		maze_rows = 35
	elif maze_level <= 60:
		maze_cols = 29
		maze_rows = 41
	elif maze_level <= 80:
		maze_cols = 33
		maze_rows = 45
	else:
		maze_cols = 37
		maze_rows = 51

	maze_grid.clear()
	maze_seen.clear()
	maze_fog_alpha.clear()

	maze_vision_radius = get_maze_vision_radius()

	for y in range(maze_rows):
		var row: Array = []
		var seen_row: Array = []
		var fog_row: Array = []

		for x in range(maze_cols):
			row.append(1)
			seen_row.append(false)
			fog_row.append(1.0)

		maze_grid.append(row)
		maze_seen.append(seen_row)
		maze_fog_alpha.append(fog_row)

	var start = Vector2i(1, 1)
	maze_grid[start.y][start.x] = 0

	var stack: Array[Vector2i] = [start]

	var directions = [
		Vector2i(0, -2),
		Vector2i(0, 2),
		Vector2i(-2, 0),
		Vector2i(2, 0)
	]

	# Recursive-backtracking maze generation.
	while not stack.is_empty():
		var current = stack.back()
		var neighbors: Array[Vector2i] = []

		for direction in directions:
			var next = current + direction

			if next.x > 0 and next.x < maze_cols - 1:
				if next.y > 0 and next.y < maze_rows - 1:
					if maze_grid[next.y][next.x] == 1:
						neighbors.append(next)

		if neighbors.is_empty():
			stack.pop_back()
		else:
			var next = neighbors[randi() % neighbors.size()]

			var middle = Vector2i(
				int((current.x + next.x) / 2),
				int((current.y + next.y) / 2)
			)

			maze_grid[middle.y][middle.x] = 0
			maze_grid[next.y][next.x] = 0
			stack.append(next)

	# Fixed exit: always at the far bottom-right.
	maze_exit_cell = Vector2i(maze_cols - 2, maze_rows - 2)

	# Add alternate routes as levels become harder.
	var extra_openings = 0

	if maze_level <= 20:
		extra_openings = 3
	elif maze_level <= 40:
		extra_openings = 5
	elif maze_level <= 60:
		extra_openings = 8
	elif maze_level <= 80:
		extra_openings = 12
	else:
		extra_openings = 16

	for i in range(extra_openings):
		open_random_maze_wall()

	# Ensure start and exit remain open.
	maze_grid[1][1] = 0
	maze_grid[maze_exit_cell.y][maze_exit_cell.x] = 0

	# Smaller cells show more of the maze while keeping corridors clear.
	maze_cell_size = clampf(
		screen_size.x * 0.15,
		90.0,
		110.0
	)

	maze_origin = Vector2.ZERO


func open_random_maze_wall():
	var possible_walls: Array[Vector2i] = []

	for y in range(1, maze_rows - 1):
		for x in range(1, maze_cols - 1):
			if maze_grid[y][x] != 1:
				continue

			var horizontal = (
				maze_grid[y][x - 1] == 0
				and maze_grid[y][x + 1] == 0
			)

			var vertical = (
				maze_grid[y - 1][x] == 0
				and maze_grid[y + 1][x] == 0
			)

			if horizontal or vertical:
				possible_walls.append(Vector2i(x, y))

	if not possible_walls.is_empty():
		var chosen = possible_walls[randi() % possible_walls.size()]
		maze_grid[chosen.y][chosen.x] = 0


func maze_cell_center(cell: Vector2i) -> Vector2:
	return maze_origin + Vector2(
		(cell.x + 0.5) * maze_cell_size,
		(cell.y + 0.5) * maze_cell_size
	)


# =====================================================
# MAZE CAMERA
# =====================================================

func get_maze_viewport_rect() -> Rect2:
	return Rect2(
		Vector2(0, 190),
		Vector2(screen_size.x, maxf(200.0, screen_size.y - 430.0))
	)


func update_maze_camera():
	var viewport_rect = get_maze_viewport_rect()
	var viewport_center = viewport_rect.position + viewport_rect.size / 2.0

	maze_camera_offset = viewport_center - maze_player_position


# =====================================================
# MAZE FOG OF WAR
# PERSISTENT EXPLORATION + SMOOTH FADE
# =====================================================

func reveal_maze_area(center: Vector2i):
	if maze_seen.is_empty():
		return

	for y in range(maze_rows):
		for x in range(maze_cols):
			var cell = Vector2i(x, y)

			if cell.distance_to(center) <= maze_vision_radius:
				maze_seen[y][x] = true


func initialize_maze_fog():
	for y in range(maze_rows):
		for x in range(maze_cols):
			if maze_seen[y][x]:
				maze_fog_alpha[y][x] = 0.0
			else:
				maze_fog_alpha[y][x] = 1.0


func update_maze_fog(delta):
	if maze_fog_alpha.is_empty():
		return

	for y in range(maze_rows):
		for x in range(maze_cols):
			var target_alpha = 1.0

			# Once discovered, a cell stays revealed.
			if maze_seen[y][x]:
				target_alpha = 0.0

			maze_fog_alpha[y][x] = move_toward(
				maze_fog_alpha[y][x],
				target_alpha,
				maze_fog_speed * delta
			)


func get_maze_fog_alpha(cell: Vector2i) -> float:
	if cell.x < 0 or cell.x >= maze_cols:
		return 1.0

	if cell.y < 0 or cell.y >= maze_rows:
		return 1.0

	if maze_fog_alpha.is_empty():
		return 1.0

	return maze_fog_alpha[cell.y][cell.x]


func is_maze_cell_visible(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= maze_cols:
		return false

	if cell.y < 0 or cell.y >= maze_rows:
		return false

	if maze_seen.is_empty():
		return false

	return maze_seen[cell.y][cell.x]


# =====================================================
# MAZE MOVEMENT - SMOOTH AND FAST
# =====================================================

func move_maze_player(direction: Vector2i):
	if maze_is_moving:
		return

	var next_cell = maze_player_cell + direction

	if next_cell.x < 0 or next_cell.x >= maze_cols:
		return

	if next_cell.y < 0 or next_cell.y >= maze_rows:
		return

	if maze_grid[next_cell.y][next_cell.x] == 1:
		return

	maze_player_cell = next_cell
	maze_move_target = maze_cell_center(next_cell)
	maze_is_moving = true

	# Reveal newly explored cells without hiding old ones.
	reveal_maze_area(maze_player_cell)
	play_button_sound()


func update_maze(delta):
	if maze_is_moving:
		maze_player_position = maze_player_position.move_toward(
			maze_move_target,
			maze_move_speed * delta
		)

		if maze_player_position.distance_to(maze_move_target) < 0.5:
			maze_player_position = maze_move_target
			maze_is_moving = false

			if maze_player_cell == maze_exit_cell:
				complete_maze_level()

		return

	var direction = Vector2.ZERO

	if joystick_active:
		direction = joystick_vector
	else:
		direction = Input.get_vector(
			"ui_left", "ui_right",
			"ui_up", "ui_down"
		)

	if direction.length() < 0.5:
		return

	if absf(direction.x) > absf(direction.y):
		move_maze_player(
			Vector2i(1 if direction.x > 0 else -1, 0)
		)
	else:
		move_maze_player(
			Vector2i(0, 1 if direction.y > 0 else -1)
		)


# =====================================================
# MAZE LEVEL COMPLETION
# =====================================================

func complete_maze_level():
	wallet_coins += maze_reward
	save_shop_data()

	if maze_level < 99:
		unlocked_maze_level = max(
			unlocked_maze_level,
			maze_level + 1
		)

	save_maze_data()

	maze_is_moving = false
	stop_joystick()
	change_state("maze_complete")


# =====================================================
# JOYSTICK SYSTEM
# =====================================================

func is_joystick_area(pos: Vector2) -> bool:
	return pos.distance_to(joystick_center) <= joystick_radius + 35


func update_joystick(pos: Vector2):
	var offset = pos - joystick_center

	if offset.length() > joystick_radius:
		offset = offset.normalized() * joystick_radius

	joystick_vector = offset / joystick_radius


func stop_joystick():
	joystick_active = false
	joystick_mouse_active = false
	joystick_touch_index = -1
	joystick_vector = Vector2.ZERO


func draw_joystick():
	var knob_position = joystick_center + joystick_vector * 48.0

	draw_circle(
		joystick_center,
		joystick_radius,
		Color(0.05, 0.12, 0.16, 0.35)
	)

	draw_arc(
		joystick_center,
		joystick_radius,
		0,
		TAU,
		64,
		Color(1, 1, 1, 0.65),
		5
	)

	draw_circle(
		joystick_center,
		55,
		Color(1, 1, 1, 0.12)
	)

	draw_circle(knob_position, 32, Color("#3498db"))

	draw_arc(
		knob_position,
		32,
		0,
		TAU,
		48,
		Color.WHITE,
		4
	)


# =====================================================
# HUD
# =====================================================

func draw_hud_panel(rect: Rect2, panel_color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = panel_color

	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18

	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.45)

	draw_style_box(style, rect)


func draw_hud():
	var score_panel = Rect2(20, 25, 295, 125)
	var lives_panel = Rect2(330, 25, 170, 65)

	var pulse = 1.0

	if hud_pulse_timer > 0:
		pulse = 1.0 + sin(hud_pulse_timer * 30.0) * 0.04

	draw_hud_panel(score_panel, Color(0.05, 0.20, 0.25, 0.88))

	draw_string(
		ThemeDB.fallback_font,
		Vector2(43, 59),
		"COINS COLLECTED",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		17,
		Color("#bcecff")
	)

	draw_set_transform(Vector2(43, 101), 0.0, Vector2(pulse, pulse))

	draw_circle(Vector2(9, -9), 12, Color("#d99b00"))
	draw_circle(Vector2(9, -9), 9, Color("#ffe66d"))

	draw_string(
		ThemeDB.fallback_font,
		Vector2(30, 0),
		str(int(round(display_score))),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		31,
		Color.WHITE
	)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_line(
		Vector2(42, 112),
		Vector2(293, 112),
		Color(1, 1, 1, 0.2),
		2
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(43, 139),
		"WALLET: " + str(int(round(display_wallet))) + " COINS",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		19,
		Color("#ffe66d")
	)

	draw_hud_panel(lives_panel, Color(0.25, 0.08, 0.12, 0.88))

	draw_string(
		ThemeDB.fallback_font,
		Vector2(348, 52),
		"LIVES",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		17,
		Color("#ffc5c5")
	)

	for i in range(max_lives):
		var heart_position = Vector2(350 + i * 27, 76)
		var heart_color = Color("#ff5252") if i < lives else Color("#65454b")

		draw_string(
			ThemeDB.fallback_font,
			heart_position,
			"♥",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			23,
			heart_color
		)


# =====================================================
# GAME LOOP
# =====================================================

func _process(delta):
	animation_time += delta

	display_score = lerpf(
		display_score,
		float(score),
		minf(delta * 12.0, 1.0)
	)

	display_wallet = lerpf(
		display_wallet,
		float(wallet_coins),
		minf(delta * 8.0, 1.0)
	)

	hud_pulse_timer = maxf(0.0, hud_pulse_timer - delta)

	if state == "maze_playing":
		update_maze(delta)
		update_maze_fog(delta)
		update_maze_camera()
		queue_redraw()
		return

	if state != "playing":
		queue_redraw()
		return

	update_effects(delta)
	update_rocks(delta)

	if state != "playing":
		queue_redraw()
		return

	if invulnerability_timer > 0:
		invulnerability_timer -= delta

	if magnet_timer > 0:
		magnet_timer = maxf(0.0, magnet_timer - delta)

	if speed_timer > 0:
		speed_timer = maxf(0.0, speed_timer - delta)

	var direction = Input.get_vector(
		"ui_left", "ui_right",
		"ui_up", "ui_down"
	)

	if joystick_active:
		direction = joystick_vector

	is_moving = direction.length() > 0.05

	var current_speed = player_speed

	if speed_timer > 0:
		current_speed *= 1.7

	player_position += direction * current_speed * delta

	player_position.x = clampf(
		player_position.x, 40, screen_size.x - 40
	)

	player_position.y = clampf(
		player_position.y, 140, screen_size.y - 45
	)

	update_coins(delta)
	queue_redraw()


# =====================================================
# INPUT
# =====================================================

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if (state == "playing" or state == "maze_playing") and is_joystick_area(event.position):
				joystick_active = true
				joystick_touch_index = event.index
				update_joystick(event.position)
			else:
				handle_press(event.position)
		else:
			if joystick_active and event.index == joystick_touch_index:
				stop_joystick()

	elif event is InputEventScreenDrag:
		if joystick_active and event.index == joystick_touch_index:
			update_joystick(event.position)

	elif event is InputEventMouseButton:
		if DisplayServer.is_touchscreen_available():
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if (state == "playing" or state == "maze_playing") and is_joystick_area(event.position):
					joystick_active = true
					joystick_mouse_active = true
					update_joystick(event.position)
				else:
					handle_press(event.position)
			else:
				if joystick_mouse_active:
					stop_joystick()

	elif event is InputEventMouseMotion:
		if DisplayServer.is_touchscreen_available():
			return

		if joystick_mouse_active and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			update_joystick(event.position)


# =====================================================
# BUTTON ACTIONS
# =====================================================

func handle_press(pos: Vector2):
	if state == "menu":
		if music_button.has_point(pos):
			play_button_sound()
			toggle_music()
		elif play_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			change_state("mode_select")
		elif shop_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			change_state("shop")
		elif daily_reward_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			refresh_daily_reward_status()
			change_state("daily_rewards")
		elif achievement_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			achievement_page = 0
			change_state("achievements")

	elif state == "achievements":
		if achievement_back_button.has_point(pos):
			play_button_sound()
			change_state("menu")
		elif achievement_previous_button.has_point(pos) and achievement_page > 0:
			play_button_sound()
			achievement_page -= 1
			queue_redraw()
		elif achievement_next_button.has_point(pos) and (achievement_page + 1) * 6 < coin_achievement_thresholds.size():
			play_button_sound()
			achievement_page += 1
			queue_redraw()

	elif state == "daily_rewards":
		if daily_back_button.has_point(pos):
			play_button_sound()
			change_state("menu")
		elif daily_claim_button.has_point(pos):
			if can_claim_daily_reward():
				claim_daily_reward()
				animate_button_press()
			else:
				play_button_sound()

	elif state == "mode_select":
		if classic_mode_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			start_game()
		elif maze_mode_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			change_state("maze_menu")
		elif mode_back_button.has_point(pos):
			play_button_sound()
			change_state("menu")

	elif state == "maze_menu":
		if maze_play_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			start_maze()
		elif maze_back_button.has_point(pos):
			play_button_sound()
			change_state("mode_select")

	elif state == "maze_complete":
		if maze_level < 99 and maze_next_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			start_maze()
		elif maze_select_button.has_point(pos):
			play_button_sound()
			change_state("maze_menu")

	elif state == "shop":
		if shop_back_button.has_point(pos):
			play_button_sound()
			change_state("menu")
			return

		for item in item_order:
			if item_buy_buttons[item].has_point(pos):
				buy_item(item)
				animate_button_press()
				return

	elif state == "playing":
		if music_button.has_point(pos):
			play_button_sound()
			toggle_music()
		elif pause_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			stop_joystick()
			change_state("paused")
		else:
			for item in item_order:
				if item_use_buttons[item].has_point(pos):
					activate_item(item)
					animate_button_press()
					return

	elif state == "paused":
		if music_button.has_point(pos):
			play_button_sound()
			toggle_music()
		elif resume_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			change_state("playing")
		elif restart_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			start_game()
		elif home_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			change_state("menu")

	elif state == "game_over":
		if restart_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			start_game()
		elif home_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			change_state("menu")


# =====================================================
# CHARACTER
# =====================================================

func draw_character(pos: Vector2, running: bool, scale_factor: float = 1.0):
	var swing = 0.0

	if running:
		swing = sin(animation_time * 10.0) * 13.0

	var idle_bounce = 0.0

	if not running:
		idle_bounce = sin(animation_time * 3.0) * 2.5

	pos.y += idle_bounce
	draw_set_transform(pos, 0.0, Vector2.ONE * scale_factor)

	draw_line(Vector2(-8, 17), Vector2(-10 + swing, 34), Color("#202638"), 10)
	draw_line(Vector2(8, 17), Vector2(10 - swing, 34), Color("#202638"), 10)

	draw_line(Vector2(-10 + swing, 34), Vector2(-19 + swing, 39), Color("#e74c3c"), 12)
	draw_line(Vector2(10 - swing, 34), Vector2(19 - swing, 39), Color("#e74c3c"), 12)

	draw_line(Vector2(-20 + swing, 43), Vector2(-10 + swing, 43), Color.WHITE, 3)
	draw_line(Vector2(10 - swing, 43), Vector2(20 - swing, 43), Color.WHITE, 3)

	draw_line(Vector2(-14, -7), Vector2(-24 - swing * 0.5, 7), Color("#b92e28"), 11)
	draw_line(Vector2(14, -7), Vector2(24 + swing * 0.5, 7), Color("#b92e28"), 11)

	draw_circle(Vector2(-24 - swing * 0.5, 8), 6, Color("#ffd0aa"))
	draw_circle(Vector2(24 + swing * 0.5, 8), 6, Color("#ffd0aa"))

	var body = PackedVector2Array([
		Vector2(-17, -15),
		Vector2(17, -15),
		Vector2(15, 20),
		Vector2(-15, 20)
	])

	draw_colored_polygon(body, Color("#e53935"))
	draw_line(Vector2(0, -12), Vector2(0, 18), Color("#ff8a80"), 2)
	draw_arc(Vector2(0, -9), 18, PI, TAU, 32, Color("#a92725"), 5)

	draw_circle(Vector2(-18, -31), 6, Color("#ffd0aa"))
	draw_circle(Vector2(18, -31), 6, Color("#ffd0aa"))
	draw_circle(Vector2(0, -32), 19, Color("#ffd0aa"))

	var hair = PackedVector2Array([
		Vector2(-19, -34),
		Vector2(-23, -47),
		Vector2(-12, -43),
		Vector2(-7, -54),
		Vector2(1, -46),
		Vector2(10, -53),
		Vector2(13, -43),
		Vector2(24, -45),
		Vector2(20, -32),
		Vector2(14, -28),
		Vector2(-15, -28)
	])

	draw_colored_polygon(hair, Color("#39231d"))

	draw_circle(Vector2(7, -32), 3.5, Color("#171717"))
	draw_circle(Vector2(-6, -32), 3.5, Color("#171717"))
	draw_circle(Vector2(8, -34), 1.2, Color.WHITE)
	draw_circle(Vector2(-5, -34), 1.2, Color.WHITE)
	draw_arc(Vector2(2, -23), 5, 0.2, PI - 0.2, 12, Color("#9b5142"), 1.5)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# =====================================================
# ROCK DRAWING
# =====================================================

func draw_rocks():
	for rock in rocks:
		var target: Vector2 = rock["target"]
		var size: float = rock["size"]

		if rock["phase"] == "warning":
			var pulse = 1.0 + sin(animation_time * 8.0) * 0.12
			var warning_alpha = 0.25 + absf(sin(animation_time * 8.0)) * 0.35

			draw_circle(
				target,
				size * 1.4 * pulse,
				Color(0.9, 0.15, 0.1, warning_alpha)
			)

			draw_arc(
				target,
				size * 1.4 * pulse,
				0,
				TAU,
				48,
				Color("#ff4444"),
				4
			)

			draw_circle(target, 7, Color("#ff4444"))

		elif rock["phase"] == "falling":
			var pos: Vector2 = rock["position"]

			draw_circle(pos, size, Color("#666666"))
			draw_circle(pos + Vector2(-size * 0.25, -size * 0.25), size * 0.48, Color("#999999"))
			draw_circle(pos + Vector2(size * 0.3, size * 0.2), size * 0.25, Color("#4c4c4c"))
			draw_arc(pos, size, 0, TAU, 32, Color("#444444"), 3)


# =====================================================
# EFFECT DRAWING
# =====================================================

func draw_collection_effects():
	for particle in particles:
		var life_ratio = particle["life"] / particle["max_life"]
		var color: Color = particle["color"]
		color.a = life_ratio

		draw_circle(
			particle["position"],
			particle["size"] * life_ratio,
			color
		)

	for floating in floating_texts:
		var life_ratio = floating["life"] / floating["max_life"]
		var color = Color("#fff36b")
		color.a = life_ratio

		draw_string(
			ThemeDB.fallback_font,
			floating["position"],
			"+1",
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			32,
			color
		)


# =====================================================
# BUTTON DRAWING
# =====================================================

func draw_button(rect: Rect2, label: String, color: Color):
	var center = rect.position + rect.size / 2.0
	var scaled_size = rect.size * ui_button_scale
	var scaled_rect = Rect2(center - scaled_size / 2.0, scaled_size)

	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_width_bottom = 5
	style.border_color = Color(0, 0, 0, 0.2)

	draw_style_box(style, scaled_rect)
	draw_rect(scaled_rect, Color.WHITE, false, 3)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(
			scaled_rect.position.x,
			scaled_rect.position.y + scaled_rect.size.y / 2.0 + 10
		),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		scaled_rect.size.x,
		32,
		Color.WHITE
	)


func draw_music_button():
	var button_color = Color("#27ae60") if music_enabled else Color("#7f8c8d")
	var label = "MUSIC ON" if music_enabled else "MUSIC OFF"

	draw_rect(music_button, button_color)
	draw_rect(music_button, Color.WHITE, false, 3)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(music_button.position.x, music_button.position.y + 40),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		music_button.size.x,
		18,
		Color.WHITE
	)


# =====================================================
# SHOP DRAWING
# =====================================================

func draw_shop_panel(rect: Rect2, panel_color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = panel_color

	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22

	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.35)

	draw_style_box(style, rect)


func draw_shop_icon(item: String, center: Vector2):
	var background_color = Color("#3498db")

	if item == "magnet":
		background_color = Color("#e74c3c")
	elif item == "shield":
		background_color = Color("#2980b9")
	elif item == "speed":
		background_color = Color("#f39c12")
	elif item == "life":
		background_color = Color("#e84393")

	draw_circle(center, 43, Color(0, 0, 0, 0.18))
	draw_circle(center, 38, background_color)

	if item == "magnet":
		draw_arc(center + Vector2(0, -3), 22, 0, PI, 32, Color.WHITE, 9)
		draw_line(center + Vector2(-22, -3), center + Vector2(-22, 16), Color.WHITE, 9)
		draw_line(center + Vector2(22, -3), center + Vector2(22, 16), Color.WHITE, 9)

	elif item == "shield":
		var shield = PackedVector2Array([
			center + Vector2(0, -27),
			center + Vector2(23, -17),
			center + Vector2(19, 12),
			center + Vector2(0, 28),
			center + Vector2(-19, 12),
			center + Vector2(-23, -17)
		])
		draw_colored_polygon(shield, Color.WHITE)

	elif item == "speed":
		var lightning = PackedVector2Array([
			center + Vector2(5, -29),
			center + Vector2(-18, 4),
			center + Vector2(-3, 4),
			center + Vector2(-9, 29),
			center + Vector2(19, -7),
			center + Vector2(4, -7)
		])
		draw_colored_polygon(lightning, Color.WHITE)

	elif item == "life":
		draw_string(
			ThemeDB.fallback_font,
			center + Vector2(-18, 13),
			"♥",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			48,
			Color.WHITE
		)


func draw_shop_buy_button(rect: Rect2, price: int, can_afford: bool):
	var button_color = Color("#20bf6b") if can_afford else Color("#59636e")
	var style = StyleBoxFlat.new()
	style.bg_color = button_color

	style.corner_radius_top_left = 17
	style.corner_radius_top_right = 17
	style.corner_radius_bottom_left = 17
	style.corner_radius_bottom_right = 17

	style.border_width_bottom = 4
	style.border_color = Color(0, 0, 0, 0.2)

	draw_style_box(style, rect)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(rect.position.x, rect.position.y + 27),
		"BUY",
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		22,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(rect.position.x, rect.position.y + 49),
		str(price) + " COINS",
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		15,
		Color.WHITE
	)


func draw_shop():
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 92),
		"ITEM SHOP",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		48,
		Color("#ffe66d")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 130),
		"UPGRADE YOUR GAME!",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		18,
		Color("#eaffff")
	)

	var wallet_panel = Rect2(170, 145, 380, 58)
	draw_shop_panel(wallet_panel, Color("#173f47"))

	draw_circle(Vector2(215, 174), 15, Color("#d99b00"))
	draw_circle(Vector2(215, 174), 11, Color("#ffe66d"))

	draw_string(
		ThemeDB.fallback_font,
		Vector2(245, 184),
		"YOUR COINS: " + str(wallet_coins),
		HORIZONTAL_ALIGNMENT_LEFT,
		280,
		25,
		Color.WHITE
	)

	for i in range(item_order.size()):
		var item = item_order[i]
		var card_y = 220 + i * 205
		var card = Rect2(25, card_y, screen_size.x - 50, 175)

		var card_color = Color("#245d65")
		if i % 2 == 1:
			card_color = Color("#28546b")

		draw_shop_panel(card, card_color)
		draw_shop_icon(item, Vector2(82, card_y + 83))

		draw_string(
			ThemeDB.fallback_font,
			Vector2(140, card_y + 45),
			item_names[item],
			HORIZONTAL_ALIGNMENT_LEFT,
			340,
			25,
			Color("#ffe66d")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(140, card_y + 78),
			item_descriptions[item],
			HORIZONTAL_ALIGNMENT_LEFT,
			340,
			17,
			Color.WHITE
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(140, card_y + 126),
			"OWNED: " + str(inventory[item]),
			HORIZONTAL_ALIGNMENT_LEFT,
			300,
			21,
			Color("#aaffc3")
		)

		draw_shop_buy_button(
			item_buy_buttons[item],
			item_prices[item],
			wallet_coins >= item_prices[item]
		)

	draw_button(shop_back_button, "BACK", Color("#c0392b"))


# =====================================================
# GAMEPLAY ITEM BUTTONS
# =====================================================

func draw_gameplay_item_icon(item: String, center: Vector2):
	if item == "magnet":
		draw_arc(center + Vector2(0, -2), 17, 0, PI, 32, Color.WHITE, 7)
		draw_line(center + Vector2(-17, -2), center + Vector2(-17, 12), Color.WHITE, 7)
		draw_line(center + Vector2(17, -2), center + Vector2(17, 12), Color.WHITE, 7)

	elif item == "shield":
		var shield = PackedVector2Array([
			center + Vector2(0, -22),
			center + Vector2(19, -14),
			center + Vector2(16, 9),
			center + Vector2(0, 23),
			center + Vector2(-16, 9),
			center + Vector2(-19, -14)
		])
		draw_colored_polygon(shield, Color.WHITE)

	elif item == "speed":
		var lightning = PackedVector2Array([
			center + Vector2(4, -23),
			center + Vector2(-15, 3),
			center + Vector2(-2, 3),
			center + Vector2(-7, 23),
			center + Vector2(16, -5),
			center + Vector2(3, -5)
		])
		draw_colored_polygon(lightning, Color.WHITE)

	elif item == "life":
		draw_string(
			ThemeDB.fallback_font,
			center + Vector2(-15, 14),
			"♥",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			38,
			Color.WHITE
		)


func draw_item_buttons():
	for item in item_order:
		var rect = item_use_buttons[item]
		var count = inventory[item]
		var button_color = Color("#2980b9") if count > 0 else Color("#777777")

		if item == "magnet" and magnet_timer > 0:
			button_color = Color("#d4a017")
		elif item == "speed" and speed_timer > 0:
			button_color = Color("#d35400")
		elif item == "shield" and shield_active:
			button_color = Color("#16a085")

		var style = StyleBoxFlat.new()
		style.bg_color = button_color

		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 14
		style.corner_radius_bottom_left = 14
		style.corner_radius_bottom_right = 14

		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(1, 1, 1, 0.75)

		draw_style_box(style, rect)

		var icon_center = Vector2(
			rect.position.x + rect.size.x / 2.0,
			rect.position.y + 23
		)

		draw_gameplay_item_icon(item, icon_center)

		var status_text = ""

		if item == "magnet":
			status_text = str(int(ceil(magnet_timer))) + "s" if magnet_timer > 0 else "MAGNET"
		elif item == "shield":
			status_text = "ACTIVE" if shield_active else "SHIELD"
		elif item == "speed":
			status_text = str(int(ceil(speed_timer))) + "s" if speed_timer > 0 else "SPEED"
		elif item == "life":
			status_text = "EXTRA LIFE"

		draw_string(
			ThemeDB.fallback_font,
			Vector2(rect.position.x, rect.position.y + 49),
			status_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			14,
			Color.WHITE
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(rect.position.x, rect.position.y + 66),
			"x" + str(count),
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			12,
			Color("#fff3a3")
		)


# =====================================================
# MAZE DRAWING - THIN CORRIDOR WALLS
# =====================================================

func draw_maze_wall_cell(cell: Vector2i):
	var center = maze_cell_center(cell) + maze_camera_offset
	var half = maze_cell_size * 0.5
	var thickness = maxf(4.0, maze_cell_size * 0.13)

	var wall_color = Color("#344d68")
	var highlight_color = Color("#607c98")

	# Center of the wall cell.
	draw_rect(
		Rect2(
			center - Vector2(thickness, thickness) * 0.5,
			Vector2(thickness, thickness)
		),
		wall_color
	)

	# Connect neighboring wall cells to form continuous thin walls.
	if cell.x > 0 and maze_grid[cell.y][cell.x - 1] == 1:
		draw_rect(
			Rect2(
				center + Vector2(-half, -thickness * 0.5),
				Vector2(half, thickness)
			),
			wall_color
		)

	if cell.x < maze_cols - 1 and maze_grid[cell.y][cell.x + 1] == 1:
		draw_rect(
			Rect2(
				center + Vector2(0, -thickness * 0.5),
				Vector2(half, thickness)
			),
			wall_color
		)

	if cell.y > 0 and maze_grid[cell.y - 1][cell.x] == 1:
		draw_rect(
			Rect2(
				center + Vector2(-thickness * 0.5, -half),
				Vector2(thickness, half)
			),
			wall_color
		)

	if cell.y < maze_rows - 1 and maze_grid[cell.y + 1][cell.x] == 1:
		draw_rect(
			Rect2(
				center + Vector2(-thickness * 0.5, 0),
				Vector2(thickness, half)
			),
			wall_color
		)

	# Small highlight for a slightly raised wall appearance.
	draw_rect(
		Rect2(
			center - Vector2(thickness * 0.25, thickness * 0.25),
			Vector2(thickness * 0.5, thickness * 0.5)
		),
		highlight_color
	)


func draw_maze():
	var viewport_rect = get_maze_viewport_rect()

	# Background outside the maze camera.
	draw_rect(
		Rect2(Vector2.ZERO, screen_size),
		Color("#101c2b")
	)

	# Maze viewing area.
	draw_rect(
		viewport_rect,
		Color("#dce5ed")
	)

	# Draw a consistent floor across the maze.
	for y in range(maze_rows):
		for x in range(maze_cols):
			var cell_rect = Rect2(
				maze_origin
				+ Vector2(x * maze_cell_size, y * maze_cell_size)
				+ maze_camera_offset,
				Vector2(maze_cell_size, maze_cell_size)
			)

			if not cell_rect.intersects(viewport_rect):
				continue

			if maze_grid[y][x] == 0:
				draw_rect(cell_rect, Color("#f5f7fa"))
			else:
				# Wall cells use the same floor base.
				# The thin wall lines are drawn separately below.
				draw_rect(cell_rect, Color("#f5f7fa"))

	# Draw thin connected wall lines.
	for y in range(maze_rows):
		for x in range(maze_cols):
			if maze_grid[y][x] != 1:
				continue

			var cell = Vector2i(x, y)
			var cell_rect = Rect2(
				maze_origin
				+ Vector2(x * maze_cell_size, y * maze_cell_size)
				+ maze_camera_offset,
				Vector2(maze_cell_size, maze_cell_size)
			)

			if not cell_rect.intersects(viewport_rect):
				continue

			draw_maze_wall_cell(cell)

	# Draw the fixed exit.
	var exit_position = maze_cell_center(maze_exit_cell) + maze_camera_offset
	var exit_rect = Rect2(
		exit_position - Vector2.ONE * maze_cell_size * 0.5,
		Vector2.ONE * maze_cell_size
	)

	if exit_rect.intersects(viewport_rect):
		var exit_alpha = 1.0 - get_maze_fog_alpha(maze_exit_cell)

		if exit_alpha > 0.01:
			var exit_color = Color("#20bf6b")
			exit_color.a = exit_alpha

			draw_circle(
				exit_position,
				maze_cell_size * 0.38,
				exit_color
			)

			var inner_exit_color = Color("#aaffc3")
			inner_exit_color.a = exit_alpha

			draw_circle(
				exit_position,
				maze_cell_size * 0.25,
				inner_exit_color
			)

			var exit_text_color = Color("#14532d")
			exit_text_color.a = exit_alpha

			draw_string(
				ThemeDB.fallback_font,
				exit_position + Vector2(-8, 7),
				"E",
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				18,
				exit_text_color
			)

	# Player stays centered in the camera.
	draw_character(
		maze_player_position + maze_camera_offset,
		maze_is_moving,
		maze_cell_size / 85.0
	)

	# Persistent fog overlay.
	for y in range(maze_rows):
		for x in range(maze_cols):
			var cell = Vector2i(x, y)

			var cell_rect = Rect2(
				maze_origin
				+ Vector2(x * maze_cell_size, y * maze_cell_size)
				+ maze_camera_offset,
				Vector2(maze_cell_size, maze_cell_size)
			)

			if not cell_rect.intersects(viewport_rect):
				continue

			var fog_alpha = get_maze_fog_alpha(cell)

			if fog_alpha > 0.01:
				draw_rect(
					cell_rect,
					Color(0.055, 0.09, 0.15, fog_alpha * 0.96)
				)

	# Camera frame.
	draw_rect(
		viewport_rect,
		Color("#607c98"),
		false,
		3.0
	)


func draw_maze_hud():
	draw_hud_panel(
		Rect2(25, 25, screen_size.x - 50, 125),
		Color(0.05, 0.15, 0.22, 0.92)
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 65),
		"MAZE LEVEL " + str(maze_level),
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		32,
		Color("#ffe66d")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 105),
		get_maze_difficulty(),
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		22,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 135),
		"REWARD: " + str(maze_reward) + " COINS",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		20,
		Color("#aaffc3")
	)

	if maze_vision_radius < 99:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(0, 175),
			"FOG OF WAR - EXPLORE TO REVEAL",
			HORIZONTAL_ALIGNMENT_CENTER,
			screen_size.x,
			15,
			Color("#bcecff")
		)


func draw_daily_rewards():
	draw_rect(
		Rect2(Vector2.ZERO, screen_size),
		Color("#14283b")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 115),
		"DAILY REWARDS",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		46,
		Color("#ffe66d")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 155),
		"COME BACK EVERY DAY FOR FREE COINS!",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		17,
		Color("#d7ecff")
	)

	var today_claimed = not can_claim_daily_reward()
	var display_day = daily_next_day

	if today_claimed:
		display_day = daily_next_day - 1
		if display_day < 1:
			display_day = 7

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 225),
		"7-DAY REWARD CYCLE",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		25,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 190),
		"CURRENT STREAK: " + str(daily_streak) + " DAYS",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		23,
		Color("#ffad42")
	)

	var card_width = 145.0
	var card_height = 145.0
	var gap = 15.0
	var total_width = card_width * 2.0 + gap
	var start_x = (screen_size.x - total_width) / 2.0

	for i in range(7):
		var row = int(i / 2)
		var col = i % 2
		if i == 6:
			row = 3
			col = 0

		var card_position = Vector2(
			start_x + col * (card_width + gap),
			265 + row * 155
		)

		var card_rect = Rect2(card_position, Vector2(card_width, card_height))
		var is_claimed = today_claimed and i < display_day
		var is_today = i == daily_next_day - 1 and not today_claimed

		var card_color = Color("#28465d")
		if is_claimed:
			card_color = Color("#245c48")
		elif is_today:
			card_color = Color("#73551f")
		elif i == 6:
			card_color = Color("#60417d")

		draw_shop_panel(card_rect, card_color)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(card_position.x, card_position.y + 34),
			"DAY " + str(i + 1),
			HORIZONTAL_ALIGNMENT_CENTER,
			card_width,
			21,
			Color("#ffe66d")
		)

		draw_circle(
			card_position + Vector2(card_width / 2.0, 77),
			22,
			Color("#d99b00")
		)
		draw_circle(
			card_position + Vector2(card_width / 2.0, 77),
			16,
			Color("#ffe66d")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(card_position.x, card_position.y + 119),
			str(daily_rewards[i]) + " COINS",
			HORIZONTAL_ALIGNMENT_CENTER,
			card_width,
			20,
			Color.WHITE
		)

		if is_claimed:
			draw_string(
				ThemeDB.fallback_font,
				Vector2(card_position.x, card_position.y + 139),
				"CLAIMED",
				HORIZONTAL_ALIGNMENT_CENTER,
				card_width,
				13,
				Color("#aaffc3")
			)
		elif is_today:
			draw_string(
				ThemeDB.fallback_font,
				Vector2(card_position.x, card_position.y + 139),
				"AVAILABLE",
				HORIZONTAL_ALIGNMENT_CENTER,
				card_width,
				13,
				Color("#ffe66d")
			)

	if today_claimed:
		draw_button(
			daily_claim_button,
			"CLAIMED TODAY",
			Color("#59636e")
		)
	else:
		draw_button(
			daily_claim_button,
			"CLAIM " + str(daily_rewards[daily_next_day - 1]) + " COINS",
			Color("#27ae60")
		)

	draw_button(daily_back_button, "BACK", Color("#c0392b"))

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, screen_size.y - 55),
		"STREAK BONUS: 7 DAYS +100 | 14 DAYS +250 | 30 DAYS +500",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		14,
		Color("#ffad42")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, screen_size.y - 25),
		"DAY 7 BONUS: 200 COINS",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		16,
		Color("#dcb5ff")
	)


func draw_maze_menu():
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 240),
		"MAZE ADVENTURE",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		45,
		Color("#ffe66d")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 340),
		"99 LEVELS",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		35,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 410),
		"UNLOCKED LEVEL: " + str(unlocked_maze_level),
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		26,
		Color("#aaffc3")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 470),
		"DIFFICULTY: " + get_maze_difficulty(),
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		24,
		Color.WHITE
	)

	draw_button(
		maze_play_button,
		"PLAY LEVEL " + str(unlocked_maze_level),
		Color("#8e44ad")
	)

	draw_button(maze_back_button, "BACK", Color("#c0392b"))


func draw_maze_complete():
	draw_rect(
		Rect2(Vector2.ZERO, screen_size),
		Color(0, 0, 0, 0.78)
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, screen_size.y * 0.30),
		"LEVEL COMPLETE!",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		48,
		Color("#ffe66d")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, screen_size.y * 0.40),
		"LEVEL " + str(maze_level),
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		32,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, screen_size.y * 0.48),
		"+" + str(maze_reward) + " COINS!",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		35,
		Color("#aaffc3")
	)

	if maze_level < 99:
		draw_button(
			maze_next_button,
			"NEXT LEVEL",
			Color("#27ae60")
		)
	else:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(0, screen_size.y * 0.58),
			"YOU COMPLETED ALL 99 LEVELS!",
			HORIZONTAL_ALIGNMENT_CENTER,
			screen_size.x,
			22,
			Color("#ffe66d")
		)

	draw_button(
		maze_select_button,
		"LEVEL SELECT",
		Color("#8e44ad")
	)


# =====================================================
# BACKGROUND
# =====================================================

func draw_background():
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#78d7ff"))

	draw_circle(
		Vector2(screen_size.x - 85, 120),
		55,
		Color("#ffe66d")
	)

	for cloud_pos in [
		Vector2(100, 150),
		Vector2(350, 230),
		Vector2(550, 110)
	]:
		draw_circle(cloud_pos, 30, Color.WHITE)
		draw_circle(cloud_pos + Vector2(30, 5), 25, Color.WHITE)
		draw_circle(cloud_pos + Vector2(-30, 8), 22, Color.WHITE)

	var hills = PackedVector2Array([
		Vector2(0, 390),
		Vector2(150, 270),
		Vector2(300, 390),
		Vector2(470, 260),
		Vector2(720, 400),
		Vector2(720, 1280),
		Vector2(0, 1280)
	])

	draw_colored_polygon(hills, Color("#80c96b"))

	draw_rect(
		Rect2(0, 400, screen_size.x, screen_size.y - 400),
		Color("#65bd55")
	)

	for i in range(90):
		var x = float((i * 83) % int(screen_size.x))
		var y = float(420 + (i * 137) % int(screen_size.y - 450))

		draw_line(
			Vector2(x, y),
			Vector2(x + 5, y - 9),
			Color("#8cdb69"),
			3
		)

	for tree_pos in [
		Vector2(35, 350),
		Vector2(675, 430),
		Vector2(45, 750),
		Vector2(680, 850),
		Vector2(40, 1100)
	]:
		draw_rect(
			Rect2(tree_pos.x - 7, tree_pos.y, 14, 45),
			Color("#85502e")
		)

		draw_circle(tree_pos + Vector2(0, -12), 32, Color("#258b43"))
		draw_circle(tree_pos + Vector2(-15, -25), 20, Color("#38a852"))

func draw_achievements():
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#14283b"))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 105),
		"ACHIEVEMENTS",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		44,
		Color("#ffe66d")
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 145),
		"COIN COLLECTOR MILESTONES",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		20,
		Color("#d7ecff")
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 190),
		"TOTAL COINS COLLECTED: " + format_achievement_number(total_coins_collected),
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		23,
		Color("#ffe66d")
	)

	var card_width = (screen_size.x - 55.0) / 2.0
	var card_height = 205.0
	var gap_x = 15.0
	var gap_y = 18.0
	var start_x = 10.0
	var start_y = 225.0
	var start_index = achievement_page * 6

	for slot in range(6):
		var index = start_index + slot
		if index >= coin_achievement_thresholds.size():
			break

		var col = slot % 2
		var row = int(slot / 2)
		var card_pos = Vector2(
			start_x + col * (card_width + gap_x),
			start_y + row * (card_height + gap_y)
		)
		var card_rect = Rect2(card_pos, Vector2(card_width, card_height))
		var target = coin_achievement_thresholds[index]
		var reward = coin_achievement_rewards[index]
		var unlocked = total_coins_collected >= target
		var card_color = Color("#28465d")
		if unlocked:
			card_color = Color("#245c48")
		draw_shop_panel(card_rect, card_color)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(card_pos.x, card_pos.y + 38),
			"COIN COLLECTOR " + str(index + 1),
			HORIZONTAL_ALIGNMENT_CENTER,
			card_width,
			18,
			Color("#ffe66d")
		)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(card_pos.x, card_pos.y + 82),
			format_achievement_number(target) + " COINS",
			HORIZONTAL_ALIGNMENT_CENTER,
			card_width,
			27,
			Color.WHITE
		)

		var progress = minf(1.0, float(total_coins_collected) / float(target))
		var bar_rect = Rect2(card_pos.x + 18, card_pos.y + 105, card_width - 36, 13)
		draw_rect(bar_rect, Color("#172a38"), true, 6.0)
		draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * progress, bar_rect.size.y)), Color("#45d483"), true, 6.0)

		var status_text = "REWARD: +" + format_achievement_number(reward) + " COINS"
		if unlocked:
			status_text += "  |  UNLOCKED"
		else:
			status_text += "  |  " + format_achievement_number(total_coins_collected) + "/" + format_achievement_number(target)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(card_pos.x + 5, card_pos.y + 155),
			status_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			card_width - 10,
			14,
			Color("#aaffc3") if unlocked else Color("#d7ecff")
		)

	var total_pages = int(ceil(float(coin_achievement_thresholds.size()) / 6.0))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, screen_size.y - 245),
		"PAGE " + str(achievement_page + 1) + " / " + str(total_pages),
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		18,
		Color.WHITE
	)
	if achievement_page > 0:
		draw_button(achievement_previous_button, "PREVIOUS", Color("#2980b9"))
	if (achievement_page + 1) * 6 < coin_achievement_thresholds.size():
		draw_button(achievement_next_button, "NEXT", Color("#2980b9"))
	draw_button(achievement_back_button, "BACK", Color("#c0392b"))


# =====================================================
# MAIN DRAWING
# =====================================================

func _draw():
	draw_background()
	var center = screen_size.x / 2.0

	if state == "menu":
		draw_music_button()

		draw_string(
			ThemeDB.fallback_font,
			Vector2(0, screen_size.y * 0.27),
			"COIN COLLECTOR",
			HORIZONTAL_ALIGNMENT_CENTER,
			screen_size.x,
			55,
			Color("#f1c40f")
		)

		draw_character(Vector2(center, screen_size.y * 0.37), false, 0.9)

		var coin_bob = sin(animation_time * 3.0) * 5.0

		draw_circle(
			Vector2(center - 65, screen_size.y * 0.37 + coin_bob),
			18,
			Color("#f1c40f")
		)

		draw_circle(
			Vector2(center + 65, screen_size.y * 0.37 - coin_bob),
			18,
			Color("#f1c40f")
		)

		draw_button(play_button, "PLAY", Color("#27ae60"))
		draw_button(shop_button, "SHOP", Color("#d68910"))

		var daily_label = "DAILY REWARDS"
		if not can_claim_daily_reward():
			daily_label = "DAILY REWARDS - CLAIMED"
		draw_button(
			daily_reward_button,
			daily_label,
			Color("#8e44ad")
		)
		draw_button(achievement_button, "ACHIEVEMENTS", Color("#2471a3"))

		draw_string(
			ThemeDB.fallback_font,
			Vector2(0, screen_size.y * 0.89),
			"BEST SCORE: " + str(best_score),
			HORIZONTAL_ALIGNMENT_CENTER,
			screen_size.x,
			28,
			Color.WHITE
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(0, screen_size.y * 0.94),
			"WALLET: " + str(wallet_coins) + " COINS",
			HORIZONTAL_ALIGNMENT_CENTER,
			screen_size.x,
			25,
			Color("#ffe66d")
		)

	elif state == "mode_select":
		draw_music_button()

		draw_string(
			ThemeDB.fallback_font,
			Vector2(0, screen_size.y * 0.27),
			"CHOOSE YOUR MODE",
			HORIZONTAL_ALIGNMENT_CENTER,
			screen_size.x,
			42,
			Color("#ffe66d")
		)

		draw_button(classic_mode_button, "CLASSIC MODE", Color("#27ae60"))
		draw_button(maze_mode_button, "MAZE MODE", Color("#8e44ad"))
		draw_button(mode_back_button, "BACK", Color("#c0392b"))

	elif state == "daily_rewards":
		draw_daily_rewards()

	elif state == "achievements":
		draw_achievements()

	elif state == "maze_menu":
		draw_maze_menu()

	elif state == "maze_playing":
		draw_maze()
		draw_maze_hud()
		draw_joystick()

	elif state == "maze_complete":
		draw_maze()
		draw_maze_complete()

	elif state == "shop":
		draw_shop()

	elif state == "playing" or state == "paused":
		draw_rocks()

		for i in range(coins.size()):
			var coin = coins[i]
			var bob = sin(animation_time * 3.0 + i * 1.7) * 5.0
			var squash = absf(cos(animation_time * 4.0 + i)) * 0.65 + 0.35

			draw_set_transform(
				coin + Vector2(0, bob),
				animation_time * 0.5,
				Vector2(squash, 1.0)
			)

			draw_circle(Vector2.ZERO, 20, Color("#d99b00"))
			draw_circle(Vector2.ZERO, 16, Color("#f1c40f"))
			draw_circle(Vector2.ZERO, 10, Color("#ffe680"))

			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		if invulnerability_timer <= 0 or int(Time.get_ticks_msec() / 100) % 2 == 0:
			draw_character(player_position, is_moving, 1.0)

		draw_collection_effects()
		draw_hud()
		draw_music_button()
		draw_button(pause_button, "II", Color("#2980b9"))
		draw_item_buttons()
		draw_joystick()

		if state == "paused":
			draw_rect(
				Rect2(Vector2.ZERO, screen_size),
				Color(0, 0, 0, 0.75)
			)

			draw_string(
				ThemeDB.fallback_font,
				Vector2(0, screen_size.y * 0.30),
				"PAUSED",
				HORIZONTAL_ALIGNMENT_CENTER,
				screen_size.x,
				55,
				Color.WHITE
			)

			draw_button(resume_button, "RESUME", Color("#27ae60"))
			draw_button(restart_button, "RESTART", Color("#2980b9"))
			draw_button(home_button, "MAIN MENU", Color("#c0392b"))
			draw_music_button()

	elif state == "game_over":
		draw_string(
			ThemeDB.fallback_font,
			Vector2(0, screen_size.y * 0.29),
			"GAME OVER!",
			HORIZONTAL_ALIGNMENT_CENTER,
			screen_size.x,
			55,
			Color("#ff5555")
		)

		draw_character(Vector2(center, screen_size.y * 0.39), false, 1.0)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(0, screen_size.y * 0.48),
			"COINS: " + str(score),
			HORIZONTAL_ALIGNMENT_CENTER,
			screen_size.x,
			34,
			Color.WHITE
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(0, screen_size.y * 0.53),
			"WALLET: " + str(wallet_coins),
			HORIZONTAL_ALIGNMENT_CENTER,
			screen_size.x,
			26,
			Color("#ffe66d")
		)

		draw_button(restart_button, "TRY AGAIN", Color("#27ae60"))
		draw_button(home_button, "MAIN MENU", Color("#c0392b"))
		draw_music_button()

	# Fade transition
	if transition_alpha < 1.0:
		draw_rect(
			Rect2(Vector2.ZERO, screen_size),
			Color(0, 0, 0, 1.0 - transition_alpha)
		)
