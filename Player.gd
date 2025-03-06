#extends CharacterBody2D
#
#@export var speed: float = 100.0
#@export var jump_force: float = 200.0
#@export var gravity: float = 550.0
#@export var padding: float = 1.0
#@export var finish_padding: float = 5.0
#
#var current_path: Array
#var current_target: Vector2
#var path_finder: Node
#
#var movement: Vector2 = Vector2.ZERO
#
## Called when the node enters the scene tree for the first time.
#func _ready():
	#path_finder = get_parent().get_node("Pathfinder") # Updated to get_node()
	#movement = Vector2.ZERO
#
#
#func next_point():
	#if current_path.is_empty():
		#current_target = Vector2.ZERO
		#return
	#
	#current_target = current_path.pop_front()
	#
	#if current_target == Vector2.ZERO:
		#jump()
		#next_point()
#
#
#func jump():
	#if is_on_floor():
		#movement.y = -jump_force
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#var space_state = get_world_2d().direct_space_state
#
	#if Input.is_action_just_pressed("left_click"):
		#var mouse_pos = get_global_mouse_position()
		#var query = PhysicsRayQueryParameters2D.create(mouse_pos, mouse_pos + Vector2(0, 1000))
		#var result = space_state.intersect_ray(query)
		#if result:
			#var go_to = result.position
			#current_path = path_finder.find_path(global_position, go_to) # Updated function call
			#next_point()
			#print(current_path)
	#
	#if current_target != Vector2.ZERO:
		#if current_target.x - padding > position.x:
			#movement.x = speed
		#elif current_target.x + padding < position.x:
			#movement.x = -speed
		#else:
			#movement.x = 0
			#
		#if position.distance_to(current_target) < finish_padding and is_on_floor():
			#next_point()
	#else:
		#movement.x = 0
	#
	#if not is_on_floor():
		#movement.y += gravity * delta
	#
	#velocity = movement  # Updated to use `velocity` directly
	#move_and_slide()
extends CharacterBody2D

@export var speed: float = 100.0
@export var jump_force: float = 200.0
@export var gravity: float = 550.0
@export var horizontal_padding: float = 1.0
@export var arrival_threshold: float = 5.0
@export var jump_height_threshold: float = 10.0  # Minimum height difference to trigger jump
@export var path_finder: Node  # Assign in editor

var current_path: Array = []
var current_target: Vector2 = Vector2.ZERO

func _ready():
	pass

func update_path_target():
	if current_path.is_empty():
		current_target = Vector2.ZERO
		return
	
	current_target = current_path.pop_front()
	
	# Check if next point requires jumping
	if not current_path.is_empty():
		var next_target = current_path[0]
		if global_position.y - next_target.y > jump_height_threshold:
			jump()

func jump():
	if is_on_floor():
		velocity.y = -jump_force

func _physics_process(delta):
	handle_input()
	move_character(delta)
	apply_gravity(delta)
	move_and_slide()

func handle_input():
	if Input.is_action_just_pressed("left_click"):
		var mouse_pos = get_global_mouse_position()
		var query = PhysicsRayQueryParameters2D.create(mouse_pos, mouse_pos + Vector2.DOWN * 1000)
		var result = get_world_2d().direct_space_state.intersect_ray(query)
		
		if result:
			current_path = path_finder.find_path(global_position, result.position)
			if not current_path.is_empty():
				update_path_target()

func move_character(_delta):
	if current_target == Vector2.ZERO:
		velocity.x = 0
		return

	# Horizontal movement
	if global_position.x < current_target.x - horizontal_padding:
		velocity.x = speed
	elif global_position.x > current_target.x + horizontal_padding:
		velocity.x = -speed
	else:
		velocity.x = 0

	# Check if reached current target
	if global_position.distance_to(current_target) < arrival_threshold:
		update_path_target()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = max(velocity.y, 0)
