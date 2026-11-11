extends Control

const GOLD := Color(0.82, 0.57, 0.24)
const GOLD_LIGHT := Color(0.98, 0.78, 0.43)
const DARK := Color(0.08, 0.075, 0.07)

func _ready() -> void:
    custom_minimum_size = Vector2(104, 92)
    size_flags_horizontal = Control.SIZE_SHRINK_CENTER

func _draw() -> void:
    var w := size.x
    var scale_factor := minf(w / 104.0, size.y / 92.0)
    var origin := Vector2((w - 104.0 * scale_factor) * 0.5, (size.y - 92.0 * scale_factor) * 0.5)
    draw_set_transform(origin, 0.0, Vector2.ONE * scale_factor)

    # M massif, ouvert et lisible en petite taille.
    var m := PackedVector2Array([
        Vector2(13, 83), Vector2(24, 26), Vector2(48, 55),
        Vector2(73, 26), Vector2(91, 83), Vector2(73, 83),
        Vector2(65, 53), Vector2(48, 72), Vector2(32, 53),
        Vector2(25, 83)
    ])
    draw_colored_polygon(m, DARK)
    draw_polyline(m, GOLD_LIGHT, 3.0, true)

    # Empreinte de patte stylisée intégrée au sommet du M.
    draw_circle(Vector2(31, 15), 7.0, GOLD)
    draw_circle(Vector2(45, 9), 7.0, GOLD_LIGHT)
    draw_circle(Vector2(60, 9), 7.0, GOLD_LIGHT)
    draw_circle(Vector2(74, 15), 7.0, GOLD)
    draw_colored_polygon(PackedVector2Array([
        Vector2(34, 25), Vector2(42, 18), Vector2(54, 18),
        Vector2(67, 25), Vector2(64, 37), Vector2(52, 42),
        Vector2(39, 37)
    ]), GOLD)
    draw_line(Vector2(48, 29), Vector2(53, 36), Color(0.24, 0.15, 0.08), 2.0)
