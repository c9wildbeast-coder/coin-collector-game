
extends Node2D

var screen_size = Vector2(720, 1280)
var player_position = Vector2.ZERO
var player_speed = 350.0
var coins: Array[Vector2] = []

var score = 0
var best_score = 0

var state = "menu"
var touch_target: Variant = null

var animation_time = 0.0
var is_moving = false

var particles: Array[Dictionary] = []
var floating_texts: Array[Dictionary] = []

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
    particles.clear()
    floating_texts.clear()

    player_position = screen_size / 2
    touch_target = null
    is_moving = false

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

func create_collection_effect(pos: Vector2):
    # Sparkle particles
    for i in range(16):
        var angle = randf_range(0.0, TAU)
        var speed = randf_range(80.0, 230.0)

        var velocity = Vector2(
            cos(angle),
            sin(angle)
        ) * speed

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

    # Floating +1 text
    floating_texts.append({
        "position": pos + Vector2(0, -25),
        "life": 0.8,
        "max_life": 0.8
    })

func update_effects(delta):
    for i in range(particles.size() - 1, -1, -1):
        particles[i]["life"] -= delta

        particles[i]["position"] += (
            particles[i]["velocity"] * delta
        )

        particles[i]["velocity"] *= 0.96

        if particles[i]["life"] <= 0:
            particles.remove_at(i)

    for i in range(floating_texts.size() - 1, -1, -1):
        floating_texts[i]["life"] -= delta

        floating_texts[i]["position"] += Vector2(0, -65 * delta)

        if floating_texts[i]["life"] <= 0:
            floating_texts.remove_at(i)

func _process(delta):
    if state != "playing":
        queue_redraw()
        return

    update_effects(delta)

    var direction = Input.get_vector(
        "ui_left", "ui_right",
        "ui_up", "ui_down"
    )

    if touch_target != null:
        if player_position.distance_to(touch_target) > 10:
            direction = player_position.direction_to(touch_target)

    is_moving = direction.length() > 0.05

    if is_moving:
        animation_time += delta * 12.0
    else:
        animation_time += delta * 2.0

    player_position += direction * player_speed * delta

    player_position.x = clampf(player_position.x, 40, screen_size.x - 40)
    player_position.y = clampf(player_position.y, 140, screen_size.y - 45)

    for i in range(coins.size() - 1, -1, -1):
        if player_position.distance_to(coins[i]) < 50:
            var collected_position = coins[i]

            coins.remove_at(i)

            create_collection_effect(collected_position)

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

func draw_character(pos: Vector2, running: bool, scale_factor: float = 1.0):
    var swing = 0.0

    if running:
        swing = sin(animation_time) * 13.0

    draw_set_transform(pos, 0.0, Vector2.ONE * scale_factor)

    # Legs
    draw_line(Vector2(-8, 17), Vector2(-10 + swing, 34), Color("#202638"), 10)
    draw_line(Vector2(8, 17), Vector2(10 - swing, 34), Color("#202638"), 10)

    # Shoes
    draw_line(Vector2(-10 + swing, 34), Vector2(-19 + swing, 39), Color("#e74c3c"), 12)
    draw_line(Vector2(10 - swing, 34), Vector2(19 - swing, 39), Color("#e74c3c"), 12)

    draw_line(Vector2(-20 + swing, 43), Vector2(-10 + swing, 43), Color.WHITE, 3)
    draw_line(Vector2(10 - swing, 43), Vector2(20 - swing, 43), Color.WHITE, 3)

    # Arms
    draw_line(Vector2(-14, -7), Vector2(-24 - swing * 0.5, 7), Color("#b92e28"), 11)
    draw_line(Vector2(14, -7), Vector2(24 + swing * 0.5, 7), Color("#b92e28"), 11)

    # Hands
    draw_circle(Vector2(-24 - swing * 0.5, 8), 6, Color("#ffd0aa"))
    draw_circle(Vector2(24 + swing * 0.5, 8), 6, Color("#ffd0aa"))

    # Hoodie
    var body = PackedVector2Array([
        Vector2(-17, -15),
        Vector2(17, -15),
        Vector2(15, 20),
        Vector2(-15, 20)
    ])
    draw_colored_polygon(body, Color("#e53935"))

    draw_line(Vector2(0, -12), Vector2(0, 18), Color("#ff8a80"), 2)

    # Hood
    draw_arc(Vector2(0, -9), 18, PI, TAU, 32, Color("#a92725"), 5)

    # Ears
    draw_circle(Vector2(-18, -31), 6, Color("#ffd0aa"))
    draw_circle(Vector2(18, -31), 6, Color("#ffd0aa"))

    # Face
    draw_circle(Vector2(0, -32), 19, Color("#ffd0aa"))

    # Hair
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

    # Eyes
    draw_circle(Vector2(7, -32), 3.5, Color("#171717"))
    draw_circle(Vector2(-6, -32), 3.5, Color("#171717"))

    draw_circle(Vector2(8, -34), 1.2, Color.WHITE)
    draw_circle(Vector2(-5, -34), 1.2, Color.WHITE)

    # Smile
    draw_arc(Vector2(2, -23), 5, 0.2, PI - 0.2, 12, Color("#9b5142"), 1.5)

    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_collection_effects():
    # Draw sparkling particles
    for particle in particles:
        var life_ratio = particle["life"] / particle["max_life"]

        var color: Color = particle["color"]
        color.a = life_ratio

        draw_circle(
            particle["position"],
            particle["size"] * life_ratio,
            color
        )

    # Draw floating +1 text
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
    # Sky
    draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#78d7ff"))

    # Sun
    draw_circle(Vector2(screen_size.x - 85, 120), 55, Color("#ffe66d"))

    # Clouds
    for cloud_pos in [
        Vector2(100, 150),
        Vector2(350, 230),
        Vector2(550, 110)
    ]:
        draw_circle(cloud_pos, 30, Color.WHITE)
        draw_circle(cloud_pos + Vector2(30, 5), 25, Color.WHITE)
        draw_circle(cloud_pos + Vector2(-30, 8), 22, Color.WHITE)

    # Hills
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

    # Grass
    draw_rect(
        Rect2(0, 400, screen_size.x, screen_size.y - 400),
        Color("#65bd55")
    )

    # Grass details
    for i in range(90):
        var x = float((i * 83) % int(screen_size.x))
        var y = float(420 + (i * 137) % int(screen_size.y - 450))

        draw_line(
            Vector2(x, y),
            Vector2(x + 5, y - 9),
            Color("#8cdb69"),
            3
        )

    # Trees
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

        draw_character(Vector2(center, screen_size.y * 0.39), true, 0.9)

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

        draw_character(player_position, is_moving, 1.0)

        # Collection effects
        draw_collection_effects()

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
