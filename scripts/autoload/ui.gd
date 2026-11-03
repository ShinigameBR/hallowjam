extends Node
## Central visual language for the whole game.
## Builds one Theme at startup and exposes a few helpers so every
## screen shares the same spacing, colours and typography.

var BG := Color("#080b12")
var BG_SOFT := Color("#0d121c")
var SURFACE := Color("#121926")
var SURFACE_2 := Color("#182132")
var SURFACE_3 := Color("#202b3d")
var TEXT := Color("#e9e4d8")
var MUTED := Color("#98a2b3")
var MUTED_DIM := Color("#5d6879")
var ACCENT := Color("#d6b36a")
var ACCENT_SOFT := Color("#8f7743")
var TEAL := Color("#69c6b1")
var DANGER := Color("#cf5d70")
var PURPLE := Color("#a488d6")
var GREEN := Color("#6fbf8a")
var BLUE := Color("#6d9fd1")
var RED := Color("#cf5d63")
var CRIMSON := Color("#c2445f")
var WHITE := Color("#e8e3d4")
var BLACK := Color("#05070b")

var theme: Theme
var font_body: Font
var font_title: Font
var font_medium: Font
var font_bold: Font
var font_spaced: Font


func _ready() -> void:
	var cinzel := _load_font("res://assets/fonts/Cinzel.ttf")
	var inter := _load_font("res://assets/fonts/Inter.ttf")

	font_body = _vary(inter, 0, 400)
	font_medium = _vary(inter, 0, 500)
	font_bold = _vary(inter, 0, 650)
	font_spaced = _vary(inter, 2, 500)
	font_title = _vary(cinzel, 5, 600)

	theme = _build_theme()


func _load_font(path: String) -> Font:
	var res := load(path)
	if res is Font:
		return res
	return ThemeDB.fallback_font


func _vary(base: Font, spacing: int, weight: int) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = base
	f.spacing_glyph = spacing
	f.variation_opentype = { "wght": weight }
	return f


func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = 16

	# ---------------------------------------------------------------- labels
	t.set_color("font_color", "Label", TEXT)
	t.set_font("font", "Label", font_body)
	t.set_font_size("font_size", "Label", 16)

	_variation(t, "Title", "Label", font_title, 86, ACCENT)
	_variation(t, "TitleSmall", "Label", font_title, 42, TEXT)
	_variation(t, "HudTitle", "Label", font_title, 24, ACCENT)
	_variation(t, "H1", "Label", font_title, 30, TEXT)
	_variation(t, "H2", "Label", font_bold, 20, TEXT)
	_variation(t, "H3", "Label", font_bold, 16, TEXT)
	_variation(t, "BodyLarge", "Label", font_body, 18, TEXT)
	_variation(t, "Objective", "Label", font_body, 15, Color(TEXT, 0.94))
	_variation(t, "Muted", "Label", font_body, 14, MUTED)
	_variation(t, "Small", "Label", font_body, 12, MUTED)
	_variation(t, "Tiny", "Label", font_medium, 10, MUTED_DIM)
	_variation(t, "Eyebrow", "Label", font_spaced, 11, ACCENT)
	_variation(t, "EyebrowMuted", "Label", font_spaced, 10, MUTED)
	_variation(t, "ItemName", "Label", font_medium, 13, TEXT)
	_variation(t, "Tag", "Label", font_medium, 10, MUTED)
	_variation(t, "DialogSpeaker", "Label", font_spaced, 11, ACCENT)
	_variation(t, "DialogText", "Label", font_body, 18, TEXT)
	_variation(t, "Danger", "Label", font_medium, 14, DANGER)

	# ---------------------------------------------------------------- buttons
	t.set_font("font", "Button", font_medium)
	t.set_font_size("font_size", "Button", 15)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", ACCENT)
	t.set_color("font_focus_color", "Button", ACCENT)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", MUTED_DIM)

	var button_normal := _style(Color(1, 1, 1, 0.02), 8, Color(1, 1, 1, 0.06), 1, 14)
	var button_hover := _style(Color(1, 1, 1, 0.06), 8, Color(ACCENT, 0.5), 1, 14)
	var button_pressed := _style(Color(1, 1, 1, 0.09), 8, Color(ACCENT, 0.8), 1, 14)
	var button_disabled := _style(Color(1, 1, 1, 0.015), 8, Color(1, 1, 1, 0.03), 1, 14)
	var button_focus := _style(Color(1, 1, 1, 0.0), 8, Color(ACCENT, 0.9), 1, 14)
	t.set_stylebox("normal", "Button", button_normal)
	t.set_stylebox("hover", "Button", button_hover)
	t.set_stylebox("pressed", "Button", button_pressed)
	t.set_stylebox("disabled", "Button", button_disabled)
	t.set_stylebox("focus", "Button", button_focus)

	# Menu buttons: almost invisible until hovered, editorial and quiet.
	t.set_type_variation("NavButton", "Button")
	t.set_font("font", "NavButton", _vary(font_body, 2, 500))
	t.set_font_size("font_size", "NavButton", 17)
	t.set_color("font_color", "NavButton", TEXT)
	t.set_color("font_hover_color", "NavButton", ACCENT)
	t.set_color("font_focus_color", "NavButton", ACCENT)
	t.set_color("font_pressed_color", "NavButton", ACCENT)
	t.set_color("font_disabled_color", "NavButton", MUTED_DIM)
	t.set_stylebox("normal", "NavButton", _nav_style(Color(1, 1, 1, 0.0)))
	t.set_stylebox("hover", "NavButton", _nav_style(Color(1, 1, 1, 0.045)))
	t.set_stylebox("pressed", "NavButton", _nav_style(Color(1, 1, 1, 0.075)))
	t.set_stylebox("disabled", "NavButton", _nav_style(Color(1, 1, 1, 0.0)))
	t.set_stylebox("focus", "NavButton", _nav_style(Color(1, 1, 1, 0.0)))

	# Gold primary action.
	t.set_type_variation("PrimaryButton", "Button")
	t.set_font("font", "PrimaryButton", font_bold)
	t.set_font_size("font_size", "PrimaryButton", 14)
	t.set_color("font_color", "PrimaryButton", BG)
	t.set_color("font_hover_color", "PrimaryButton", BG)
	t.set_color("font_focus_color", "PrimaryButton", BG)
	t.set_color("font_pressed_color", "PrimaryButton", BG)
	t.set_color("font_disabled_color", "PrimaryButton", Color(BG, 0.45))
	t.set_stylebox("normal", "PrimaryButton", _style(ACCENT, 7, ACCENT, 0, 16))
	t.set_stylebox("hover", "PrimaryButton", _style(ACCENT.lightened(0.12), 7, ACCENT.lightened(0.2), 0, 16))
	t.set_stylebox("pressed", "PrimaryButton", _style(ACCENT.darkened(0.12), 7, ACCENT, 0, 16))
	t.set_stylebox("disabled", "PrimaryButton", _style(Color(ACCENT, 0.22), 7, Color.TRANSPARENT, 0, 16))
	t.set_stylebox("focus", "PrimaryButton", _style(Color.TRANSPARENT, 7, Color(TEXT, 0.65), 1, 16))

	# Quiet bordered action.
	t.set_type_variation("GhostButton", "Button")
	t.set_font("font", "GhostButton", font_medium)
	t.set_font_size("font_size", "GhostButton", 14)
	t.set_color("font_color", "GhostButton", TEXT)
	t.set_color("font_hover_color", "GhostButton", ACCENT)
	t.set_color("font_focus_color", "GhostButton", ACCENT)
	t.set_color("font_pressed_color", "GhostButton", ACCENT)
	t.set_color("font_disabled_color", "GhostButton", MUTED_DIM)
	t.set_stylebox("normal", "GhostButton", _style(Color.TRANSPARENT, 7, Color(1, 1, 1, 0.14), 1, 14))
	t.set_stylebox("hover", "GhostButton", _style(Color(ACCENT, 0.07), 7, Color(ACCENT, 0.55), 1, 14))
	t.set_stylebox("pressed", "GhostButton", _style(Color(ACCENT, 0.12), 7, ACCENT, 1, 14))
	t.set_stylebox("disabled", "GhostButton", _style(Color.TRANSPARENT, 7, Color(1, 1, 1, 0.05), 1, 14))
	t.set_stylebox("focus", "GhostButton", _style(Color.TRANSPARENT, 7, Color(ACCENT, 0.9), 1, 14))

	# Small square icon-ish button used in the HUD.
	t.set_type_variation("IconButton", "Button")
	t.set_font("font", "IconButton", font_medium)
	t.set_font_size("font_size", "IconButton", 13)
	t.set_color("font_color", "IconButton", MUTED)
	t.set_color("font_hover_color", "IconButton", ACCENT)
	t.set_color("font_focus_color", "IconButton", ACCENT)
	t.set_color("font_pressed_color", "IconButton", ACCENT)
	t.set_stylebox("normal", "IconButton", _style(Color(1, 1, 1, 0.025), 6, Color(1, 1, 1, 0.07), 1, 10))
	t.set_stylebox("hover", "IconButton", _style(Color(ACCENT, 0.08), 6, Color(ACCENT, 0.5), 1, 10))
	t.set_stylebox("pressed", "IconButton", _style(Color(ACCENT, 0.12), 6, ACCENT, 1, 10))
	t.set_stylebox("focus", "IconButton", _style(Color.TRANSPARENT, 6, Color(ACCENT, 0.9), 1, 10))

	# Inventory slot.
	t.set_type_variation("SlotButton", "Button")
	t.set_stylebox("normal", "SlotButton", _style(Color(1, 1, 1, 0.035), 9, Color(1, 1, 1, 0.09), 1, 4))
	t.set_stylebox("hover", "SlotButton", _style(Color(1, 1, 1, 0.07), 9, Color(ACCENT, 0.6), 1, 4))
	t.set_stylebox("pressed", "SlotButton", _style(Color(ACCENT, 0.13), 9, ACCENT, 1, 4))
	t.set_stylebox("focus", "SlotButton", _style(Color.TRANSPARENT, 9, Color(ACCENT, 0.9), 1, 4))

	# ---------------------------------------------------------------- panels
	var panel := _style(Color(SURFACE, 0.97), 14, Color(1, 1, 1, 0.08), 1, 24)
	panel.shadow_color = Color(0, 0, 0, 0.45)
	panel.shadow_size = 24
	panel.shadow_offset = Vector2(0, 10)
	t.set_stylebox("panel", "PanelContainer", panel)

	t.set_type_variation("HudPanel", "PanelContainer")
	t.set_stylebox("panel", "HudPanel", _style(Color(BG_SOFT, 0.82), 10, Color(1, 1, 1, 0.06), 1, 12))

	# Floating HUD cards: dark glass, a thin gold edge and a soft drop shadow.
	t.set_type_variation("HudCard", "PanelContainer")
	var hud_card := _style(Color(BG_SOFT, 0.80), 12, Color(ACCENT, 0.18), 1, 0)
	hud_card.border_width_left = 2
	hud_card.shadow_color = Color(0, 0, 0, 0.35)
	hud_card.shadow_size = 12
	hud_card.shadow_offset = Vector2(0, 5)
	t.set_stylebox("panel", "HudCard", hud_card)

	t.set_type_variation("HudTray", "PanelContainer")
	var hud_tray := _style(Color("#0a0f18"), 16, Color(ACCENT, 0.16), 1, 0)
	hud_tray.shadow_color = Color(0, 0, 0, 0.45)
	hud_tray.shadow_size = 18
	hud_tray.shadow_offset = Vector2(0, 7)
	t.set_stylebox("panel", "HudTray", hud_tray)

	t.set_type_variation("HudSlot", "PanelContainer")
	t.set_stylebox("panel", "HudSlot", _style(Color(BG_SOFT, 0.62), 9, Color(ACCENT, 0.20), 1, 4))

	t.set_type_variation("DialogPanel", "PanelContainer")
	var dialog_style := _style(Color("#0d131e"), 10, Color(ACCENT, 0.22), 1, 20)
	dialog_style.border_width_left = 3
	dialog_style.shadow_color = Color(0, 0, 0, 0.5)
	dialog_style.shadow_size = 18
	t.set_stylebox("panel", "DialogPanel", dialog_style)

	t.set_type_variation("PagePanel", "PanelContainer")
	t.set_stylebox("panel", "PagePanel", _style(Color("#101722"), 10, Color(ACCENT, 0.16), 1, 20))

	# ---------------------------------------------------------------- sliders
	var slider_track := _style(Color(1, 1, 1, 0.16), 4, Color(1, 1, 1, 0.08), 1, 0)
	slider_track.content_margin_top = 4
	slider_track.content_margin_bottom = 4
	var slider_fill := _style(Color(ACCENT, 0.75), 4, Color(ACCENT, 0.9), 1, 0)
	slider_fill.content_margin_top = 4
	slider_fill.content_margin_bottom = 4
	var slider_fill_hi := _style(ACCENT, 4, ACCENT.lightened(0.2), 1, 0)
	slider_fill_hi.content_margin_top = 4
	slider_fill_hi.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", slider_track)
	t.set_stylebox("grabber_area", "HSlider", slider_fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", slider_fill_hi)
	t.set_icon("grabber", "HSlider", _grabber_texture(18, ACCENT))
	t.set_icon("grabber_highlight", "HSlider", _grabber_texture(18, ACCENT.lightened(0.25)))
	t.set_icon("grabber_disabled", "HSlider", _grabber_texture(18, MUTED_DIM))

	# ---------------------------------------------------------------- tooltips
	t.set_stylebox("panel", "TooltipPanel", _style(Color("#0b1019"), 7, Color(1, 1, 1, 0.12), 1, 10))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_font("font", "TooltipLabel", font_body)
	t.set_font_size("font_size", "TooltipLabel", 13)

	# ---------------------------------------------------------------- misc
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_color("font_hover_color", "CheckButton", ACCENT)
	t.set_font("font", "CheckButton", font_body)
	t.set_font_size("font_size", "CheckButton", 15)

	return t


func _variation(t: Theme, name: StringName, base: StringName, font: Font, size: int, color: Color) -> void:
	t.set_type_variation(name, base)
	t.set_font("font", name, font)
	t.set_font_size("font_size", name, size)
	t.set_color("font_color", name, color)


func _nav_style(bg: Color) -> StyleBoxFlat:
	var s := _style(bg, 4, Color.TRANSPARENT, 0, 6)
	s.content_margin_left = 18
	s.content_margin_right = 18
	return s


func _grabber_texture(diameter: int, color: Color) -> ImageTexture:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var radius := diameter * 0.5
	for y in range(diameter):
		for x in range(diameter):
			var dist := Vector2(x + 0.5 - radius, y + 0.5 - radius).length()
			var alpha := clampf(radius - dist, 0.0, 1.0)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * alpha))
	return ImageTexture.create_from_image(img)


func _style(bg: Color, radius: int, border: Color, border_width: int, margin: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border_width)
	s.border_color = border
	s.set_content_margin_all(margin)
	s.anti_aliasing = true
	return s


# ------------------------------------------------------------------ helpers
func label(text_value: String, variation: String = "Label") -> Label:
	var l := Label.new()
	l.text = text_value
	l.theme_type_variation = variation
	return l


func button(text_value: String, variation: String = "Button") -> Button:
	var b := Button.new()
	b.text = text_value
	b.theme_type_variation = variation
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


func panel(variation: String = "") -> PanelContainer:
	var p := PanelContainer.new()
	if variation != "":
		p.theme_type_variation = variation
	return p


func spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func hline(color: Color = Color(1, 1, 1, 0.1), height: float = 1.0) -> ColorRect:
	var c := ColorRect.new()
	c.color = color
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func full_rect(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]
