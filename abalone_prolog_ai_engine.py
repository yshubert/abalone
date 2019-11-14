# abalone_prolog_ai_engine

import os
os.environ['SWI_LIB_DIR'] = '/usr/local/Cellar/swi-prolog/8.0.3/libexec/lib/swipl/lib'
from pyswip import Prolog

# Supported Moves Type
class MovesType(object):
	WALK = 'walk'
	PUSH = 'push'
	PUSH_OUT = 'push_out'

# Map from Prolog moves types to MovesType
PROLOG_MOVES_TO_PUSH_TYPE = {
	'1': MovesType.WALK,
	'2': MovesType.WALK,
	'3': MovesType.WALK,
	'push2': MovesType.PUSH,
	'push3': MovesType.PUSH,
	'push3_2': MovesType.PUSH,
	'push_out': MovesType.PUSH_OUT,
	'push_out3': MovesType.PUSH_OUT,
	'push_out3_2': MovesType.PUSH_OUT,
}


class AbalonePrologAIEngine(object):

	# loads the abalone.pl prolog file
	def __init__(self):
		self.swipl = Prolog()
		self.swipl.consult("./abalone.pl")
		result = list(self.swipl.query("start_game"))
		if not result:
			raise Exception('Error in initializing the game')

	# make_move
	#   @color - the color of the current player
	#   @from_cell - the beginning cell of the move
	#   #end_cell - the end cell of the move
	#   execute in prolog:
	#       can_make_move query for validation the move is valid
	#       make_move query for executing the move in prolog.
	#   returns tuple of the MoveType and Move Direction
	def make_move(self, color, from_cell, to_cell='not_exist'):
		result = list(self.swipl.query(
			"can_make_move(MoveType, %s, Direction, %s, %s), "
			"make_move(MoveType, %s, Direction, %s, %s)" % (
				color, from_cell, to_cell, color, from_cell, to_cell)))
		if not result:
			return None, None
		return PROLOG_MOVES_TO_PUSH_TYPE[str(result[0]['MoveType'])], result[0]['Direction']

	# make_move
	#   @color - the color of the current player
	#   execute in prolog:
	#       get_best_move query for getting the computer best move
	#       make_move query for executing the move in prolog.
	#   returns tuple of the MoveType, Move Direction, FromCell, EndCell
	def get_best_move(self, color):
		result = list(self.swipl.query(
			"get_best_move(%s, MoveType, Direction, From, To)" % color))
		if not result:
			return None, None, None, None
		query = "make_move(%s, %s, %s, %s, %s)" % (
				(result[0]['MoveType']), color, result[0]['Direction'], result[0]['From'], result[0]['To'])
		result2 = list(self.swipl.query(query))
		if not result2:
			print('unexpected error')
		return PROLOG_MOVES_TO_PUSH_TYPE[str(result[0]['MoveType'])], result[0]['Direction'], \
			   result[0]['From'], result[0]['To']

	def change_level(self, level):
		self.swipl.retract("level(OldLevel)" )
		self.swipl.asserta('level(%s)' % level)

	# get_current_score
	#   execute in prolog
	#       game_score query for getting the current game score
	#   returns tuple of the number of white cells, blackcells, and weather the game ended.
	def get_current_score(self):
		result = list(self.swipl.query("game_score(Black, White, Victory)"))
		return result[0]['White'], result[0]['Black'], result[0]['Victory']
