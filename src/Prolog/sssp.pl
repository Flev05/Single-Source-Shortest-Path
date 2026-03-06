%% Dynamic knowledge base implementation.
%% Interface
:- dynamic graph/1.
:- dynamic vertex/2.
:- dynamic arc/4.
%% MinHeap
:- dynamic heap/2. 
:- dynamic heap_entry/4.
%% SSSP
:- dynamic distance/3.
:- dynamic visited/2.
:- dynamic previous/3.


%%-------------------------------INTERFACE--------------------------------
%% new_graph/1
%% Creates a new graph G if it does not already exist.
new_graph(G) :- graph(G), !.
new_graph(G) :- assert(graph(G)).


%% delete_graph/1
%% Deletes a graph G if it exists, removing all its vertices and arcs.
delete_graph(G) :- 
    retractall(arc(G, _, _, _)),
    retractall(vertex(G, _)),
    retractall(graph(G)),
    !.


%% new_vertex/2
%% Creates a new vertex V in graph G if it does not already exist.
%% (CL1) If it already exists, do nothing (True).
new_vertex(G, V) :- vertex(G, V), !.
%% (CL2) If it does not exist, create vertex V in graph G.
new_vertex(G, V) :- graph(G), assert(vertex(G, V)).
%% In this implementation, if the graph does not exist 
%% it is not created implicitly.


%% vertices/2
%% Checks if Vs is a list containing all vertices of G.
%% Assumes graph exists and then finds all vertices.
vertices(G, Vs) :- graph(G), findall(V, vertex(G, V), Vs). 


%% list_vertices/1
%% Prints all vertices of a graph.
list_vertices(G) :- graph(G), listing(vertex(G, _)).


%% new_arc/4
%% Creates an arc between U and V with weight Weight.
%% (CL1) If the arc already exists: Updates the weight of arc from U to V to Weight.
new_arc(G, U, V, Weight) :- 
    arc(G, U, V, _),
    number(Weight), Weight >= 0,
    !,
    retractall(arc(G, U, V, _)),
    assert(arc(G, U, V, Weight)).
%% (CL2) If the arc does not exist: Creates a new arc from U to V with weight Weight.
new_arc(G, U, V, Weight) :- 
    graph(G),
    new_vertex(G, U),
    new_vertex(G, V),
    number(Weight), Weight >= 0,
    assert(arc(G, U, V, Weight)).
%% (CL3) If the arc does not exist and weight is not specified:
%% Do new_arc with weight 1.
new_arc(G, U, V) :- new_arc(G, U, V, 1).


%% arcs/2
%% Checks if Es is a list of all arcs present in G.
arcs(G, Es) :- 
    graph(G), 
    findall(arc(G, U, V, Weight), arc(G, U, V, Weight), Es).


%% neighbors/3
%% Checks if V is a vertex of G and Ns 
%% is the list of its neighbors.
neighbors(G, V, Ns) :-
    graph(G),               
    vertex(G, V),           
    findall(arc(G, V, K, Weight), arc(G, V, K, Weight), Ns).


%% list_arcs/1
%% Prints all arcs of a graph.
list_arcs(G) :- listing(arc(G, _, _, _)).


%% list_graph/1
%% Prints all vertices and arcs of a graph.
list_graph(G) :- 
    list_vertices(G), 
    list_arcs(G).


%%--------------------------------MIN_HEAP--------------------------------
%% new_heap/1
%% Creates a new heap H if it does not already exist.
new_heap(H) :- heap(H, _), !.
new_heap(H) :- assert(heap(H, 0)).


%% delete_heap/1
%% Deletes a heap H.
%% (Cl1) Heap exists: Deletes it and also removes heap_entry.
delete_heap(H) :- 
    heap(H, _), !,
    retractall(heap_entry(H, _, _, _)), 
    retract(heap(H, _)).
%% (Cl2) Heap does not exist: Does nothing (True).
delete_heap(_).

%% heap_size/2
%% Checks if S is the size of heap H.
heap_size(H, S) :- heap(H, S).


%% empty/1
%% Checks if heap H is empty.
empty(H) :- heap(H, 0).


%% not_empty/1
%% Checks if heap H is not empty.
not_empty(H) :- 
    heap(H, S), 
    S > 0.


%% head/3
%% K is the key of the minimum value V.
head(H, K, V) :- heap_entry(H, 1, K, V).


%% insert/3
%% Inserts a value into the minHeap.
insert(H, K, V) :-
    heap(H, S),
    NewS is S + 1,
    retract(heap(H, S)),
    assert(heap(H, NewS)),
    assert(heap_entry(H, NewS, K, V)),
    up_heap(H, NewS),
    !.


%% up_heap/2
%% Orders the heap by bubbling up:
%% If the node is smaller than the parent, swap them and continue bubbling up.
%% (CL1) Base case root: Does nothing (True).
up_heap(_, 1).
%% (CL2) Case child >= parent: Does nothing (True).
up_heap(H, P) :-
    P > 1,
    ParentPos is (P) // 2,
    heap_entry(H, P, K_child, _),
    heap_entry(H, ParentPos, K_parent, _),
    K_child >= K_parent.
%% (CL3) Case child < parent: Swap and call up_heap on parent.
up_heap(H, P) :-
    P > 1,
    ParentPos is (P) // 2,
    heap_entry(H, P, K_child, _),
    heap_entry(H, ParentPos, K_parent, _),
    K_child < K_parent,
    swap_entries(H, P, ParentPos),
    up_heap(H, ParentPos), 
    !.


%% swap_entries/3
%% Swaps two nodes in minHeap H.
swap_entries(H, P1, P2) :-
    retract(heap_entry(H, P1, K1, V1)),
    retract(heap_entry(H, P2, K2, V2)),
    assert(heap_entry(H, P1, K2, V2)),
    assert(heap_entry(H, P2, K1, V1)).


%% extract/3
%% Extracts the minimum node from the minHeap;
%% then takes the last element and puts it at the top, then does heapify.
%% (CL1) Case where heap has more than one element:
extract(H, K, V) :-
    heap(H, S),
    S > 1,
    retract(heap_entry(H, 1, K, V)),
    retract(heap_entry(H, S, LastK, LastV)), 
    NewS is S - 1,
    retract(heap(H, S)),
    assert(heap(H, NewS)),
    assert(heap_entry(H, 1, LastK, LastV)),
    heapify(H, 1),
    !.
%% (CL2) Case where heap has only one element:
extract(H, K, V) :-
    heap(H, 1),
    retract(heap_entry(H, 1, K, V)),
    retract(heap(H, 1)),
    assert(heap(H, 0)).
%% If trying to extract from an empty heap, it fails.


%% heapify/2
%% Orders the heap by bubbling down:
%% If the node is larger than one of its children, swap them and continue bubbling down.
%% (CL1) Case where node has no children: Does nothing (True).
heapify(H, P) :- 
    heap(H, S),
    LeftPos is 2 * P,
    LeftPos > S, 
    !.
%% (CL2) Case where node is less than or equal to children: Does nothing (True).
heapify(H, P) :- 
    heap(H, S),
    LeftPos is 2 * P,
    RightPos is 2 * P + 1,
    find_min_child(H, LeftPos, RightPos, S, MinPos),
    heap_entry(H, P, K_parent, _),
    heap_entry(H, MinPos, K_min, _),
    K_parent =< K_min,
    !.
%% (CL3) Case where node is greater than one of its children:
%% Swap with the minimum child and call heapify on the child.
heapify(H, P) :-
    heap(H, S),
    LeftPos is 2 * P,
    RightPos is 2 * P + 1,
    find_min_child(H, LeftPos, RightPos, S, MinPos),
    heap_entry(H, P, K_parent, _),
    heap_entry(H, MinPos, K_min, _),
    K_parent > K_min,
    swap_entries(H, P, MinPos),
    heapify(H, MinPos), 
    !.


%% find_min_child/5
%% Finds the child with minimum key between LeftPos and RightPos.
%% (CL1) Case RightPos does not exist: Minimum child is LeftPos.
find_min_child(H, LeftPos, RightPos, S, MinPos) :-
    heap(H, S),
    RightPos > S,
    MinPos = LeftPos,
    !.
%% (CL2) Case left node <= right node:
%% Minimum child is LeftPos.
find_min_child(H, LeftPos, RightPos, S, MinPos) :-
    heap(H, S),
    heap_entry(H, LeftPos, K_left, _),
    heap_entry(H, RightPos, K_right, _),
    K_left =< K_right,
    MinPos = LeftPos, 
    !.
%% (CL3) Case right node < left node:
%% Minimum child is RightPos.
find_min_child(H, LeftPos, RightPos, S, MinPos) :-
    heap(H, S),
    heap_entry(H, LeftPos, K_left, _),
    heap_entry(H, RightPos, K_right, _),
    K_right < K_left,
    MinPos = RightPos, 
    !.


%% modify_key/4
%% Modifies the key of an element.
modify_key(H, NewKey, OldKey, V) :-
    retract(heap_entry(H, P, OldKey, V)),
    assert(heap_entry(H, P, NewKey, V)),
    up_heap(H, P),
    heapify(H, P),
    !.


%% list_heap/1
%% Prints all elements of heap H.
list_heap(H) :- listing(heap_entry(H, _, _, _)).


%%---------------------------------SSSP--------------------------------
%% change_distance/3
%% Sets or updates the distance of vertex V from the source.
change_distance(G, V, NewDist) :-
    retractall(distance(G, V, _)), 
    assert(distance(G, V, NewDist)).


%% change_previous/3
%% Sets or updates the previous vertex of V.
change_previous(G, V, U) :-
    retractall(previous(G, V, _)),
    assert(previous(G, V, U)).


%% dijkstra_sssp/2
%% Computes the Single Source Shortest Path (SSSP) from vertex S to all
%% other vertices in graph G using Dijkstra's algorithm.
dijkstra_sssp(G, Source) :-
    retractall(distance(G, _, _)),
    retractall(visited(G, _)),
    retractall(previous(G, _, _)),
    delete_heap(G),

    graph(G),
    vertex(G, Source),

    findall(V, vertex(G, V), Vs),
    initialize_graph(G, Vs),
    
    assert(visited(G, Source)),
    change_distance(G, Source, 0),
    new_heap(G),
    populate_heap(G, Source, G),
    scroll_heap(G, G),
    !.


%% initialize_graph/2
%% Initializes the knowledge base for SSSP: sets the distance
%% of all vertices to infinity (-1) and previous vertex to null.
initialize_graph(_, []) :- !.
initialize_graph(G, [H|Rest]) :-
    change_distance(G, H, inf),
    initialize_graph(G, Rest).


%% populate_heap/3
%% Populates heap H with neighbors of State,
%% using the distance traveled to calculate the key for each neighbor.
populate_heap(G, State, H) :-
    distance(G, State, DTraveled),
    neighbors(G, State, Ns),
    scroll_Ns(G, State, DTraveled, Ns, H).


%% scroll_Ns/5
%% Iterates through the list of neighbors Ns of State, for each neighbor V computes
%% the distance traveled to reach it from Source via State, and updates
%% the distance of V if it is better than the current one.
%% Then populates the heap with neighbors of State.
%% (Cl1) Base case empty list: Does nothing (True).
scroll_Ns(_, _, _, [], _) :- !.
%% (Cl2) Case V already visited:
%% Does nothing (True) and continues iterating the list.
scroll_Ns(G, State, DTraveled, [arc(G, State, V, _)|Rest], H) :-
    visited(G, V),
    !,
    scroll_Ns(G, State, DTraveled, Rest, H).
%% (Cl3) Case V not visited: Computes the distance traveled to reach V from
%% Source via State, updates distance of V if better than current
%% and continues iterating the list.
scroll_Ns(G, State, DTraveled, [arc(G, State, V, Weight)|Rest], H) :-
    NewD is DTraveled + Weight,
    update_if_better(G, State, V, NewD, H),
    scroll_Ns(G, State, DTraveled, Rest, H),
    !.


%% update_if_better/5
%% Updates the distance of V if NewD is better than OldD.
update_if_better(G, Previous, V, NewD, H) :-
    distance(G, V, OldD),
    NewD < OldD,
    !,
    change_distance(G, V, NewD),
    update_or_insert(H, OldD, NewD, V),
    change_previous(G, V, Previous).
update_if_better(_, _, _, _, _).



%% update_or_insert/4
%% Updates the key of V in heap H.
%% (CL1) If OldD is inf: Inserts V with key NewD in heap H.
update_or_insert(H, inf, NewD, V) :-
    !,
    insert(H, NewD, V).
%% (CL2) If OldD is different from inf:
%% Modifies the key of V in heap H from OldD to NewD.
update_or_insert(H, OldD, NewD, V) :-
    modify_key(H, NewD, OldD, V).


%% scroll_heap/2
%% Iterates through heap H until it is empty: extracts the node with minimum key,
%% marks the extracted vertex as visited,
%% and populates the heap with neighbors of the extracted vertex.
scroll_heap(_, H) :- empty(H), !.
scroll_heap(G, H) :-
    extract(H, _, V),
    assert(visited(G, V)),
    populate_heap(G, V, H),
    scroll_heap(G, H).


%% shortest_path/4
%% Checks if Path is the list of arcs that constitute the shortest
%% path from Source to Target in graph G.
shortest_path(G, Source, V, Path) :-
    dijkstra_sssp(G, Source),
    distance(G, V, D),
    D \= inf,
    build_path(G, Source, V, [], Path),
    !.


%% build_path/5
%% Builds the list of arcs that constitute the shortest
%% path from Source to Target.
build_path(_, Source, Source, Path, Path) :- !.
build_path(G, Source, V, Build, Path) :-
    previous(G, V, U),
    !,
    arc(G, U, V, Weight),
    build_path(G, Source, U, [arc(G, U, V, Weight)|Build], Path).
