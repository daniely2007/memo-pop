extends Node2D

# Level progression
var current_level = 1
var bubbles_count = 4
var time_limit = 10.0
var time_left = 0.0
var timer_running = false

# Reveal phase
var reveal_time = 3.0
var in_reveal_phase = false

# Matching logic
var first_selected = null
var second_selected = null
var checking_match = false

# Game state
var game_active = true

# Preload bubble scene
var bubble_scene = preload("res://bubble.tscn")

# Element textures
var element_textures = []

func _ready():
	# Load all element images
	element_textures = [
		preload("res://elements/cyclone.png"),
		preload("res://elements/lightning.png"),
		preload("res://elements/rain_cloud.png"),
		preload("res://elements/tornado.png"),
		preload("res://elements/umbrella_with_rain_drops.png"),
		preload("res://elements/zap.png")
	]
	
	# Hide restart button initially
	if has_node("CanvasLayer/RestartButton"):
		$CanvasLayer/RestartButton.visible = false
		$CanvasLayer/RestartButton.pressed.connect(_on_restart_button_pressed)
	
	start_level()

func start_level():
	game_active = true
	
	# Calculate bubbles for this level (max 20 = 5x4 grid)
	bubbles_count = min(4 + (current_level - 1) * 2, 20)
	
	# Calculate time for this level
	if bubbles_count < 20:
		# Still increasing bubbles - increase time
		time_limit = 10.0 + (current_level - 1) * 5.0
	else:
		# At max bubbles (level 9+) - decrease time by 2 seconds each level
		var levels_past_max = current_level - 9
		time_limit = max(50.0 - (levels_past_max * 2.0), 10.0)  # Minimum 10 seconds
	
	time_left = time_limit
	timer_running = false
	in_reveal_phase = true
	reveal_time = 3.0
	
	# Reset matching
	first_selected = null
	second_selected = null
	checking_match = false
	
	# Hide restart button
	if has_node("CanvasLayer/RestartButton"):
		$CanvasLayer/RestartButton.visible = false
	
	spawn_bubbles()

func spawn_bubbles():
	# Create pairs
	var elements = []
	var pairs_needed = bubbles_count / 2
	
	for i in range(pairs_needed):
		var element = element_textures[i % element_textures.size()]
		elements.append(element)
		elements.append(element)
	
	elements.shuffle()
	
	# Spawn bubbles
	for i in range(bubbles_count):
		var bubble = bubble_scene.instantiate()
		bubble.position = Vector2(100 + (i % 5) * 100, 100 + int(i / 5) * 100)
		bubble.bubble_clicked.connect(_on_bubble_clicked)
		add_child(bubble)
		bubble.set_element(elements[i])
		bubble.reveal_element()

func _process(delta):
	if not game_active:
		return
	
	# Reveal phase countdown
	if in_reveal_phase:
		reveal_time -= delta
		$Label.text = "Level " + str(current_level) + " - Memorize! " + str(int(reveal_time) + 1)
		
		if reveal_time <= 0:
			in_reveal_phase = false
			timer_running = true
			cover_all_bubbles()
	
	# Game timer
	if timer_running:
		time_left -= delta
		
		if time_left <= 0:
			time_left = 0
			timer_running = false
			$Label.text = "Time's up!"
			game_over()
		else:
			$Label.text = "Level " + str(current_level) + " - Time: " + str(int(time_left))

func cover_all_bubbles():
	for child in get_children():
		if child.has_method("cover_element"):
			child.cover_element()

func _on_bubble_clicked(bubble):
	if checking_match or in_reveal_phase or not game_active:
		return
	
	if first_selected == null:
		first_selected = bubble
	elif second_selected == null and bubble != first_selected:
		second_selected = bubble
		checking_match = true
		check_match()

func check_match():
	await get_tree().create_timer(0.5).timeout
	
	if first_selected.element_texture == second_selected.element_texture:
		# Correct match - remove both bubbles
		first_selected.queue_free()
		second_selected.queue_free()
		print("Match!")
		
		# Wait for bubbles to actually be freed
		await get_tree().create_timer(0.1).timeout
		
		# NOW check if level is complete
		check_level_complete()
	else:
		# Wrong match - cover both again
		first_selected.cover_element()
		second_selected.cover_element()
		print("No match!")
	
	first_selected = null
	second_selected = null
	checking_match = false

func check_level_complete():
	var remaining = 0
	for child in get_children():
		if child.has_method("cover_element"):
			remaining += 1
	
	print("Remaining bubbles: ", remaining)
	
	if remaining == 0:
		level_complete()

func game_over():
	game_active = false
	print("Game Over! Level reached: ", current_level)
	$Label.text = "Game Over! Reached Level " + str(current_level)
	
	# Show restart button
	if has_node("CanvasLayer/RestartButton"):
		$CanvasLayer/RestartButton.visible = true

func level_complete():
	print("Level Complete!")
	timer_running = false
	$Label.text = "Level " + str(current_level) + " Complete!"
	current_level += 1
	
	# Clear old bubbles
	for child in get_children():
		if child.has_method("cover_element"):
			child.queue_free()
	
	# Wait before starting next level
	await get_tree().create_timer(1.5).timeout
	start_level()

func _on_restart_button_pressed():
	# Reset game state
	current_level = 1
	game_active = true
	
	# Clear all bubbles
	for child in get_children():
		if child.has_method("cover_element"):
			child.queue_free()
	
	# Wait a moment then restart
	await get_tree().create_timer(0.2).timeout
	start_level()
