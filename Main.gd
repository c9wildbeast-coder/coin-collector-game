
extends Node2D

var player_position = Vector2(360, 640)
var player_speed = 350.0
var player_radius = 25.0

var coins = []
var score = 0

var touch_target = null

var screen_size = Vector2(720, 1280)

func _ready():
    randomize()
    screen_size = get_viewport_rect().size
    player_position = screen_size / 2

    for i in range(10):
        spawn_coin()

    queue_redraw()

func _process(delta):
    var direction = Vector2.ZERO

    direction = Input.get_vector(
        "ui_left",
        "ui_right",
        "ui_up",
        "ui_down"
    )

    if touch_target != null:
        var distance = player_position.distance_to(touch_target)

        if distance > 10:
            direction = player_position.direction_to(touch_target)

    player_position += direction * player_speed * delta

    player_position.x = clampf(player_position.x, 30, screen_size.x - 30)
    player_position.y = clampf(player_position.y, 100, screen_size.y - 30)

    for i in range(coins.size() - 1, -1, -1):
        if player_position.distance_to(coins[i]) < 45:
            coins.remove_at(i)
            score += 1
            spawn_coin()

    queue_redraw()

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_target = event.position
        else:
            touch_target = null

    elif event is InputEventScreenDrag:
        touch_target = event.position

    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                touch_target = event.position
            else:
                touch_target = null

    elif event is InputEventMouseMotion:
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            touch_target = event.position

func spawn_coin():
    var margin = 60.0

    var coin = Vector2(
        randf_range(margin, screen_size.x - margin),
        randf_range(130, screen_size.y - margin)
    )

    coins.append(coin)

func _draw():
    draw_rect(
        Rect2(Vector2.ZERO, screen_size),
        Color("#17252b")
    )

    # Draw background grid
    for x in range(0, int(screen_size.x), 60):
        draw_line(
            Vector2(x, 0),
            Vector2(x, screen_size.y),
            Color("#24363c"),
            1
        )

    for y in range(0, int(screen_size.y), 60):
        draw_line(
            Vector2(0, y),
            Vector2(screen_size.x, y),
            Color("#24363c"),
            1
        )

    # Draw coins
    for coin in coins:
        draw_circle(coin, 17, Color("#f1c40f"))
        draw_circle(coin, 11, Color("#ffe680"))

    # Draw player
    draw_circle(player_position, player_radius, Color("#3498db"))
    draw_circle(player_position, 13, Color("#85d6ff"))

    # Draw score
    draw_string(
        ThemeDB.fallback_font,
        Vector2(25, 65),
        "COINS: " + str(score),
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        36,
        Color.WHITE
    )

    draw_string(
        ThemeDB.fallback_font,
        Vector2(25, 100),
        "Touch to move",
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        22,
        Color("#bdc3c7")
    )
