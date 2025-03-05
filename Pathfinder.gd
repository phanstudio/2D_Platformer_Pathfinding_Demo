extends Node2D

@export var cell_size: int = 16

@export var jump_height: int = 2
@export var jump_distance: int = 2

var tile_map: TileMapLayer
var graph: AStar2D

@export var show_lines: bool = true

const TEST = preload("res://face.tscn")

func find_path(start: Vector2, end: Vector2) -> Array:
	var first_point = graph.get_closest_point(start)
	var finish = graph.get_closest_point(end)
	var path: PackedInt64Array = graph.get_id_path(first_point, finish, true)
	
	if path.is_empty():
		return []
	
	var actions: Array = []
	var last_pos: Vector2
	for i in range(path.size()):
		var point = path[i]
		var pos: Vector2 = graph.get_point_position(point)
		var stat = cell_type(pos, true, true)
		
		if last_pos and last_pos.y >= pos.y - (cell_size * jump_height) and ((last_pos.x < pos.x and stat[0] < 0) or (last_pos.x > pos.x and stat[1] < 0)):
			actions.append(null)

		last_pos = pos
		
		# Ensure path has at least 2 elements before accessing indices
		if i == 0 and path.size() > 1:
			var next_pos = graph.get_point_position(path[1])
			if start.distance_to(next_pos) > pos.distance_to(next_pos): 
				actions.append(pos)

		elif i == path.size() - 1 and path.size() > 1:
			if graph.get_point_position(path[path.size() - 2]).distance_to(end) < pos.distance_to(end):
				actions.append(pos)
		else:
			actions.append(pos)

	actions.append(end)
	return actions




func _ready():
	graph = AStar2D.new()
	tile_map = get_parent().get_node("Map")  # Updated to get_node()
	create_map()
	create_connections()

func create_connections():
	var points = graph.get_point_ids() # FIXED: get_point_ids() replaces get_points()
	for point_id in points:
		var pos = graph.get_point_position(point_id)	
		var stat = cell_type(pos, true, true)

		var points_to_join: Array = []
		var no_bi_join: Array = []

		for new_point_id in points:
			var new_pos = graph.get_point_position(new_point_id)
			if stat[1] == 0 and new_pos.y == pos.y and new_pos.x > pos.x:
				points_to_join.append(new_point_id)

		# Connect points
		for join_point_id in points_to_join:
			graph.connect_points(point_id, join_point_id)
		for join_point_id in no_bi_join:
			graph.connect_points(point_id, join_point_id, false)


func _draw():
	if not show_lines:
		return
	
	var points = graph.get_point_ids()
	for point in points:
		var pos = graph.get_point_position(point)

		for new_point in points:
			var new_pos = graph.get_point_position(new_point)

			if graph.are_points_connected(point, new_point):
				draw_line(pos, new_pos, Color(1, 0, 0), 1)
			else:
				draw_line(pos, new_pos, Color(0, 1, 0), 1)


func create_map():
	var space_state = get_world_2d().direct_space_state
	var cells = tile_map.get_used_cells()  # TileMap layers now require a layer argument
	
	for cell in cells:
		var stat = cell_type(cell)

		if stat and stat != Vector2i(0, 0):
			create_point(cell)
			
			if stat[1] == -1:
				var pos = tile_map.map_to_local(Vector2i(cell.x + 1, cell.y))
				var pto = Vector2i(pos.x, pos.y + 1000)
				var result = space_state.intersect_ray(PhysicsRayQueryParameters2D.create(pos, pto))
				if result:
					create_point(tile_map.local_to_map(result.position))

			if stat[0] == -1:
				var pos = tile_map.map_to_local(Vector2i(cell.x - 1, cell.y))
				var pto = Vector2i(pos.x, pos.y + 1000)
				var result = space_state.intersect_ray(PhysicsRayQueryParameters2D.create(pos, pto))
				if result:
					create_point(tile_map.local_to_map(result.position))


func cell_type(pos: Vector2i, global: bool = false, is_above: bool = false) -> Vector2i:
	if global:
		pos = tile_map.local_to_map(pos)
	if is_above:
		pos += Vector2i.DOWN
	
	var cells = tile_map.get_used_cells()  # Specify the layer explicitly

	if pos + Vector2i.UP in cells:
		return Vector2i.ZERO
	
	var results = Vector2i.ZERO
	
	if pos + Vector2i.UP + Vector2i.LEFT in cells:
		results.x = 1
	elif not (pos + Vector2i.LEFT in cells):
		results.x = -1
		
	if pos + Vector2i.UP + Vector2i.RIGHT in cells:
		results.y = 1
	elif not (pos + Vector2i.RIGHT in cells):
		results.y = -1
		
	return results

func create_point(cell: Vector2i):
	var above = Vector2i(cell.x, cell.y - 1)
	var pos = tile_map.map_to_local(above) + Vector2(cell_size / 2.0, cell_size / 2.0)
	
	# FIX: Use `get_point_ids()` instead of `get_points()`
	if not graph.get_point_ids().is_empty() and graph.get_point_position(graph.get_closest_point(pos)) == pos:
		return

	if show_lines:
		var test = TEST.instantiate()
		test.position = pos
		call_deferred("add_child", test)
	
	graph.add_point(graph.get_available_point_id(), pos)
