extends Node

enum {EMPTY, BLACK, WHITE}

var game_finished = false;

var current_state;
var current_turn = WHITE;

var history_list = []
var history_count = 0

export var visualizer_path:NodePath;
onready var visualizer = get_node(visualizer_path)

func _ready():
	current_state = State.new(BoardManager.current_board)
	history_list.append(current_state)
	randomize()
	
func _process(delta):
	if Input.is_action_just_pressed("ui_right"):
		
		if not game_finished: #if state was played before
			if range(history_list.size()).has(history_count+1):
				current_state = history_list[history_count+1]
				current_turn = switch_turn(current_turn)
				visualizer.update_board(current_state.board)
				history_count+=1
			else:
			#WHITE plays minimax,BLACK plays random!
				if current_turn == WHITE:
					#var m = minimax(current_state,2,true,WHITE,WHITE)
					var m = alphabeta(current_state,2,-INF,INF,true,WHITE,WHITE)
					var next_state = m[1]
					current_state = next_state
					current_turn = switch_turn(current_turn)
					visualizer.update_board(current_state.board)
				elif current_turn == BLACK:
					var possible_new_states = Successor.calculate_successor(current_state,current_turn);
					var next_state = possible_new_states[randi()%possible_new_states.size()] #random move!
					current_state = next_state
					current_turn = switch_turn(current_turn)
					visualizer.update_board(current_state.board)
				
				history_list.append(current_state)
				history_count+=1

				if current_state.white_score >= 6:
					print("White Won!")
					game_finished = true
				elif current_state.black_score >= 6:
					print("Black Won!")
					game_finished = true
					
	
	elif Input.is_action_just_pressed("ui_left"):
		if history_count != 0:
			history_count-=1
			current_state = history_list[history_count]
			current_turn = switch_turn(current_turn)
			visualizer.update_board(current_state.board)
		
			
		
func minimax(state,depth,maximizer,piece,turn):
	if depth == 0 or state.white_score>=6 or state.black_score>=6:
		return [eval_state(state,piece),state]
	if maximizer:
		var value = -INF
		var best_state = null
		for succesor in Successor.calculate_successor(state,current_turn):
			var temp = minimax(succesor,depth-1,false,piece,switch_turn(current_turn))
			if temp[0]>value:
				value = temp[0]
				best_state = succesor
		return [value,best_state]
	else:
		var value = +INF
		var best_state = null
		for succesor in Successor.calculate_successor(state,current_turn):
			var temp = minimax(succesor,depth-1,false,piece,switch_turn(current_turn))
			if temp[0]<value:
				value = temp[0]
				best_state = succesor
		return [value,best_state]

		
func alphabeta(state,depth,a,b,maximizer,piece,turn):
	if depth == 0 or state.white_score>=6 or state.black_score>=6:
		return [eval_state(state,piece),state]
	if maximizer:
		var value = -INF
		var best_state = null
		for succesor in Successor.calculate_successor(state,current_turn):
			var temp = alphabeta(succesor,depth-1,a,b,false,piece,switch_turn(current_turn))
			if temp[0]>value:
				value = temp[0]
				best_state=succesor
			if value>=b:
				break
			a = max(a,value)
		return [value,best_state]
	else:
		var value = +INF
		var best_state = null
		for succesor in Successor.calculate_successor(state,current_turn):
			var temp = alphabeta(succesor,depth-1,a,b,true,piece,switch_turn(current_turn))
			if temp[0]<value:
				value = temp[0]
				best_state=succesor
			if value<=a:
				break
			b = min(b,value)
		return [value,best_state]
		
			
		
func eval_state(state,piece):
	if state.white_score >= 6:
		if piece == WHITE:
			return INF
		elif piece == BLACK:
			return -INF
	elif state.black_score >= 6:
		if piece == WHITE:
			return -INF
		elif piece == BLACK:
			return INF
	else: #not terminal state
		return heuristic(state,piece)
	
		
func heuristic(state,piece):
	var center_proximity = center_proximity_hueristic(state,piece)
	var cohesion = 0
	if abs(center_proximity) > 2:
		cohesion = populations_heuirsitc(state,piece)
	var marbles = 0
	#if abs(center_proximity) < 1.8:
	marbles = number_of_marbles_heuristic(state,piece)*100
	return (center_proximity)+(cohesion)+marbles
	
	
func center_proximity_hueristic(state,piece): #LOWER IS BETTER!
	var white_center_proximity = 0.0
	var number_of_whites = 0
	var black_center_proximity = 0.0
	var number_of_blacks = 0
	for i in range(61):
		var cell_value = state.board[i]
		if cell_value == WHITE:
			number_of_whites+=1
			white_center_proximity += distance_to_center(i)
		elif cell_value == BLACK:
			number_of_blacks +=1
			black_center_proximity += distance_to_center(i)
	white_center_proximity = white_center_proximity/number_of_whites
	black_center_proximity = black_center_proximity/number_of_blacks
	if piece == BLACK:
		return white_center_proximity - black_center_proximity
	elif piece == WHITE:
		return black_center_proximity - white_center_proximity

	
func distance_to_center(cell_index):
	var distance_dict = {
	0:4,
	1:4,
	2:4,
	3:4,
	4:4,
	5:4,
	6:3,
	7:3,
	8:3,
	9:3,
	10:4,
	11:4,
	12:3,
	13:2,
	14:2,
	15:2,
	16:3,
	17:4,
	18:4,
	19:3,
	20:2,
	21:1,
	22:1,
	23:2,
	24:3,
	25:4,
	26:4,
	27:3,
	28:2,
	29:1,
	30:0}
	
	if cell_index<=30:
		return distance_dict[cell_index]
	else:
		return distance_dict[30 - (cell_index-30)]
		

func populations_heuirsitc(state,piece): 
	var number_of_white_groups = 0
	var number_of_black_groups = 0
	var white_unchecked = []
	var black_unchecked = []
	for i in range(61):
		if state.board[i] == WHITE:
			white_unchecked.append(i)
		elif state.board[i] == BLACK:
			black_unchecked.append(i)

	while white_unchecked:
		var white_neighbours = [white_unchecked.pop_back()]
		while white_neighbours:
			var cell = white_neighbours.pop_back()
			white_unchecked.erase(cell)
			var white_new_neighbours = BoardManager.neighbors.duplicate(true)[cell]
			for c in white_new_neighbours:
				if state.board[c] != WHITE:
					white_new_neighbours.erase(c)
			white_neighbours.append_array(intersect_arrays(white_new_neighbours,white_unchecked))
		number_of_white_groups+=1
	
	while black_unchecked:
		var black_neighbours = [black_unchecked.pop_back()]
		while black_neighbours:
			var cell = black_neighbours.pop_back()
			black_unchecked.erase(cell)
			var black_new_neighbours = BoardManager.neighbors.duplicate(true)[cell]
			for c in black_new_neighbours:
				if state.board[c] != BLACK:
					black_new_neighbours.erase(c)
			black_neighbours.append_array(intersect_arrays(black_new_neighbours,black_unchecked))
		number_of_black_groups+=1
		
	if piece == BLACK:
		return number_of_white_groups - number_of_black_groups
	elif piece == WHITE:
		return number_of_black_groups - number_of_white_groups
			

func number_of_marbles_heuristic(state,piece): 
	var number_of_whites = 0
	var number_of_blacks = 0
	for i in range(61):
		var cell_value = state.board[i]
		if cell_value == WHITE:
			number_of_whites+=1
		elif cell_value == BLACK:
			number_of_blacks +=1
			
	if piece == WHITE:
		return number_of_whites - number_of_blacks
	elif piece == BLACK:
		return number_of_blacks - number_of_whites

func switch_turn(turn):
	if turn == WHITE:
		return BLACK
	elif turn == BLACK:
		return WHITE

func intersect_arrays(arr1, arr2):
	var arr2_dict = {}
	for v in arr2:
		arr2_dict[v] = true

	var in_both_arrays = []
	for v in arr1:
		if arr2_dict.get(v, false):
			in_both_arrays.append(v)
	return in_both_arrays	
	
