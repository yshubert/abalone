# abalone_gui.py

from abalone_prolog_ai_engine import AbalonePrologAIEngine, MovesType
import tkinter as tk
from tkinter import messagebox
import time

BLACK = 'black'
WHITE = 'white'
BACKGROUND_COLOR = '#aaaaff'
EMPTY = None
HUMAN_COLOR = BLACK
COMPUTER_COLOR = WHITE

LEVELS = {
	'easy': 2,
	'moderate': 3,
	'hard': 4
}


'''
	Abalone Cell Representation:
		cell_number - cell number
		row - cell row
		column - cell column
		value - cell value
		obj_id - cell ui component object id
'''
class AbaloneCell(object):
	def __init__(self, cell_num, row, column, value):
		self.cell_num = cell_num
		self.row = row
		self.column = column
		self.value = value
		self.obj_id = None


''' 
	Game Board Representation 
	List of AbaloneCells

'''
class AbaloneBoard(list):
	''' Matrix() -> list with all the positions of an abalone's board. '''
	UNUSED_CELLS = [
		0, 1, 2, 3, 4, 5, 11, 12, 13, 14, 15, 22, 23, 24, 25, 33, 34, 35, 44, 45,
		55, 56, 65, 66, 67, 75, 76, 77, 78, 85, 86, 87, 88, 89
	]

	# initiate the list boards.
	def __init__(self):
		super(AbaloneBoard, self).__init__()
		cells = (range(0, 95))
		for cell in cells:
			if cell in self.UNUSED_CELLS:
				self.append(None)
				continue
			column, row = self.cell_to_xy(cell)
			self.append(AbaloneCell(cell, row, column, self.cell_to_value(cell)))

	# Initial board values
	def cell_to_value(self, number):
		if number <= 21:
			return BLACK
		if 28 <= number <= 30:
			return BLACK
		if  70 <= number <= 72:
			return WHITE
		if number >= 79:
			return WHITE
		return EMPTY

	# Cell number to X, Y
	def cell_to_xy(self, number):
		return number % 11, number // 11

# Game Class
class Game(tk.Frame):
	canvas = None
	first_item_selected = None
	second_item_selected = None
	last_computer_move = None
	white_score_txt = None # object id to update the score
	black_score_txt = None # object id to update the score
	game_finished = None


	def __init__(self, master):
		super(Game, self).__init__(master)
		self.game_root = master
		self.width = 800
		self.height = 600
		self.canvas = tk.Canvas(self, bg=BACKGROUND_COLOR,
									width=self.width,
									height=self.height)
		self.initialize_game()


	def initialize_game(self):
		self.ai_engine = AbalonePrologAIEngine() # init PrologAIEngineBridge
		self.abalone_board = AbaloneBoard() # init board representation

		# Add UI Components
		self.canvas.pack()
		self.pack()
		self.canvas.create_text(400, 50, text="Abalone Game", font=("Purisa", 35))
		self.draw_cells()
		self.add_buttons()
		self.add_score()
		self.add_level()

	# add the initialize score to UI board
	def add_score(self):
		self.black_score_txt = self.canvas.create_text(
			60, 100, text="Human Score: 0", font=("Purisa", 15), fill='black')
		self.white_score_txt = self.canvas.create_text(
			69, 125, text="Computer Score: 0", font=("Purisa", 15), fill='white')

	# add level ui component
	def add_level(self):
		self.level = tk.StringVar(self.master)
		self.level.set('moderate')
		tk.OptionMenu(self.master, self.level, *LEVELS.keys(),
								  command = lambda _: self._change_level_event()).pack()

	# Change level in prolog engine according to user selection
	def _change_level_event(self):
		self.ai_engine.change_level(LEVELS.get(self.level.get()))



	# update score in UI -> update the components with new score
	def update_score(self):
		black_score, white_score , won_player = self.ai_engine.get_current_score()
		self.canvas.itemconfigure(self.black_score_txt, text="Human Score: %s" % black_score)
		self.canvas.itemconfigure(self.white_score_txt, text="Computer Score: %s" % white_score)
		if won_player != 'none':
			self.handle_game_victory(won_player)

	# Handle game victory
	#	show winner/loser message box
	#	reset ui
	def handle_game_victory(self, player):

		if player == 'white':
			messagebox.showinfo("Info", "You have lost the game")
		else:
			messagebox.showinfo("Info", "Congratulations, you are the winner!")
		time.sleep(2)
		self._reset_selection()
		self.canvas.delete('all')
		self.game_root.destroy()
		self.game_finished = True

	# add_buttons
	#	add ui buttons: Regular Move, Push Out Move.
	def add_buttons(self):
		regular_move_button = self.canvas.create_rectangle(250, 480, 370, 510, fill="grey40", outline="grey60")
		regular_move_button_txt = self.canvas.create_text(305, 493, text="Regular Move")
		self.canvas.tag_bind(
			regular_move_button, '<ButtonPress-1>', lambda _: self._on_regular_move_click())
		self.canvas.tag_bind(
			regular_move_button_txt, '<ButtonPress-1>', lambda _: self._on_regular_move_click())

		push_out_move_button = self.canvas.create_rectangle(400, 480, 520, 510, fill="grey40", outline="grey60")
		push_out_move_button_txt = self.canvas.create_text(455, 493, text="Push Out Move")
		self.canvas.tag_bind(
			push_out_move_button, '<ButtonPress-1>', lambda _: self._on_push_out_move_click(_))
		self.canvas.tag_bind(
			push_out_move_button_txt, '<ButtonPress-1>', lambda _: self._on_push_out_move_click(_))

	# Execute Computer Move
	#	call prolog method for getting the best computer move from prolog Alphabeta algorithm
	#	execute the move
	# 	update the move [GUI]
	def _exec_computer_move(self):
		self._reset_selection()
		move_type, direction, from_cell, to_cell = self.ai_engine.get_best_move(COMPUTER_COLOR)
		self.last_computer_move = (move_type, direction, from_cell, to_cell)

		if move_type:
			self._make_gui_move(move_type, direction, from_cell, to_cell)
		else:
			messagebox.showinfo("Error", "Error in finding best move")

		self._show_computer_moves(from_cell, to_cell)

	# _show_computer_moves
	#	mark the computer move with a red outline
	def _show_computer_moves(self, from_cell, to_cell):
		self.canvas.itemconfigure(self.abalone_board[from_cell].obj_id, outline='red')
		if type(to_cell) is int:
			self.canvas.itemconfigure(self.abalone_board[to_cell].obj_id, outline='red')

	# _unshow_computer_move
	#	unmark the computer move with a red outline
	def _unshow_computer_move(self):
		if not self.last_computer_move:
			return
		_, _, from_cell, to_cell = self.last_computer_move
		self.canvas.itemconfigure(self.abalone_board[from_cell].obj_id, outline=BLACK)
		if type(to_cell) is int:
			self.canvas.itemconfigure(self.abalone_board[to_cell].obj_id, outline=BLACK)

	# _on_regular_move_click
	#	regular-move button handler - trigger the human move.
	def _on_regular_move_click(self):
		if not (self.first_item_selected and self.second_item_selected):
			messagebox.showinfo("Info", "For making regular move you need to select two cells")
		else:
			self._exec_regular_move()

	# _exec_regular_move
	# 	make the user regular move by the user GUI Selectiom
	#	trigger the computer move
	def _exec_regular_move(self):
		move_type, direction = self.ai_engine.make_move(
			HUMAN_COLOR, self.first_item_selected, self.second_item_selected)
		self.update_score()

		if move_type:
			self._make_gui_move(move_type, direction, self.first_item_selected, self.second_item_selected)
			self._exec_computer_move()
			self.update_score()
		else:
			messagebox.showinfo("Info", "illegal move")

	# _exec_regular_move
	# 	make the user push-out move by the user GUI Selectiom
	#	trigger the computer move
	def _on_push_out_move_click(self, event):
		if not (self.first_item_selected and not self.second_item_selected):
			messagebox.showinfo("Info", "For making push out move you need to select only one cell")
		else:
			move_type, direction  = self.ai_engine.make_move(
				HUMAN_COLOR, self.first_item_selected)
			if move_type:
				self._make_gui_move(move_type, direction, self.first_item_selected)
				self.update_score()
				if self.game_finished:
					return
				self._exec_computer_move()
				self.update_score()
			else:
				messagebox.showinfo("Info", "illegal move")

	# _make_gui_move
	# 	Execute the MOVE in GUI
	def _make_gui_move(self, move_type, direction, from_cell, to_cell=None):
		if move_type == MovesType.WALK:
			self._make_walk_move(from_cell, to_cell)
		if move_type == MovesType.PUSH:
			self._make_push_move(from_cell, to_cell, direction)
		if move_type == MovesType.PUSH_OUT:
			self._make_push_out_move(from_cell, direction)

	# _make_walk_move
	# 	Execute WALK Move in the UI
	def _make_walk_move(self, from_cell, to_cell):
		self.canvas.itemconfigure(self.abalone_board[to_cell].obj_id, fill=self.abalone_board[from_cell].value, outline=BLACK)
		self.abalone_board[to_cell].value = self.abalone_board[from_cell].value
		self.abalone_board[from_cell].value = None
		self.canvas.itemconfigure(self.abalone_board[from_cell].obj_id, fill=BACKGROUND_COLOR, outline=BLACK)
		self.canvas.update()

	# _make_push_out_move
	# 	Execute push-out Move in the UI
	def _make_push_out_move(self, from_cell, direction):
		color = self.abalone_board[from_cell].value
		self.abalone_board[from_cell].value = None
		self.canvas.itemconfigure(self.abalone_board[from_cell].obj_id, fill=BACKGROUND_COLOR, outline=BLACK)
		third_cell = self.abalone_board[from_cell + (direction * 2)]
		if third_cell.value != color and third_cell.value is not None:
			cell_to_change = third_cell
		else:
			cell_to_change = self.abalone_board[from_cell + (direction * 3)]

		self.canvas.itemconfigure(cell_to_change.obj_id, fill=color, outline=BLACK)
		cell_to_change.value = color

	# _make_push_move
	# 	Execute push Move in the UI
	def _make_push_move(self, from_cell, to_cell, direction):
		color = self.abalone_board[from_cell].value
		other_color = self.abalone_board[to_cell - direction].value

		self.canvas.itemconfigure(
			self.abalone_board[to_cell].obj_id, fill=other_color, outline=BLACK)
		self.abalone_board[to_cell].value = other_color

		self.abalone_board[from_cell].value = None
		self.canvas.itemconfigure(self.abalone_board[from_cell].obj_id, fill=BACKGROUND_COLOR, outline=BLACK)

		if self.abalone_board[to_cell - (direction * 2)].value == other_color:
			first_other_color_cell = to_cell - (direction * 2)
		else:
			first_other_color_cell = to_cell - direction

		self.abalone_board[first_other_color_cell].value = color
		self.canvas.itemconfigure(
				self.abalone_board[first_other_color_cell].obj_id, fill=color, outline=BLACK)

	# draw_cells
	# 	draw all cells in the board
	def draw_cells(self):
		for abalone_cell in self.abalone_board:
			if not abalone_cell:
				continue

			self.draw_circle(
				abalone_cell.cell_num, abalone_cell.row, abalone_cell.column, abalone_cell.value)


	# draw_circle
	# 	draw single cell
	def draw_circle(self, cell_num, row, column, value):
		radius = 16
		row_pixel = 40 * row + 120
		column_pixel = 40 * column + 80 + (row * 18)
		self.abalone_board[cell_num].obj_id =  self.canvas.create_oval(
			column_pixel + radius, row_pixel - radius, column_pixel - radius, row_pixel + radius,
			fill=value or BACKGROUND_COLOR, outline=BLACK)

		self.canvas.tag_bind(
			self.abalone_board[cell_num].obj_id, '<ButtonPress-1>', lambda _: self._onCellClick(cell_num))


	# _onCellClick
	#	user click on cell handler
	def _onCellClick(self, cell_number):
		if self.abalone_board[cell_number].value == WHITE:
			return
		if self.first_item_selected and self.second_item_selected:
			self._reset_selection()

		if self.abalone_board[cell_number].value == BLACK:
			self._reset_selection()
			self.first_item_selected = cell_number
			self.canvas.itemconfigure(self.abalone_board[cell_number].obj_id, outline='red')
		elif self.first_item_selected and not self.second_item_selected:
			self.second_item_selected = cell_number
			self.canvas.itemconfigure(self.abalone_board[cell_number].obj_id, outline='red')
		else:
			self._reset_selection()

	# _reset_selection
	#	reset user cell selection.
	def _reset_selection(self):
		if self.first_item_selected:
			self.canvas.itemconfigure(self.abalone_board[self.first_item_selected].obj_id, outline=BLACK)
			self.first_item_selected = None
		if self.second_item_selected:
			self.canvas.itemconfigure(self.abalone_board[self.second_item_selected].obj_id, outline=BLACK)
			self.second_item_selected = None
		self._unshow_computer_move()



def start_game():
	# Game Loop, Once game is completed we start a new game.
	continue_play = True
	while continue_play:
		root = tk.Tk()
		root.title('Abalone')
		game = Game(root)
		game.mainloop()
		continue_play = game.game_finished


if __name__ == '__main__':
	start_game()
