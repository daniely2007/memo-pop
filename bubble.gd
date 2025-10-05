extends Node2D

signal bubble_clicked(bubble)

var element_texture = null
var is_covered = true

func _ready():
	$AnimatedSprite2D.stop()
	$AnimatedSprite2D.frame = 0
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

func set_element(texture):
	element_texture = texture
	if has_node("ElementSprite"):
		$ElementSprite.texture = texture
		$ElementSprite.visible = false

func reveal_element():
	if has_node("ElementSprite"):
		$ElementSprite.visible = true
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.visible = false
	is_covered = false

func cover_element():
	if has_node("ElementSprite"):
		$ElementSprite.visible = false
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.visible = true
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.frame = 0
	is_covered = true

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_covered:
			$AnimatedSprite2D.play("pop")
			if has_node("ElementSprite"):
				$ElementSprite.visible = true
			is_covered = false
			bubble_clicked.emit(self)

func _on_animation_finished():
	$AnimatedSprite2D.visible = false
