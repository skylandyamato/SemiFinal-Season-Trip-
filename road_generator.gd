extends Node3D
class_name TerrainController

var RoadBlocks = {}
var type = ['road']
var part_instances = []
var part_free_queue = []
var obstacle_scenes = {}
var obstacle_layouts = {}
var left_turn_counter = 0
var right_turn_counter = 0
var intersection_counter = 0
var spawn_part_counter = 0
var part
# Called when the node enters the scene tree for the first time.

var terrain_belt: Array[MeshInstance3D] = []
var terrain_vel = 0
@export var terrain_blocks = randi_range(3, 6)
@export_dir var terrain_blocks_path = "res://road_tiles"
	
func _ready() -> void:
	_load_terrain_scenes(terrain_blocks_path)
	_road_to_right(terrain_blocks)	
		
func _physics_process(delta: float) -> void:
	_progress_terrain(delta, part)
	pass

func spawn_next_part(index):	
	randomize()
	var part = RoadBlocks[type[0]][randi()%RoadBlocks[type[0]].size()]
	match part.type:
		"lturn":
			if left_turn_counter > 0 or index < 4:
				return spawn_next_part(index)
			left_turn_counter +=1
		"rturn":
			if right_turn_counter > 0 or index < 4:
				return spawn_next_part(index)
			right_turn_counter +=1
		"intersectA":
			if intersection_counter > 0 or index < 4:
				return spawn_next_part(index)
			intersection_counter +=1

func _progress_terrain(delta: float, part) -> void:
	for block in terrain_belt:
		block.position.z += terrain_vel * delta

	if terrain_belt[0].position.z >= terrain_belt[0].mesh.size.y/2:
		var last_terrain = terrain_belt[-1]
		var first_terrain = terrain_belt.pop_front()
		var block = load(part.file).instantiate()
		_append_to_far_edge(last_terrain, block)
		add_child(block)
		terrain_belt.append(block)
		first_terrain.queue_free()


func _append_to_far_edge(target_block: MeshInstance3D, appending_block: MeshInstance3D) -> void:
	appending_block.position.z = target_block.position.z - target_block.mesh.size.y/2 - appending_block.mesh.size.y/2
	#appending_block.rotate_z(randi())
	#Reminder: pos x & 2 + = right; pos x & 2 - = left
	#Reminder: build chunks from the mesh or smth then rotate it when needed
	#search how to turn multiple meshes into one whole
	
func _load_terrain_scenes(target_path: String) -> void:
	var dir = DirAccess.open(target_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				var road= {
						file = target_path + "/" + file_name,
						stuff = file_name.split('_')[0],
						type = file_name.split('_')[1]
					}
				print("Found Directory: " + file_name)
				if !RoadBlocks.has(road.stuff):
					RoadBlocks[road.stuff] = []
				RoadBlocks[road.stuff].push_back(road)
			else:
				print("Found file: "+ file_name)
			file_name = dir.get_next()
	else:
		print("Error while accessing path")

func _initial_road(blocks):
	part = RoadBlocks[type[0]][RoadBlocks[type[0]].size()-1]
	for block_index in blocks:
		var block = load(part.file).instantiate()
		print(block)
		if block_index == 0:
			block.position.z = block.mesh.size.y/2
		else:
			_append_to_far_edge(terrain_belt[block_index-1], block)
		add_child(block)
		terrain_belt.append(block)
	return part

func _road_to_right(blocks):

	#terrain_belt = []
	part = RoadBlocks[type[0]][RoadBlocks[type[0]].size()-1]
	for i in blocks:
		terrain_belt.append("")
	terrain_belt.append(load( RoadBlocks[type[0]][RoadBlocks[type[0]].size()-2].file).instantiate())
	for block_index in blocks:
		var block = load(part.file).instantiate()
		if block_index == 0:
			block.position.z = block.mesh.size.y/2
		else:
			_append_to_far_edge(terrain_belt[block_index-1], block)
			print(terrain_belt)
		add_child(block)
		terrain_belt.push_front(block)
	return part

func _on_v_box_container_speed_changed(speed):
	terrain_vel = speed
