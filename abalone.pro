level(2).

member(X, [X|_]).
member(X, [_|Tail]):- member(X, Tail).

translate_move(1, walk).
translate_move(2, walk).
translate_move(3, walk).
translate_move(push2, push).
translate_move(push3, push).
translate_move(push3_2, push).
translate_move(push_out, push_out).
translate_move(push_out3, push_out).
tranlslate_move(push_out3_2, push_out).


rank(1, 1).
rank(2, 2).
rank(3, 3).
rank(push2, 4).
rank(push3, 5).
rank(push3_2, 6).
rank(push_out, 7).
rank(push_out3, 8).
rank(push_out3_2, 9).

player(1, black).
player(-1, white).

second_color(Color, OtherColor):-
	player(P, Color), P1 is P * (-1), player(P1, OtherColor).

unused_cells([
	11, 12, 13, 14, 15, 22, 23, 24, 25, 33, 34, 35, 44, 45, 
	55, 56, 65, 66, 67, 75, 76, 77, 78, 85, 86, 87, 88, 89]).

is_unused_cell(CellNumber):-
	unused_cells(CellList), member(CellNumber, CellList).

:-
	build_board(6).

% cell_value, add_to_board

% Optimize with Cut.
build_board(Number):-
	Number < 95,
	not is_unused_cell(Number),
	board_initial_value(Number, Value),
	assert(cell_value(Number, Value)),
	NewNumber is Number + 1,
	build_board(NewNumber).
	
build_board(Number):-
   Number < 95,
   is_unused_cell(Number),
   NewNumber is Number + 1,
	build_board(NewNumber).


build_board(95).

board_initial_value(36, white):- !.
board_initial_value(46, white):- !.
board_initial_value(47, white):- !.
board_initial_value(48, white):- !.
board_initial_value(26, black):- !.
board_initial_value(22, black):- !.
board_initial_value(30, black):- !.
board_initial_value(38, white):- !.
%board_initial_value(46, white):- !.
board_initial_value(Number, black):-
	Number < 22, !.
	
board_initial_value(Number, black):-
	Number < 31, Number > 27, !.
	
board_initial_value(Number, white):-
	Number > 78, !.

board_initial_value(Number, white):-
	Number > 69, Number < 73, !.

board_initial_value(Number, empty).

amount(black, 14).
amount(white, 14).
types(black).
types(white).
types(empty).

change_member_in_list(
	cell_value(Num, Val), [cell_value(Num, Val2)| Tail], [cell_value(Num, Val)| Tail]):- !.

change_member_in_list(
	cell_value(Num, Val), [cell_value(Num2, Val2)| Tail], [cell_value(Number, Val)| List]):- 
	
	change_member_in_list(cell_value(Num, Val), Tail, List).


directions([-1, 10, 11, 1, -10, -11]).

is_valid_direction(Direction):-
	directions(List), member(Direction, List).

% Can Make Move Rules

can_make_move(1, Color, Direction, FromCell, ToCell):-
	(var(ToCell); ToCell \= not_exist),
	cell_value(FromCell, Color), Color \= empty,
	is_valid_direction(Direction),
	ToCell is FromCell + Direction,
	cell_value(ToCell, empty).
	
can_make_move(2, Color, Direction, FromCell, ToCell):-
	(var(ToCell); ToCell \= not_exist),
	cell_value(FromCell, Color), Color \= empty,
	is_valid_direction(Direction),
	SecondCell is FromCell + Direction,
	can_make_move(1, Color, Direction, SecondCell, ToCell).
	

can_make_move(3, Color, Direction, FromCell, ToCell):-
	(var(ToCell); ToCell \= not_exist),
	cell_value(FromCell, Color), Color \= empty,
	is_valid_direction(Direction),
	SecondCell is FromCell + Direction,
	can_make_move(2, Color, Direction, SecondCell, ToCell).

make_move(RegMove, Color, Direction, FromCell, ToCell):-
	member(RegMove, [1, 2, 3]),
	retract(cell_value(FromCell, Color)),
	assert(cell_value(FromCell,empty)),
	retract(cell_value(ToCell, empty)),
	assert(cell_value(ToCell,Color)).

undo_move(RegMove, Color, Direction, FromCell, ToCell):-
	member(RegMove, [1, 2, 3]),
	retract(cell_value(FromCell, empty)),
	assert(cell_value(FromCell,Color)),
	retract(cell_value(ToCell, Color)),
	assert(cell_value(ToCell,empty)).


% can make push of 2 player one player.
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
	
make_move(push2, Color, Direction, FromCell, ToCell):-
	retract(cell_value(FromCell, Color)),
	assert(cell_value(FromCell,empty)),
	ThirdCell is FromCell + (Direction *2), 
	second_color(Color, Color2),
	retract(cell_value(ThirdCell, Color2)),
	assert(cell_value(ThirdCell, Color)),
	retract(cell_value(ToCell, empty)),
	assert(cell_value(ToCell,Color2)).

undo_move(push2, Color, Direction, FromCell, ToCell):-
	retract(cell_value(FromCell, empty)),
	assert(cell_value(FromCell,Color)),
	ThirdCell is FromCell + (Direction *2), 
	second_color(Color, Color2),
	retract(cell_value(ThirdCell, Color)),
	assert(cell_value(ThirdCell, Color2)),
	retract(cell_value(ToCell, Color2)),
	assert(cell_value(ToCell, empty)).
	

% can make push of 3 player one player.
can_make_move(push3, Color, Direction, FromCell, ToCell):-	
	(var(ToCell); ToCell \= not_exist),
	cell_value(FromCell, Color),
	is_valid_direction(Direction),
	SecondCell is FromCell + Direction,
	cell_value(SecondCell, Color),
	can_make_move(push2, Color, Direction, SecondCell, ToCell).

% can make push of 3 player one player.
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


make_move(PushWith3, Color, Direction, FromCell, ToCell):-
	member(PushWith3, [push3_2, push3]),
	retract(cell_value(FromCell, Color)),
	assert(cell_value(FromCell,empty)),
	FourthCell is FromCell + (Direction *3), 
	second_color(Color, Color2),
	retract(cell_value(FourthCell, Color2)),
	assert(cell_value(FourthCell, Color)),
	retract(cell_value(ToCell, empty)),
	assert(cell_value(ToCell,Color2)).

undo_move(PushWith3, Color, Direction, FromCell, ToCell):-
	member(PushWith3, [push3_2, push3]),
	retract(cell_value(FromCell, empty)),
	assert(cell_value(FromCell,Color)),
	FourthCell is FromCell + (Direction *3), 
	second_color(Color, Color2),
	retract(cell_value(FourthCell, Color)),
	assert(cell_value(FourthCell, Color2)),
	retract(cell_value(ToCell, Color2)),
	assert(cell_value(ToCell, empty)).
	
can_make_move(push_out, Color, Direction, FromCell, not_exist):-	
	is_valid_direction(Direction),
	cell_value(FromCell, Color), Color \= empty,
	SecondCell is FromCell + Direction,
	cell_value(SecondCell, Color),
	ThirdCell is SecondCell + Direction,
	cell_value(ThirdCell, Color2),
	Color2 \= Color, Color2 \= empty,
	FourthCell is ThirdCell + Direction,
	not cell_value(FourthCell, _).

make_move(push_out, Color, Direction, FromCell, not_exist):-
	retract(cell_value(FromCell, Color)),
	assert(cell_value(FromCell,empty)),
	ThirdCell is FromCell + (Direction *2),
	second_color(Color, Color2),
	retract(cell_value(ThirdCell, Color2)),
	assert(cell_value(ThirdCell, Color)),
	retract(amount(Color2, Amount)),
	NewAmount is Amount - 1,
	assert(amount(Color2, NewAmount)).

undo_move(push_out, Color, Direction, FromCell, not_exist):-
	member(PushWith3, [push3_2, push3]),
	retract(cell_value(FromCell, empty)),
	assert(cell_value(FromCell,Color)),
	ThirdCell is FromCell + (Direction *2), 
	second_color(Color, Color2),
	retract(cell_value(ThirdCell, Color)),
	assert(cell_value(ThirdCell, Color2)),
	retract(amount(Color2, Amount)),
	NewAmount is Amount + 1,
	assert(amount(Color2, NewAmount)).


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
	not cell_value(FifthCell, _).
	
make_move(push_out3, Color, Direction, FromCell, not_exist):-
	make_move(push_out3_2, Color, Direction, FromCell, not_exist).

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
	not cell_value(Sixth, _).


make_move(push_out3_2, Color, Direction, FromCell, not_exist):-
	retract(cell_value(FromCell, Color)),
	assert(cell_value(FromCell,empty)),
	FourthCell is FromCell + (Direction *3),
	second_color(Color, Color2),
	retract(cell_value(FourthCell, Color2)),
	assert(cell_value(FourthCell, Color)),
	retract(amount(Color2, Amount)),
	NewAmount is Amount - 1,
	assert(amount(Color2, NewAmount)).

undo_move(push_out3_2, Color, Direction, FromCell, not_exist):-
	member(PushWith3, [push3_2, push3]),
	retract(cell_value(FromCell, empty)),
	assert(cell_value(FromCell,Color)),
	FourthCell is FromCell + (Direction *3), 
	second_color(Color, Color2),
	retract(cell_value(FourthCell, Color)),
	assert(cell_value(FourthCell, Color2)),
	retract(amount(Color2, Amount)),
	NewAmount is Amount + 1,
	assert(amount(Color2, NewAmount)).

cells_for_player(Player, Cells):-
	player(Player, Color),
	findall(cell(Number, Color), cell_value(Number, Color), Cells).


all_moves_for_player((Player, _, _, _, _), Depth, SortedMoves):-
	player(Player, Color),
	NewPlayer is Player* -1,
	findall((NewPlayer, MoveType, Direction, FromCell, ToCell),
	(cell_value(FromCell, Color), 
		can_make_move(MoveType, Color, Direction, FromCell, ToCell)),
		Moves),
	MovesLen is 20,
	sort_moves_with_limit(Moves, SortedMoves, MovesLen).	

sort_moves_with_limit([], [], _):- !.
sort_moves_with_limit(_, [], 0):- !.

sort_moves_with_limit(List, [Elem|SortedListWithout], Limit):- 
	biggest_in_list(Elem, List), !, 
	delete_element_from_list(Elem, List, ListWithout),
	NewLimit is Limit - 1,
	sort_moves_with_limit(ListWithout, SortedListWithout, NewLimit).


biggest_in_list((Player, MoveType, Direction, From, To), List):-
	member((Player, MoveType, Direction, From, To), List),
	rank(MoveType, Rank), 
	not ( member((_, MoveType2, _, _, _), List),  rank(MoveType2, Rank2), Rank2 > Rank). 


delete_element_from_list(Elem, [Elem|Tail], Tail):- !.
delete_element_from_list(Elem, [Elem2|Tail], [Elem2|TailNewList]):- 
	delete_element_from_list(Elem, Tail, TailNewList).


static_val((Player , Type , Cell1 , Cell2) , Val):-
	amount(black, BlackNum),
	amount(white, WhiteNum),
	dist_from_center(black, BlackDist),
	dist_from_center(white, WhiteDist),
	Val is (((BlackNum * 10000) - (WhiteNum * 10000))  - BlackDist + WhiteDist).


% TODO implement
dist_from_center(Color, TotalDist):-
	findall(Distance, 
		(cell_value(Cell, Color), distance_from_center(Cell, Distance)), List),
	sum_list(List, TotalDist).
	
sum_list([], 0):- !.
sum_list([X|Tail], Sum):-
	sum_list(Tail, Sum1), Sum is Sum1 + X.

distance_from_center(Cell, Dist):-
	get_xy(Cell, X, Y),
	distance(X, Y, 4, 4, Dist).

get_xy(CellNumber, X, Y):-
	Y is (CellNumber -1) // 11,
	Offset is ((Y - 6) // 2), 
	X is (CellNumber - 1 + Offset) mod 11.
	
distance(X,Y, X2, Y2, Dist):-
	Temp is ((Y - Y2) * (Y - Y2) + (X - X2) * (X - X2)),
	Dist is sqrt(Temp).
	

game_flow(Player):-
	amount(white, Amount1), Amount1 > 8,
	amount(black, Amount2), Amount2 > 8,
	level(Depth),
	alpha_beta((Player, _, _, _, _), Depth, -999999, 999999, NewState, Val),
	write(NewState).
	
max_to_move((1 ,_, _ , _ , _) ).
min_to_move( (-1 , _,_ , _ , _) ).

alpha_beta(State, MaxDepth, Alpha, Beta, GoodState, Val):-
    all_moves_for_player(State, MaxDepth, StateList), MaxDepth > 0, !,
    bounded_best(StateList, MaxDepth, Alpha, Beta, GoodState, Val);
    static_val(State, Val).
 
bounded_best([State|StateList], MaxDepth, Alpha, Beta, GoodState, GoodVal) :-
    NewMaxDepth is MaxDepth - 1,
    make_move(State),
    alpha_beta(State, NewMaxDepth, Alpha, Beta, _, Val),
    undo_move(State),
    good_enough(StateList, Alpha, Beta, State, Val, GoodState, GoodVal, MaxDepth).

make_move((Player, MoveType, Direction, From, To)):-
	player(Player, Color),
	second_color(Color, FirstColor),
	make_move(MoveType,FirstColor, Direction, From, To).  

undo_move((Player, MoveType, Direction, From, To)):-
	player(Player, Color),
	second_color(Color, FirstColor),
	undo_move(MoveType,FirstColor, Direction, From, To).  

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

new_bounds(Alpha, Beta, _, _, Alpha, Beta).

better_of(State, Val, _, Val1, State, Val) :-
    min_to_move(State), Val > Val1, !;
    max_to_move(State), Val < Val1, !.
better_of(_, _, State1, Val1, State1, Val1).


	