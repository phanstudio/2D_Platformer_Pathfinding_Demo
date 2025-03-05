#extends CharacterBody2D
#
#
## Declare member variables here. Examples:
## var a = 2
## var b = "text"
#var currentPath
#var currentTarget
#var pathFinder
#
#var speed = 100
#var jumpForce = 200
#var gravity = 550
#var padding = 1
#var finishPadding = 5
#
#var movement
#
## Called when the node enters the scene tree for the first time.
#func _ready():
	#pathFinder = find_parent("Master").find_child("Pathfinder")
	#movement = Vector2(0, 0)
	#pass # Replace with function body.
#
#
#func nextPoint():
	#if len(currentPath) == 0:
		#currentTarget = null
		#return
	#
	#currentTarget = currentPath.pop_front()
##	print(currentTarget)
	#
	#if !currentTarget:
		#jump()
		#nextPoint()
#
#func jump():
	#if (self.is_on_floor()):
		#movement[1] = -jumpForce
	#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#var space_state = get_world_2d().direct_space_state
	#if Input.is_action_just_pressed("left_click"):
		#var mousePos = get_global_mouse_position()
		#var result = space_state.intersect_ray(mousePos, Vector2(mousePos[0], mousePos[1] + 1000))
		#if (result):
			#var goTo = result["position"]
			#currentPath = pathFinder.findPath(self.position, goTo)
			#nextPoint()
	#
	#if currentTarget:
		#if (currentTarget[0] - padding > position[0]): # and position.distance_to(currentTarget) > padding:
			#movement[0] = speed
		#elif (currentTarget[0] + padding < position[0]): # and position.distance_to(currentTarget) > padding:
			#movement[0] = -speed
		#else:
			#movement[0] = 0
			#
		#if position.distance_to(currentTarget) < finishPadding and is_on_floor():
				#nextPoint()
	#else:
		#movement[0] = 0
	#
	#if !is_on_floor():
		#movement[1] += gravity * delta
##	elif movement[1] > 0:
##		movement[1] = 0
	#
	#self.set_velocity(movement)
	#self.set_up_direction(Vector2(0, -1))
	#self.move_and_slide()
	#self.velocity



extends CharacterBody2D

@export var speed: float = 100.0
@export var jump_force: float = 200.0
@export var gravity: float = 550.0
@export var padding: float = 1.0
@export var finish_padding: float = 5.0

var current_path: Array
var current_target: Vector2
var path_finder: Node

var movement: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	path_finder = get_parent().get_node("Pathfinder") # Updated to get_node()
	movement = Vector2.ZERO


func next_point():
	if current_path.is_empty():
		current_target = Vector2.ZERO
		return
	
	current_target = current_path.pop_front()
	
	if current_target == Vector2.ZERO:
		jump()
		next_point()


func jump():
	if is_on_floor():
		movement.y = -jump_force


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var space_state = get_world_2d().direct_space_state

	if Input.is_action_just_pressed("left_click"):
		var mouse_pos = get_global_mouse_position()
		var query = PhysicsRayQueryParameters2D.create(mouse_pos, mouse_pos + Vector2(0, 1000))
		var result = space_state.intersect_ray(query)
		if result:
			var go_to = result.position
			current_path = path_finder.find_path(global_position, go_to) # Updated function call
			next_point()
			print(current_path)
	
	if current_target != Vector2.ZERO:
		if current_target.x - padding > position.x:
			movement.x = speed
		elif current_target.x + padding < position.x:
			movement.x = -speed
		else:
			movement.x = 0
			
		if position.distance_to(current_target) < finish_padding and is_on_floor():
			next_point()
	else:
		movement.x = 0
	
	if not is_on_floor():
		movement.y += gravity * delta
	
	velocity = movement  # Updated to use `velocity` directly
	move_and_slide()
