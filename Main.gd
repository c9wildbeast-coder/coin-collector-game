
extends Node2D

var screen_size = Vector2(720, 1280)
var player_position = Vector2.ZERO
var player_speed = 350.0
var player_radius = 25.0

var coins: Array[Vector2] = []
var score = 0
var best_score = 0

var state = "menu"
var touch_target: Variant = null

var play_button = Rect2()
var pause_button = Rect2()
var resume_button = Rect2()
var restart_button = Rect2()
var home_button = Rect2()

func _ready():
    randomize()
    screen_size = get_viewport_rect().size
    load_best_score()
    update_buttons()
    queue_redraw()

func update_buttons():
    var center = screen_size.x / 2
    play_button = Rect2(center - 140, screen_size.y * 0.53, 280, 85)
    pause_button = Rect2(screen_size.x - 105, 25, 80, 65)
    resume_button = Rect2(center - 140, screen_size.y * 0.43, 280, 75)
    restart_button = Rect2(center - 140, screen_size.y * 0.54, 280, 75)
    home_button = Rect2(center - 140, screen_size.y * 0.65, 280, 75)

func start_game():
    score = 0
    coins.clear()
    player_position = screen_size / 2
    touch_target = null

    for i in range(10):
        spawn_coin()

    state = "playing"

func save_best_score():
    var file = FileAccess.open("user://coin_save.cfg", FileAccess.WRITE)
    if file:
        file.store_32(best_score)

func load_best_score():
    if FileAccess.file_exists("user://coin_save.cfg"):
        var file = FileAccess.open("user://coin_save.cfg", FileAccess.READ)
        if file:
            best_score = file.get_32()

func spawn_coin():
    var margin = 60.0
    var coin = Vector2(
        randf_range(margin, screen_size.x - margin),
        randf_range(150, screen_size.y - margin)
    )
    coins.append(coin)

func _process(delta):
    if state != "playing":
        queue_redraw()
        return

    var direction = Input.get_vector(
        "ui_left", "ui_right",
        "ui_up", "ui_down"
    )

    if touch_target != null:
        if player_position.distance_to(touch_target) > 10:
            direction = player_position.direction_to(touch_target)

    player_position += direction * player_speed * delta

    player_position.x = clampf(player_position.x, 30, screen_size.x - 30)
    player_position.y = clampf(player_position.y, 120, screen_size.y - 30)

    for i in range(coins.size() - 1, -1, -1):
        if player_position.distance_to(coins[i]) < 45:
            coins.remove_at(i)
            score += 1

            if score > best_score:
                best_score = score
                save_best_score()

            spawn_coin()

    queue_redraw()

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            handle_press(event.position)
        else:
            touch_target = null

    elif event is InputEventScreenDrag:
        if state == "playing":
            touch_target = event.position

    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                handle_press(event.position)
            else:
                touch_target = null

    elif event is InputEventMouseMotion:
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            if state == "playing":
                touch_target = event.position

func handle_press(pos):
    if state == "menu":
        if play_button.has_point(pos):
            start_game()

    elif state == "playing":
        if pause_button.has_point(pos):
            state = "paused"
            touch_target = null
        else:
            touch_target = pos

    elif state == "paused":
        if resume_button.has_point(pos):
            state = "playing"
        elif restart_button.has_point(pos):
            start_game()
        elif home_button.has_point(pos):
            state = "menu"

func draw_button(rect, label, color):
    draw_rect(rect, color)
    draw_rect(rect, Color.WHITE, false, 3)

    draw_string(
        ThemeDB.fallback_font,
        Vector2(rect.position.x, rect.position.y + rect.size.y / 2 + 10),
        label,
        HORIZONTAL_ALIGNMENT_CENTER,
        rect.size.x,
        32,
        Color.WHITE
    )

func draw_background():
    draw_rect(
        Rect2(Vector2.ZERO, screen_size),
        Color("#17252b")
    )

    for x in range(0, int(screen_size.x), 60):
        draw_line(
            Vector2(x, 0),
            Vector2(x, screen_size.y),
            Color("#24363c"), 1
        )

    for y in range(0, int(screen_size.y), 60):
        draw_line(
            Vector2(0, y),
            Vector2(screen_size.x, y),
            Color("#24363c"), 1
        )

func _draw():
    draw_background()

    var center = screen_size.x / 2

    if state == "menu":
        draw_string(
            ThemeDB.fallback_font,
            Vector2(0, screen_size.y * 0.29),
            "COIN COLLECTOR",
            HORIZONTAL_ALIGNMENT_CENTER,
            screen_size.x,
            55,
            Color("#f1c40f")
        )

        draw_circle(Vector2(center, screen_size.y * 0.39), 35, Color("#3498db"))
        draw_circle(Vector2(center - 65, screen_size.y * 0.39), 18, Color("#f1c40f"))
        draw_circle(Vector2(center + 65, screen_size.y * 0.39), 18, Color("#f1c40f"))

        draw_button(play_button, "PLAY", Color("#27ae60"))

        draw_string(
            ThemeDB.fallback_font,
            Vector2(0, screen_size.y * 0.70),
            "BEST SCORE: " + str(best_score),
            HORIZONTAL_ALIGNMENT_CENTER,
            screen_size.x,
            28,
            Color.WHITE
        )

        draw_string(
            ThemeDB.fallback_font,
            Vector2(0, screen_size.y * 0.76),
            "Collect coins and beat your record!",
            HORIZONTAL_ALIGNMENT_CENTER,
            screen_size.x,
            19,
            Color("#bdc3c7")
        )

    elif state == "playing" or state == "paused":
        for coin in coins:
            draw_circle(coin, 20, Color("#f1c40f"))
            draw_circle(coin, 12, Color("#ffe680"))

        draw_circle(player_position, player_radius, Color("#3498db"))
        draw_circle(player_position, 13, Color("#85d6ff"))

        draw_string(
            ThemeDB.fallback_font,
            Vector2(25, 65),
            "COINS: " + str(score),
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            34,
            Color.WHITE
        )

        draw_string(
            ThemeDB.fallback_font,
            Vector2(25, 100),
            "BEST: " + str(best_score),
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            23,
            Color("#f1c40f")
        )

        draw_button(pause_button, "II", Color("#2980b9"))

        if state == "paused":
            draw_rect(
                Rect2(Vector2.ZERO, screen_size),
                Color(0, 0, 0, 0.75)
            )

            draw_string(
                ThemeDB.fallback_font,
                Vector2(0, screen_size.y * 0.34),
                "PAUSED",
                HORIZONTAL_ALIGNMENT_CENTER,
                screen_size.x,
                55,
                Color.WHITE
            )

            draw_button(resume_button, "RESUME", Color("#27ae60"))
            draw_button(restart_button, "RESTART", Color("#2980b9"))
            draw_button(home_button, "MAIN MENU", Color("#c0392b"))
