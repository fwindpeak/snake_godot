extends Node2D

const GRID_SIZE = 20
const MOVE_SPEED = 0.15  # 蛇运行速度

var direction = Vector2.RIGHT
var next_direction = Vector2.RIGHT
var snake_body = []  # 存储蛇的所有部分，包括头部
var is_moving = false
var move_timer = 0.0
var score = 0

# 获取蛇头节点
var snake_head 
var food_node

# 触摸手势相关变量
var touch_start_pos = Vector2()
var touch_end_pos = Vector2()
var is_touching = false
const SWIPE_THRESHOLD = 50  # 滑动阈值，超过这个距离才认为是有效滑动

func _ready():
	# 初始化蛇头位置
	
	snake_head= $SnakeHead
	food_node = $Food
	var start_pos = Vector2(10, 10) * GRID_SIZE
	snake_head.position = start_pos
	
	# 初始化蛇身体（包含头部位置）
	snake_body = [start_pos]
	
	# 添加初始身体部分
	for i in range(2):
		var body_part = Sprite2D.new()
		body_part.texture = preload("res://assets/snake_body.png")
		body_part.centered = true
		body_part.scale = Vector2(1, 1)
		
		# 计算身体部分位置（在蛇后方）
		var body_pos = start_pos - direction * GRID_SIZE * (i + 1)
		body_part.position = body_pos
		snake_body.append(body_pos)
		
		add_child(body_part)
		body_part.z_index = -1
	
	# 初始化食物
	spawn_food()
	is_moving = true

func _process(delta):
	if not is_moving:
		return
	
	move_timer += delta
	if move_timer >= MOVE_SPEED:
		move_timer = 0.0
		move_snake()

func _input(event):
	# 处理键盘输入
	if event.is_action_pressed("ui_up") and direction != Vector2.DOWN:
		next_direction = Vector2.UP
	elif event.is_action_pressed("ui_down") and direction != Vector2.UP:
		next_direction = Vector2.DOWN
	elif event.is_action_pressed("ui_left") and direction != Vector2.RIGHT:
		next_direction = Vector2.LEFT
	elif event.is_action_pressed("ui_right") and direction != Vector2.LEFT:
		next_direction = Vector2.RIGHT
	
	# 处理触摸输入
	if event is InputEventScreenTouch:
		if event.pressed:
			# 触摸开始
			touch_start_pos = event.position
			is_touching = true
		else:
			# 触摸结束
			if is_touching:
				touch_end_pos = event.position
				handle_swipe_gesture()
				is_touching = false

func handle_swipe_gesture():
	var swipe_vector = touch_end_pos - touch_start_pos
	var swipe_length = swipe_vector.length()
	
	# 检查滑动距离是否超过阈值
	if swipe_length < SWIPE_THRESHOLD:
		return
	
	# 获取主要滑动方向
	var abs_x = abs(swipe_vector.x)
	var abs_y = abs(swipe_vector.y)
	
	# 确定主要滑动方向
	if abs_x > abs_y:
		# 水平滑动
		if swipe_vector.x > 0 and direction != Vector2.LEFT:
			# 向右滑动
			next_direction = Vector2.RIGHT
		elif swipe_vector.x < 0 and direction != Vector2.RIGHT:
			# 向左滑动
			next_direction = Vector2.LEFT
	else:
		# 垂直滑动
		if swipe_vector.y > 0 and direction != Vector2.UP:
			# 向下滑动
			next_direction = Vector2.DOWN
		elif swipe_vector.y < 0 and direction != Vector2.DOWN:
			# 向上滑动
			next_direction = Vector2.UP

func move_snake():
	# 更新方向
	direction = next_direction
	
	# 计算新的头部位置
	var new_head_pos = snake_head.position + direction * GRID_SIZE
	
	# 检查碰撞
	if check_collisions(new_head_pos):
		return
	
	# 移动蛇身体
	var prev_pos = snake_head.position
	snake_head.position = new_head_pos
	
	# 更新身体部分位置
	var body_nodes = get_children()
	var body_index = 0
	
	for node in body_nodes:
		if node is Sprite2D and node != snake_head and node != food_node:
			if body_index < snake_body.size() - 1:
				var temp = node.position
				node.position = prev_pos
				prev_pos = temp
				snake_body[body_index + 1] = node.position
				body_index += 1
	
	# 更新蛇身体数组
	snake_body[0] = new_head_pos
	for i in range(1, snake_body.size()):
		if i <= body_index:
			snake_body[i] = body_nodes[i-1].position

func check_collisions(new_pos):
	var viewport_size = get_viewport_rect().size
	
	# 检查食物碰撞
	if new_pos == food_node.position:
		eat_food()
		return false
	
	# 检查边界碰撞
	if new_pos.x < 0 or new_pos.x >= viewport_size.x or new_pos.y < 0 or new_pos.y >= viewport_size.y:
		game_over()
		return true
	
	# 检查自身碰撞
	for i in range(1, snake_body.size()):
		if new_pos == snake_body[i]:
			game_over()
			return true
	
	
	
	return false

func spawn_food():
	var viewport_size = get_viewport_rect().size
	var grid_width = int(viewport_size.x / GRID_SIZE)
	var grid_height = int(viewport_size.y / GRID_SIZE)
	
	var valid_positions = []
	
	# 生成所有可能的位置
	for x in range(1, grid_width - 1):
		for y in range(1, grid_height - 1):
			var pos = Vector2(x, y) * GRID_SIZE
			var occupied = false
			
			# 检查是否与蛇身体重叠
			for body_pos in snake_body:
				if pos == body_pos:
					occupied = true
					break
			
			if not occupied:
				valid_positions.append(pos)
	
	if valid_positions.size() > 0:
		food_node.position = valid_positions[randi() % valid_positions.size()]
		food_node.show()

func eat_food():
	score += 10
	update_score(score)
	
	# 添加新的身体部分
	var new_part = Sprite2D.new()
	new_part.texture = preload("res://assets/snake_body.png")
	new_part.centered = true
	new_part.scale = Vector2(1, 1)
	
	# 添加到最后一个身体部分后面
	var last_pos = snake_body[-1]
	new_part.position = last_pos
	
	add_child(new_part)
	new_part.z_index = -1
	
	snake_body.append(last_pos)
	
	# 生成新食物
	spawn_food()

func update_score(new_score):
	# 更新UI
	var ui_node = get_parent().get_node("UI")
	if ui_node:
		ui_node.get_node("ScoreLabel").text = "Score: %d" % new_score

func game_over():
	is_moving = false
	var ui_node = get_parent().get_node("UI")
	if ui_node:
		ui_node.get_node("GameOverPanel").visible = true
