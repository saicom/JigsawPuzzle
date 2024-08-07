extends TextureRect
class_name PuzzlePiece

enum {
	L_U = 1,	#左上角图块
	L = 2 ,		#左边图块
	L_B = 3,	#左下角图块
	U = 4,		#上边图块
	R_U = 5,	#右上角图块
	INNER = 6,	#中间图块
	R = 7,		#右边图块
	B = 8,		#底边图块
	R_B = 9		#右下角图块
}

var x_index: int	#在拼图网格中的x轴索引
var y_index: int	#在拼图网格中的y轴索引
var grid_width: float	#拼图中网格宽度
var grid_height: float 	#拼图中网格高度
var group: int = -1		#已匹配成功的碎片组id

const TOLERANCE: float = 30	#满足吸附的误差值
const MASK_SIZE_LENGTH: float = 512	#碎片蒙版图形的基础边长(剔除凸出部分)

@onready var content: TextureRect = $Content
@onready var shadow: TextureRect = $Shadow

#根据网格坐标获取碎片的类型
func get_piece_type(x: int, y: int, grid_size: Vector2i):
	if x  == 0 and y == 0:
		return L_U
	elif x == grid_size.x - 1 and y == 0:
		return R_U
	elif x == 0 and y == grid_size.y - 1:
		return L_B
	elif x == grid_size.x - 1 and y == grid_size.y - 1:
		return R_B
	elif x == 0:
		return L
	elif x == grid_size.x - 1:
		return R
	elif y == 0:
		return U
	elif y == grid_size.y - 1:
		return B
	else:
		return INNER

#初始化碎片
func init_piece(image: Image, x: int, y: int, grid_size: Vector2, 
				mask_dict: Dictionary, shadow_dict: Dictionary):
	x_index = x
	y_index = y
	var piece_type = get_piece_type(x, y, grid_size)
	#切分后单元格的宽高
	grid_width = image.get_width() / grid_size.x
	grid_height = image.get_height() / grid_size.y
	#因为拼图存在凸出部分，所以需要根据单元格的尺寸和蒙版原始尺寸来计算出每一个碎片的尺寸
	var target_size = get_target_size(grid_width, grid_height, mask_dict[piece_type].get_size())
	size = target_size
	texture = mask_dict[piece_type]
	#阴影图片的纹理
	shadow.texture = shadow_dict[piece_type]
	#裁剪出原图中对应网格的纹理
	var content_img = Image.create(target_size.x, target_size.y, false, Image.FORMAT_RGB8)
	var rect = Rect2i(int(x * grid_width), int(y * grid_height), target_size.x, target_size.y)
	content_img.blit_rect(image, rect, Vector2i.ZERO)
	content.texture = ImageTexture.create_from_image(content_img)
	#position = Vector2((x) * grid_width, (y) * grid_height + 10)

#计算碎片尺寸
func get_target_size(_grid_width: float, _grid_height: float, mask_size: Vector2):
	var scale_factor_x = _grid_width / 512.0
	var scale_factor_y = _grid_height / 512.0
	return Vector2(mask_size.x * scale_factor_x, mask_size.y * scale_factor_y)

#是否和其他碎片临近
func is_adjacent(other: PuzzlePiece):
	if abs(x_index - other.x_index) + abs(y_index - other.y_index) != 1:
		return false
	 # 然后检查距离
	var distance = global_position - other.global_position
	# 左右相邻
	if y_index == other.y_index:
		return abs(distance.y) <= TOLERANCE and abs(distance.x) <= grid_width + TOLERANCE and distance.x * (x_index - other.x_index) > 0
	# 上下相邻		
	else:
		return abs(distance.x) <= TOLERANCE and abs(distance.y) <= grid_height + TOLERANCE and distance.y * (y_index - other.y_index) > 0

#吸附到其他碎片，返回吸附的目标位置
func snap_to(other: PuzzlePiece):
	 # 计算索引差异
	var x_diff = x_index - other.x_index
	var y_diff = y_index - other.y_index
	# 计算新的位置
	var new_position = other.global_position
	# 左右相邻
	if y_diff == 0:
		new_position.x += sign(x_diff) * grid_width
	# 上下相邻
	else:
		new_position.y += sign(y_diff) * grid_height
	return new_position
