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

    draw_button(
        classic_mode_button,
        "CLASSIC MODE",
        Color("#27ae60")
    )

    draw_button(
        maze_mode_button,
        "MAZE MODE",
        Color("#8e44ad")
    )

    draw_button(
        mode_back_button,
        "BACK",
        Color("#c0392b")
    )

elif state == "maze_coming_soon":
    draw_string(
        ThemeDB.fallback_font,
        Vector2(0, screen_size.y * 0.30),
        "MAZE MODE",
        HORIZONTAL_ALIGNMENT_CENTER,
        screen_size.x,
        50,
        Color("#ffe66d")
    )

    draw_string(
        ThemeDB.fallback_font,
        Vector2(0, screen_size.y * 0.42),
        "99 LEVELS AWAIT!",
        HORIZONTAL_ALIGNMENT_CENTER,
        screen_size.x,
        32,
        Color.WHITE
    )

    draw_string(
        ThemeDB.fallback_font,
        Vector2(0, screen_size.y * 0.49),
        "COMING SOON",
        HORIZONTAL_ALIGNMENT_CENTER,
        screen_size.x,
        28,
        Color("#aaffc3")
    )

    draw_button(
        mode_back_button,
        "BACK",
        Color("#c0392b")
    )
