
extends Node2D

var screen_size = Vector2(720, 1280)
var player_position = Vector2.ZERO
var player_speed = 350.0
var coins: Array[Vector2] = []

var score = 0
var best_score = 0
var lives = 3
var max_lives = 5
var wallet_coins = 0

var state = "menu"
var animation_time = 0.0
var is_moving = false

# Smooth UI animations
var transition_alpha = 1.0
var ui_button_scale = 1.0
var ui_tween: Tween

# Animated HUD counters
var display_score = 0.0
var display_wallet = 0.0
var hud_pulse_timer = 0.0

# Virtual joystick
var joystick_center = Vector2.ZERO
var joystick_vector = Vector2.ZERO
var joystick_radius = 82.0
var joystick_active = false
var joystick_touch_index = -1
var joystick_mouse_active = false

var particles: Array[Dictionary] = []
var floating_texts: Array[Dictionary] = []

# Falling rocks
var rocks: Array[Dictionary] = []
var rock_spawn_timer = 1.5
var rock_spawn_interval = 4.0
var invulnerability_timer = 0.0

# Shop inventory
var inventory = {
	"magnet": 0,
	"shield": 0,
	"speed": 0,
	"life": 0
}

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

var item_order = ["magnet", "shield", "speed", "life"]
var item_buy_buttons = {}
var item_use_buttons = {}

var magnet_timer = 0.0
var speed_timer = 0.0
var shield_active = false

var play_button = Rect2()
var shop_button = Rect2()
var shop_back_button = Rect2()
var pause_button = Rect2()
var resume_button = Rect2()
var restart_button = Rect2()
var home_button = Rect2()
var music_button = Rect2()

# Audio
var coin_sound_player: AudioStreamPlayer
var button_sound_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var music_enabled = true


func _ready():
	randomize()
	screen_size = get_viewport_rect().size
	load_best_score()
	load_shop_data()

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
	tween.tween_property(self, "transition_alpha", 1.0, 0.35)


func animate_button_press():
	if ui_tween and ui_tween.is_running():
		ui_tween.kill()

	ui_button_scale = 1.0
	ui_tween = create_tween()
	ui_tween.tween_property(self, "ui_button_scale", 0.94, 0.07)
	ui_tween.tween_property(self, "ui_button_scale", 1.0, 0.13)


func update_buttons():
	var center = screen_size.x / 2

	joystick_center = Vector2(center, screen_size.y - 140)

	play_button = Rect2(center - 140, screen_size.y * 0.51, 280, 80)
	shop_button = Rect2(center - 140, screen_size.y * 0.62, 280, 80)
	shop_back_button = Rect2(center - 140, screen_size.y - 145, 280, 75)

	pause_button = Rect2(screen_size.x - 105, 25, 80, 65)
	music_button = Rect2(screen_size.x - 205, 25, 90, 65)

	resume_button = Rect2(center - 140, screen_size.y * 0.38, 280, 75)
	restart_button = Rect2(center - 140, screen_size.y * 0.51, 280, 75)
	home_button = Rect2(center - 140, screen_size.y * 0.64, 280, 75)

	item_buy_buttons.clear()
	item_use_buttons.clear()

	for i in range(item_order.size()):
		var item = item_order[i]
		var card_y = 215 + i * 185

		item_buy_buttons[item] = Rect2(
			screen_size.x - 190,
			card_y + 65,
			165,
			65
		)

		item_use_buttons[item] = Rect2(
			screen_size.x - 125,
			230 + i * 88,
			110,
			70
		)


# AUDIO SYSTEM

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


# SAVING SYSTEM

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


# SHOP SYSTEM

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


# GAME SETUP

func start_game():
	score = 0
	lives = 3

	display_score = 0.0

	coins.clear()
	rocks.clear()
	particles.clear()
	floating_texts.clear()

	player_position = screen_size / 2
	is_moving = false

	joystick_active = false
	joystick_vector = Vector2.ZERO
	joystick_touch_index = -1
	joystick_mouse_active = false

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


# FALLING ROCK SYSTEM

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
	joystick_active = false
	joystick_vector = Vector2.ZERO

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


# COLLECTION EFFECTS

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


# COIN COLLECTION

func collect_coin(index: int):
	var collected_position = coins[index]

	coins.remove_at(index)
	create_collection_effect(collected_position)
	play_coin_sound()

	score += 1
	wallet_coins += 1
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
				coins[i] = coins[i].move_toward(player_position, 550.0 * delta)

		if player_position.distance_to(coins[i]) < 50:
			collect_coin(i)


# JOYSTICK SYSTEM

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

	draw_circle(
		knob_position,
		32,
		Color("#3498db")
	)

	draw_arc(
		knob_position,
		32,
		0,
		TAU,
		48,
		Color.WHITE,
		4
	)


# MODERN HUD

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

	# Score and wallet panel
	draw_hud_panel(
		score_panel,
		Color(0.05, 0.20, 0.25, 0.88)
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(43, 59),
		"COINS COLLECTED",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		17,
		Color("#bcecff")
	)

	draw_set_transform(
		Vector2(43, 101),
		0.0,
		Vector2(pulse, pulse)
	)

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

	# Lives panel
	draw_hud_panel(
		lives_panel,
		Color(0.25, 0.08, 0.12, 0.88)
	)

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


# GAME LOOP

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

	player_position.x = clampf(player_position.x, 40, screen_size.x - 40)
	player_position.y = clampf(player_position.y, 140, screen_size.y - 45)

	update_coins(delta)

	queue_redraw()


# INPUT

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if state == "playing" and is_joystick_area(event.position):
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
				if state == "playing" and is_joystick_area(event.position):
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


func handle_press(pos):
	if state == "menu":
		if music_button.has_point(pos):
			play_button_sound()
			toggle_music()

		elif play_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			start_game()

		elif shop_button.has_point(pos):
			play_button_sound()
			animate_button_press()
			change_state("shop")

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


# CHARACTER

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


# ROCK DRAWING

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


# EFFECT DRAWING

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


# BUTTON DRAWING

func draw_button(rect: Rect2, label: String, color: Color):
	var center = rect.position + rect.size / 2
	var scaled_size = rect.size * ui_button_scale

	var scaled_rect = Rect2(
		center - scaled_size / 2,
		scaled_size
	)

	draw_rect(scaled_rect, color)
	draw_rect(scaled_rect, Color.WHITE, false, 3)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(scaled_rect.position.x, scaled_rect.position.y + scaled_rect.size.y / 2 + 10),
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


func draw_shop():
	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 100),
		"ITEM SHOP",
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		48,
		Color("#f1c40f")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(0, 155),
		"YOUR COINS: " + str(wallet_coins),
		HORIZONTAL_ALIGNMENT_CENTER,
		screen_size.x,
		30,
		Color.WHITE
	)

	for i in range(item_order.size()):
		var item = item_order[i]
		var card_y = 215 + i * 185
		var card = Rect2(20, card_y, screen_size.x - 40, 155)

		draw_rect(card, Color("#286b48"))
		draw_rect(card, Color.WHITE, false, 3)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(40, card_y + 42),
			item_names[item],
			HORIZONTAL_ALIGNMENT_LEFT,
			300,
			25,
			Color("#ffe66d")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(40, card_y + 78),
			item_descriptions[item],
			HORIZONTAL_ALIGNMENT_LEFT,
			300,
			17,
			Color.WHITE
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(40, card_y + 120),
			"OWNED: " + str(inventory[item]),
			HORIZONTAL_ALIGNMENT_LEFT,
			300,
			22,
			Color("#aaffaa")
		)

		var price = item_prices[item]
		var can_afford = wallet_coins >= price
		var button_color = Color("#27ae60") if can_afford else Color("#777777")

		draw_button(
			item_buy_buttons[item],
			str(price) + " COINS",
			button_color
		)

	draw_button(shop_back_button, "BACK", Color("#c0392b"))


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

		draw_rect(rect, button_color)
		draw_rect(rect, Color.WHITE, false, 2)

		var label = item_names[item]

		if item == "magnet":
			label = "MAGNET"
			if magnet_timer > 0:
				label = str(int(ceil(magnet_timer))) + "s"

		elif item == "shield":
			label = "SHIELD"
			if shield_active:
				label = "ACTIVE"

		elif item == "speed":
			label = "SPEED"
			if speed_timer > 0:
				label = str(int(ceil(speed_timer))) + "s"

		elif item == "life":
			label = "LIFE"

		draw_string(
			ThemeDB.fallback_font,
			Vector2(rect.position.x, rect.position.y + 27),
			label,
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			17,
			Color.WHITE
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(rect.position.x, rect.position.y + 53),
			"OWNED: " + str(count),
			HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x,
			14,
			Color.WHITE
		)


# BACKGROUND

func draw_background():
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#78d7ff"))
	draw_circle(Vector2(screen_size.x - 85, 120), 55, Color("#ffe66d"))

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


# MAIN DRAWING

func _draw():
	draw_background()

	var center = screen_size.x / 2

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
		draw_circle(Vector2(center - 65, screen_size.y * 0.37 + coin_bob), 18, Color("#f1c40f"))
		draw_circle(Vector2(center + 65, screen_size.y * 0.37 - coin_bob), 18, Color("#f1c40f"))

		draw_button(play_button, "PLAY", Color("#27ae60"))
		draw_button(shop_button, "SHOP", Color("#d68910"))

		draw_string(
			ThemeDB.fallback_font,
			Vector2(0, screen_size.y * 0.77),
			"BEST SCORE: " + str(best_score),
			HORIZONTAL_ALIGNMENT_CENTER,
			screen_size.x,
			28,
			Color.WHITE
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(0, screen_size.y * 0.82),
			"WALLET: " + str(wallet_coins) + " COINS",
			HORIZONTAL_ALIGNMENT_CENTER,
			screen_size.x,
			25,
			Color("#ffe66d")
		)

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

		# New modern HUD
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

	# Fade in the current screen
	if transition_alpha < 1.0:
		draw_rect(
			Rect2(Vector2.ZERO, screen_size),
			Color(0, 0, 0, 1.0 - transition_alpha)
		)
