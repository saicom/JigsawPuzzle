extends Node2D

@export var grid_size = Vector2i(3, 3)	#网格大小

const P_1 = preload("res://assets/p1.png")
const P_2 = preload("res://assets/p2.png")
const PUZZLE_PIECE = preload("res://puzzle_piece.tscn")
const DISPLAY_HEIGHT = 800	#原图在游戏中期望的显示高度，用来等比例缩放原图使用

var mask_dict = {}	#碎片蒙版字典  类型->图片
var shadow_dict = {}	#碎片阴影字典  类型->图片
var puzzle_pieces: Array[PuzzlePiece] = []	#生成的所有碎片
var cur_piece: PuzzlePiece = null	#当前操作的碎片
var mouse_offset: Vector2	#鼠标点击碎片的时候和碎片位置偏移
var groups = {}	#所有匹配的碎片集合
var next_group_index = 0	#碎片集合的组id
var next_z_index = 0	#全局的z_index索引，一直递增，保证被移动的碎片在最上层

func _ready() -> void:
	var pic = P_2
	var img = pic.get_image()
	#将原图等比例缩放到指定的大小
	img.resize(DISPLAY_HEIGHT * pic.get_width()/pic.get_height(), DISPLAY_HEIGHT)
	#初始化碎片的图片字典
	for i in range(9):
		var index = i + 1
		mask_dict[index] = load("res://assets/Piece_%d.png"%[index]) 
		shadow_dict[index] = load("res://assets/Shadow_%d.png"%[index])
	#从左到右从上到下按网格生成碎片
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var piece = PUZZLE_PIECE.instantiate() as PuzzlePiece
			add_child(piece)
			piece.init_piece(img, x, y, grid_size, mask_dict, shadow_dict)
			puzzle_pieces.append(piece)
			#随机碎片位置
			piece.position = Vector2(randf_range(0, 800), randf_range(0, 800))
			piece.gui_input.connect(_on_piece_input_event.bind(piece))

func _on_piece_input_event(event: InputEvent, piece: PuzzlePiece):
	if event is InputEventMouseButton and event.is_pressed():
		cur_piece = piece
		mouse_offset = cur_piece.global_position - event.global_position
		if cur_piece.group == -1:
			next_z_index += 1
			cur_piece.z_index = next_z_index
		else:
			update_group_z_index(cur_piece.group)
	elif event is InputEventMouseMotion:
		if cur_piece:
			move_group(cur_piece, event.global_position + mouse_offset)
	elif event is InputEventMouseButton and not event.is_pressed():
		check_snap(cur_piece)
		cur_piece = null
		
func check_snap(piece: PuzzlePiece):
	for other in puzzle_pieces:
		if other.group != -1 and piece.group != -1 and other.group == piece.group:
			continue
		if other != piece and piece.is_adjacent(other):
			var new_pos = piece.snap_to(other)
			move_group(piece, new_pos)
			handle_group(piece, other)
			check_finish()

func move_group(piece: PuzzlePiece, new_pos: Vector2):
	if piece.group == -1:
		piece.global_position = new_pos
		return
		
	var offset = new_pos - piece.global_position
	for p in groups[piece.group]:
		p.global_position += offset	
	
func handle_group(piece1: PuzzlePiece, piece2: PuzzlePiece):
	var target_group = max(piece1.group, piece2.group)
	var source_group = min(piece1.group, piece2.group)
	#有一个未分组的
	if source_group == -1:
		#两个都未分组的创建新组
		if target_group == -1:
			next_group_index += 1			
			target_group = next_group_index
			groups[target_group] = [piece1, piece2]
		#未分组的加入已存在的组中
		else:
			var p = piece1 if piece1.group == -1 else piece2
			groups[target_group].append(p)
	else:
		#两个在同一个组返回
		if source_group == target_group:
			return
		#合并两个组
		for p in groups[source_group]:
			p.group = target_group
		groups[target_group] += groups[source_group]
		groups.erase(source_group)
	piece1.group = target_group
	piece2.group = target_group
	update_group_z_index(target_group)

func update_group_z_index(group_id):
	if group_id == -1:
		return
		
	next_group_index += 1
	for piece in groups[group_id]:
		piece.z_index = next_z_index

func check_finish():
	for group_id in groups:
		if groups[group_id].size() == grid_size.x * grid_size.y:
			print("finish!!!!")
