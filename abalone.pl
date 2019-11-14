% abalone.pl

member(X, [X|_]).
member(X, [_|Tail]):- member(X, Tail).

% Cell that are not in used, we have hexagonal board - so some of the square cells are unavailable
unused_cells([
	11, 12, 13, 14, 15, 22, 23, 24, 25, 33, 34, 35, 44, 45,
	55, 56, 65, 66, 67, 75, 76, 77, 78, 85, 86, 87, 88, 89]).


% We give a prioritize rank for each move type
% used for sorting the moves list.
rank(1, 1).
rank(2, 2).
rank(3, 3).
rank(push2, 4).
rank(push3, 5).
rank(push3_2, 6).
rank(push_out, 7).
rank(push_out3, 8).
rank(push_out3_2, 9).


% set MAX as the black player
player(1, black).
% set MIN as the white player
player(-1, white).

% get a Color, and set the OtherColor.
second_color(Color, OtherColor):-
	player(P, Color), P1 is P * (-1), player(P1, OtherColor).


% Check if a cell is unused
is_unused_cell(CellNumber):-
	unused_cells(CellList), member(CellNumber, CellList).


%%%%%%%% build_board %%%%%%%%%
% recursive function which get a cell, and assert it with the value of the cell in the initial state of the board,
% then it calls build_board with the next cell.
% end condition is when we reach the last cell.

% Build the abalone hexagonal board
% if the cell number is not unused cell assert the cell_value(Number, Value) to the prolog engine
build_board(Number):-
	Number < 95,
	(\+ is_unused_cell(Number)), !,
	board_initial_value(Number, Value),
	assert(cell_value(Number, Value)),
	NewNumber is Number + 1,
	build_board(NewNumber).

% because of the cut here is unused cell case so we just increment the cell Number
build_board(Number):-
   Number < 95, !,
   NewNumber is Number + 1,
   build_board(NewNumber).

% End Condition
build_board(95).

% Black Cell Condition
board_initial_value(Number, black):-
	Number < 22, !.

% Black Cell Condition
board_initial_value(Number, black):-
	Number < 31, Number > 27, !.

% White Cell Condition
board_initial_value(Number, white):-
	Number > 78, !.

% White Cell Condition
board_initial_value(Number, white):-
	Number > 69, Number < 73, !.

% Otherwise empty.
board_initial_value(_ , empty).

default_level(3).

change_level(Level):-
    retract(level(_)),
    assert(level(Level)).

% start_game Rule
%   build the board
%   assert the number of cells for each player
%   calculate and assert the dist from center for each of the player 
start_game:-
	build_board(6),
	default_level(Default_level),
	assert(level(Default_level)),
	assert(amount(black, 14)),
	assert(amount(white, 14)),
	dist_from_center(black, BlackDist),
	dist_from_center(white, WhiteDist),
	assert(board_distance_from_center(white, WhiteDist)),
	assert(board_distance_from_center(black, BlackDist)).


% Prolog Moves direction
directions([-1, 10, 11, 1, -10, -11]).

% Check if direction is valid.
is_valid_direction(Direction):-
	directions(List), member(Direction, List).


update_distance_from_center(remove, CellNum, Color):-
    retract(board_distance_from_center(Color, Distance)),
    distance_from_center(CellNum, CellDist),
    NewDist is Distance - CellDist,
    assert(board_distance_from_center(Color, NewDist)).

update_distance_from_center(add, CellNum, Color):-
    retract(board_distance_from_center(Color, Distance)),
    distance_from_center(CellNum, CellDist),
    NewDist is Distance + CellDist,
    assert(board_distance_from_center(Color, NewDist)).


% can_make_move Rules
% All those moves rules validates if a move is valid and possible
% Params: MoveType, Color, Direction, FromCell, ToCell

%move with 1 cell
can_make_move(1, Color, Direction, FromCell, ToCell):-
	(var(ToCell); ToCell \= not_exist),
	cell_value(FromCell, Color), Color \= empty,
	is_valid_direction(Direction),
	ToCell is FromCell + Direction,
	cell_value(ToCell, empty).

%move with 2 cells
can_make_move(2, Color, Direction, FromCell, ToCell):-
	(var(ToCell); ToCell \= not_exist),
	cell_value(FromCell, Color), Color \= empty,
	is_valid_direction(Direction),
	SecondCell is FromCell + Direction,
	can_make_move(1, Color, Direction, SecondCell, ToCell).

%move with 3 cells
can_make_move(3, Color, Direction, FromCell, ToCell):-
	(var(ToCell); ToCell \= not_exist),
	cell_value(FromCell, Color), Color \= empty,
	is_valid_direction(Direction),
	SecondCell is FromCell + Direction,
	can_make_move(2, Color, Direction, SecondCell, ToCell).

% can make push with 2 player one player.
can_make_move(push2, Color, Direction, FromCell, ToCell):-
	(var(ToCell); ToCell \= not_exist),
   cell_value(FromCell, Color),
	is_valid_direction(Direction),
	SecondCell is FromCell + Direction,
	cell_value(SecondCell, Color),
	ThirdCell is SecondCell + Direction,
	cell_value(ThirdCell, Color2),
	Color2 \= empty, Color2 \= Color,
	ToCell is ThirdCell + Direction,
	cell_value(ToCell, empty).

% can make push with 3 player one player.
can_make_move(push3, Color, Direction, FromCell, ToCell):-
	(var(ToCell); ToCell \= not_exist),
	cell_value(FromCell, Color),
	is_valid_direction(Direction),
	SecondCell is FromCell + Direction,
	cell_value(SecondCell, Color),
	can_make_move(push2, Color, Direction, SecondCell, ToCell).

% can make push with 3 players  2 player.
can_make_move(push3_2, Color, Direction, FromCell, ToCell):-
	(var(ToCell); ToCell \= not_exist),
	cell_value(FromCell, Color),
	is_valid_direction(Direction),
	SecondCell is FromCell + Direction,
	cell_value(SecondCell, Color),
	ThirdCell is SecondCell + Direction,
	cell_value(ThirdCell, Color),
	FourthCell is ThirdCell + Direction,
	cell_value(FourthCell, Color2),
	Color2 \= Color, Color2 \= empty,
	FifthCell is FourthCell + Direction,
	cell_value(FifthCell, Color2),
	ToCell is FifthCell + Direction,
	cell_value(ToCell, empty).

% can make push out by pushing with 2 players  1 player.
can_make_move(push_out, Color, Direction, FromCell, not_exist):-
	is_valid_direction(Direction),
	cell_value(FromCell, Color), Color \= empty,
	SecondCell is FromCell + Direction,
	cell_value(SecondCell, Color),
	ThirdCell is SecondCell + Direction,
	cell_value(ThirdCell, Color2),
	Color2 \= Color, Color2 \= empty,
	FourthCell is ThirdCell + Direction,
	\+ cell_value(FourthCell, _).


% can make push out by pushing with 3 players  1 player.
can_make_move(push_out3, Color, Direction, FromCell, not_exist):-
	is_valid_direction(Direction),
	cell_value(FromCell, Color), Color \= empty,
	SecondCell is FromCell + Direction,
	cell_value(SecondCell, Color),
	ThirdCell is SecondCell + Direction,
	cell_value(ThirdCell, Color),
	FourthCell is ThirdCell + Direction,
	cell_value(FourthCell, Color2),
	Color2 \= Color, Color2 \= empty,
	FifthCell is FourthCell + Direction,
	\+ cell_value(FifthCell, _).

% can make push out by pushing with 3 players  2 player.
can_make_move(push_out3_2, Color, Direction, FromCell, not_exist):-
	is_valid_direction(Direction),
	cell_value(FromCell, Color), Color \= empty,
	SecondCell is FromCell + Direction,
	cell_value(SecondCell, Color),
	ThirdCell is SecondCell + Direction,
	cell_value(ThirdCell, Color),
	FourthCell is ThirdCell + Direction,
	cell_value(FourthCell, Color2),
	Color2 \= Color, Color2 \= empty,
	FifthCell is FourthCell + Direction,
	cell_value(FifthCell, Color2),
	Sixth is FifthCell + Direction,
	\+ cell_value(Sixth, _).


% execute a WALK move
make_move(RegMove, Color, _, FromCell, ToCell):-
	member(RegMove, [1, 2, 3]),
	retract(cell_value(FromCell, Color)),
	update_distance_from_center(remove, FromCell, Color),
	assert(cell_value(FromCell,empty)),
	retract(cell_value(ToCell, empty)),
	assert(cell_value(ToCell,Color)),
	update_distance_from_center(add, ToCell, Color).


% execute a PUSH move with 2 players 1 player
make_move(push2, Color, Direction, FromCell, ToCell):-
	retract(cell_value(FromCell, Color)),
	update_distance_from_center(remove, FromCell, Color),
	assert(cell_value(FromCell,empty)),
	ThirdCell is FromCell + (Direction *2),
	second_color(Color, Color2),
	retract(cell_value(ThirdCell, Color2)),
	update_distance_from_center(remove, ThirdCell, Color2),
	assert(cell_value(ThirdCell, Color)),
	update_distance_from_center(add, ThirdCell, Color),
	retract(cell_value(ToCell, empty)),
	assert(cell_value(ToCell,Color2)),
	update_distance_from_center(add, ToCell, Color2).


% execute a PUSH move with 3
make_move(PushWith3, Color, Direction, FromCell, ToCell):-
	member(PushWith3, [push3_2, push3]),
	retract(cell_value(FromCell, Color)),
	update_distance_from_center(remove, FromCell, Color),
	assert(cell_value(FromCell,empty)),
	FourthCell is FromCell + (Direction *3),
	second_color(Color, Color2),
	retract(cell_value(FourthCell, Color2)),
	update_distance_from_center(remove, FourthCell, Color2),
	assert(cell_value(FourthCell, Color)),
	update_distance_from_center(add, FourthCell, Color),
	retract(cell_value(ToCell, empty)),
	assert(cell_value(ToCell,Color2)),
	update_distance_from_center(add, ToCell, Color2).


% execute a Push Out move with 2 players 1 player
make_move(push_out, Color, Direction, FromCell, not_exist):-
	retract(cell_value(FromCell, Color)),
	update_distance_from_center(remove, FromCell, Color),
	assert(cell_value(FromCell,empty)),
	ThirdCell is FromCell + (Direction *2),
	second_color(Color, Color2),
	retract(cell_value(ThirdCell, Color2)),
	update_distance_from_center(remove, ThirdCell, Color2),
	assert(cell_value(ThirdCell, Color)),
	update_distance_from_center(add, ThirdCell, Color),
	retract(amount(Color2, Amount)),
	NewAmount is Amount - 1,
	assert(amount(Color2, NewAmount)).

% execute a Push Out move with 3 players 1 player
make_move(push_out3, Color, Direction, FromCell, not_exist):-
	make_move(push_out3_2, Color, Direction, FromCell, not_exist).

% execute a Push Out move with 3 players 2 player
make_move(push_out3_2, Color, Direction, FromCell, not_exist):-
	retract(cell_value(FromCell, Color)),
	update_distance_from_center(remove, FromCell, Color),
	assert(cell_value(FromCell,empty)),
	FourthCell is FromCell + (Direction *3),
	second_color(Color, Color2),
	retract(cell_value(FourthCell, Color2)),
	update_distance_from_center(remove, FourthCell, Color2),
	assert(cell_value(FourthCell, Color)),
	update_distance_from_center(add, FourthCell, Color),
	retract(amount(Color2, Amount)),
	NewAmount is Amount - 1,
	assert(amount(Color2, NewAmount)).


% Undo a Walk Move
undo_move(RegMove, Color, _, FromCell, ToCell):-
	member(RegMove, [1, 2, 3]),
	retract(cell_value(FromCell, empty)),
	retract(cell_value(ToCell, Color)),
	update_distance_from_center(remove, ToCell, Color),
	assert(cell_value(FromCell,Color)),
	update_distance_from_center(add, FromCell, Color),
	assert(cell_value(ToCell, empty)).

% Undo a Push Move with 2 players 1 player
undo_move(push2, Color, Direction, FromCell, ToCell):-
	retract(cell_value(FromCell, empty)),
	assert(cell_value(FromCell,Color)),
	update_distance_from_center(add, FromCell, Color),
	ThirdCell is FromCell + (Direction *2),
	second_color(Color, Color2),
	retract(cell_value(ThirdCell, Color)),
	update_distance_from_center(remove, ThirdCell, Color),
	assert(cell_value(ThirdCell, Color2)),
	update_distance_from_center(add, ThirdCell, Color2),
	retract(cell_value(ToCell, Color2)),
	update_distance_from_center(remove, ToCell, Color2),
	assert(cell_value(ToCell, empty)).

% Undo a Push Move with 3 players 1/2 player
undo_move(PushWith3, Color, Direction, FromCell, ToCell):-
	member(PushWith3, [push3_2, push3]),
	retract(cell_value(FromCell, empty)),
	assert(cell_value(FromCell,Color)),
	update_distance_from_center(add, FromCell, Color),
	FourthCell is FromCell + (Direction *3),
	second_color(Color, Color2),
	retract(cell_value(FourthCell, Color)),
	update_distance_from_center(remove, FourthCell, Color),
	assert(cell_value(FourthCell, Color2)),
	update_distance_from_center(add, FourthCell, Color2),
	retract(cell_value(ToCell, Color2)),
	update_distance_from_center(remove, ToCell, Color2),
	assert(cell_value(ToCell, empty)).


% Undo a Push Out Move with 2 players 1 player
undo_move(push_out, Color, Direction, FromCell, not_exist):-
	retract(cell_value(FromCell, empty)),
	assert(cell_value(FromCell,Color)),
	update_distance_from_center(add, FromCell, Color),
	ThirdCell is FromCell + (Direction *2),
	second_color(Color, Color2),
	retract(cell_value(ThirdCell, Color)),
	update_distance_from_center(remove, ThirdCell, Color),
	assert(cell_value(ThirdCell, Color2)),
	update_distance_from_center(add, ThirdCell, Color2),
	retract(amount(Color2, Amount)),
	NewAmount is Amount + 1,
	assert(amount(Color2, NewAmount)).

% Undo a Push Out Move with 3 players 1 player
undo_move(push_out3, Color, Direction, FromCell, not_exist):-
    undo_move(push_out3_2, Color, Direction, FromCell, not_exist).

% Undo a Push Out Move with 3 players 2 player
undo_move(push_out3_2, Color, Direction, FromCell, not_exist):-
	retract(cell_value(FromCell, empty)),
	assert(cell_value(FromCell,Color)),
	update_distance_from_center(add, FromCell, Color),
	FourthCell is FromCell + (Direction *3),
	second_color(Color, Color2),
	retract(cell_value(FourthCell, Color)),
	update_distance_from_center(remove, FourthCell, Color),
	assert(cell_value(FourthCell, Color2)),
	update_distance_from_center(add, FourthCell, Color2),
	retract(amount(Color2, Amount)),
	NewAmount is Amount + 1,
	assert(amount(Color2, NewAmount)).


% this rule return the game status: number of black, white cells and if the game has ended
game_score(Black, White, Victory):-
   amount(black, BlackNum),
   amount(white, WhiteNum),
   Black is 14 - BlackNum,
   White is 14 - WhiteNum,
   victory(Victory).


% return the winner color.
victory(Color):-
    amount(LostColor, 8), second_color(LostColor, Color), !.

victory(none).


%all_moves_for_player rule
%  The relation gets the CurrentState - (Player, _, _, _, _), The Current Depth Level in the tree
% return a SortedMoves List of the top ranked moves
%  1. calculate the new Player - the next turn player
%  2. find all cells which belongs to the new player
%  3. find all all moves from those cells.
%  4. return the top MovesLen moves.

all_moves_for_player((Player, _, _, _, _), CurrDepth, SortedMoves):-
	player(Player, Color),
	NewPlayer is Player* -1,
	findall((NewPlayer, MoveType, Direction, FromCell, ToCell),
	(cell_value(FromCell, Color),
		can_make_move(MoveType, Color, Direction, FromCell, ToCell)),
		Moves),
    level(Depth),
	MovesLen is 20  - (4 * (Depth - CurrDepth)),
	sort_moves_with_limit(Moves, SortedMoves, MovesLen).


% get a list and returns SortedList in length of Limit.
sort_moves_with_limit([], [], _):- !.
sort_moves_with_limit(_, [], 0):- !.
sort_moves_with_limit(List, [Elem|SortedListWithout], Limit):-
	biggest_in_list(Elem, List), !,
	delete_element_from_list(Elem, List, ListWithout),
	NewLimit is Limit - 1,
	sort_moves_with_limit(ListWithout, SortedListWithout, NewLimit).

% find the top ranked element in a list.
biggest_in_list((Player, MoveType, Direction, From, To), List):-
	member((Player, MoveType, Direction, From, To), List),
	rank(MoveType, Rank),
	\+ ( member((_, MoveType2, _, _, _), List),  rank(MoveType2, Rank2), Rank2 > Rank).

% deletes an element from list.
delete_element_from_list(Elem, [Elem|Tail], Tail):- !.
delete_element_from_list(Elem, [Elem2|Tail], [Elem2|TailNewList]):-
	delete_element_from_list(Elem, Tail, TailNewList).


% The heuristic function - calculate the board score.
% explain on the score logic can be found in the Doc.
static_val(_ , Val):-
	amount(black, BlackNum),
	amount(white, WhiteNum),
	board_distance_from_center(black, BlackDist),
	board_distance_from_center(white, WhiteDist),
	Val is ((((BlackNum * 100) - (WhiteNum * 100))  - BlackDist + WhiteDist)).


% Calculate a distance of all cells of the specifid Color from the Center.
dist_from_center(Color, TotalDist):-
	findall(Distance,
		(cell_value(Cell, Color), distance_from_center(Cell, Distance)), List),
	sum_list(List, TotalDist).

% Calculate the sum of a list.
sum_list([], 0):- !.
sum_list([X|Tail], Sum):-
	sum_list(Tail, Sum1), Sum is Sum1 + X.

% Calculate the distance from the center of a cell.
distance_from_center(Cell, Dist):-
	get_xy(Cell, X, Y),
	distance(X, Y, 4, 4, Dist).

% Calculate the distance of two points.
distance(X,Y, X2, Y2, Dist):-
	Temp is ((Y - Y2) * (Y - Y2) + (X - X2) * (X - X2)),
	Dist is sqrt(Temp).


% transform the number of a cell, to X and Y axis of the board.
get_xy(CellNumber, X, Y):-
	Y is (CellNumber -1) // 11,
	Offset is ((Y - 6) // 2),
	X is (CellNumber - 1 + Offset) mod 11.


% get_best_move
% Params: get Color of player
% returns the next best move for player.
% 1. validate the game is not ended - there are more than 8 cells for each player.
% call the alpha_beta for getting the best move ( we limit the Depth level of the tree)
get_best_move(Color, MoveType, Direction, From, To):-
    player(Player, Color),
	amount(white, Amount1), Amount1 > 8,
	amount(black, Amount2), Amount2 > 8,
	level(Depth),
	alpha_beta((Player, _, _, _, _), Depth, -999999, 999999, (_, MoveType, Direction, From, To), _).

% make_move
% Params: get the curr state,
% execute the move by calling the make_move relation.
make_move((NextPlayer, MoveType, Direction, From, To)):-
	player(NextPlayer, Color),
	second_color(Color, FirstColor),
	make_move(MoveType, FirstColor, Direction, From, To).

% make_move
% Params: get the curr state,
% undo the move by calling the undo_move relation.
undo_move((NextPlayer, MoveType, Direction, From, To)):-
	player(NextPlayer, Color),
	second_color(Color, FirstColor),
	undo_move(MoveType,FirstColor, Direction, From, To).

%%%%%%%%%% ALPHA BETA %%%%%%%%%%%
max_to_move((1 ,_, _ , _ , _) ).
min_to_move( (-1 , _,_ , _ , _) ).

% modify the alpha_beta to check the MaxDepth is > 0, for limit the tree depth
alpha_beta(State, MaxDepth, Alpha, Beta, GoodState, Val):-
    MaxDepth > 0, !,
    all_moves_for_player(State, MaxDepth, StateList),
    bounded_best(StateList, MaxDepth, Alpha, Beta, GoodState, Val);
    static_val(State, Val). % heuristic value of state

% For calculating the move score -
% we make the move , and after we finish to develop the move tree we undo the move.
bounded_best([State|StateList], MaxDepth, Alpha, Beta, GoodState, GoodVal) :-
    NewMaxDepth is MaxDepth - 1,
    make_move(State),
    alpha_beta(State, NewMaxDepth, Alpha, Beta, _, Val),
    undo_move(State),
    good_enough(StateList, Alpha, Beta, State, Val, GoodState, GoodVal, MaxDepth).


good_enough([], _, _, State, Val, State, Val, _) :- !. % No other candidate

good_enough(_, Alpha, Beta, State, Val, State, Val, _) :-
    min_to_move(State), Val > Beta, !; % Maximizer attained upper bound
    max_to_move(State), Val < Alpha, !. % Minimizer attained lower bound

good_enough(StateList, Alpha, Beta, State, Val, GoodState, GoodVal, MaxDepth) :-
    new_bounds(Alpha, Beta, State, Val, NewAlpha, NewBeta), % Refine bounds
    bounded_best(StateList, MaxDepth, NewAlpha, NewBeta, State1, Val1),
    better_of(State, Val, State1, Val1, GoodState, GoodVal).

new_bounds(Alpha, Beta, State, Val, Val, Beta) :-
    min_to_move(State), Val > Alpha, !. % Maximizer increased lower bound

new_bounds(Alpha, Beta, State, Val, Alpha, Val) :-
    max_to_move(State), Val < Beta, !. % Minimizer decreased upper bound

new_bounds(Alpha, Beta, _, _, Alpha, Beta). % bounds are not changed.

better_of(State, Val, _, Val1, State, Val):- % Pos better than Pos1
    min_to_move(State), Val > Val1, !;
    max_to_move(State), Val < Val1, !.

better_of(_, _, State1, Val1, State1, Val1). % Otherwise Pos1 is better
