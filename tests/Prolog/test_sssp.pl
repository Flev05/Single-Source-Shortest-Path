:- use_module(library(plunit)).

%% Helper predicate to clean all dynamic state between tests.
cleanup :-
    retractall(graph(_)),
    retractall(vertex(_, _)),
    retractall(arc(_, _, _, _)),
    retractall(heap(_, _)),
    retractall(heap_entry(_, _, _, _)),
    retractall(distance(_, _, _)),
    retractall(visited(_, _)),
    retractall(previous(_, _, _)).


:- begin_tests(graph_interface).

test(new_graph_creates_graph) :-
    cleanup,
    new_graph(test),
    graph(test).

test(new_graph_idempotent) :-
    cleanup,
    new_graph(test),
    new_graph(test),
    findall(G, graph(G), Gs),
    length(Gs, 1).

test(new_vertex_creates_vertex) :-
    cleanup,
    new_graph(g1),
    new_vertex(g1, v1),
    vertex(g1, v1).

test(new_vertex_idempotent) :-
    cleanup,
    new_graph(g1),
    new_vertex(g1, v1),
    new_vertex(g1, v1),
    findall(V, vertex(g1, V), Vs),
    length(Vs, 1).

test(new_arc_creates_arc) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, a, b, 5),
    arc(g1, a, b, 5).

test(new_arc_creates_vertices) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, a, b, 5),
    vertex(g1, a),
    vertex(g1, b).

test(new_arc_default_weight) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, a, b),
    arc(g1, a, b, 1).

test(new_arc_updates_existing_arc) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, a, b, 5),
    new_arc(g1, a, b, 10),
    arc(g1, a, b, 10),
    \+ arc(g1, a, b, 5).

test(vertices_returns_all_vertices) :-
    cleanup,
    new_graph(g1),
    new_vertex(g1, a),
    new_vertex(g1, b),
    new_vertex(g1, c),
    vertices(g1, Vs),
    sort(Vs, Sorted),
    Sorted = [a, b, c].

test(arcs_returns_all_arcs) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, a, b, 1),
    new_arc(g1, b, c, 2),
    arcs(g1, Es),
    length(Es, 2).

test(neighbors_returns_outgoing_arcs) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, a, b, 1),
    new_arc(g1, a, c, 2),
    new_arc(g1, b, c, 3),
    neighbors(g1, a, Ns),
    length(Ns, 2).

test(delete_graph_removes_graph) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, a, b, 5),
    delete_graph(g1),
    \+ graph(g1),
    \+ vertex(g1, _),
    \+ arc(g1, _, _, _).

:- end_tests(graph_interface).


:- begin_tests(heap_operations).

test(new_heap_creates_heap) :-
    cleanup,
    new_heap(test_heap),
    heap(test_heap, 0).

test(insert_increases_size) :-
    cleanup,
    new_heap(test_heap),
    insert(test_heap, 5, v1),
    heap_size(test_heap, 1).

test(head_returns_minimum) :-
    cleanup,
    new_heap(test_heap),
    insert(test_heap, 10, v1),
    insert(test_heap, 5, v2),
    head(test_heap, K, V),
    K = 5,
    V = v2.

test(extract_returns_minimum) :-
    cleanup,
    new_heap(test_heap),
    insert(test_heap, 10, v1),
    insert(test_heap, 5, v2),
    insert(test_heap, 8, v3),
    extract(test_heap, K, V),
    K = 5,
    V = v2.

test(extract_removes_element) :-
    cleanup,
    new_heap(test_heap),
    insert(test_heap, 5, v1),
    extract(test_heap, _, _),
    heap_size(test_heap, 0).

test(empty_true_for_empty_heap) :-
    cleanup,
    new_heap(test_heap),
    empty(test_heap).

test(empty_false_for_non_empty_heap) :-
    cleanup,
    new_heap(test_heap),
    insert(test_heap, 5, v1),
    \+ empty(test_heap).

test(not_empty_true_for_non_empty_heap) :-
    cleanup,
    new_heap(test_heap),
    insert(test_heap, 5, v1),
    not_empty(test_heap).

test(modify_key_updates_key) :-
    cleanup,
    new_heap(test_heap),
    insert(test_heap, 10, v1),
    modify_key(test_heap, 3, 10, v1),
    head(test_heap, K, v1),
    K = 3.

test(delete_heap_removes_heap) :-
    cleanup,
    new_heap(test_heap),
    insert(test_heap, 5, v1),
    delete_heap(test_heap),
    \+ heap(test_heap, _),
    \+ heap_entry(test_heap, _, _, _).

test(extract_in_sorted_order) :-
    cleanup,
    new_heap(test_heap),
    insert(test_heap, 7, v1),
    insert(test_heap, 3, v2),
    insert(test_heap, 9, v3),
    insert(test_heap, 1, v4),
    insert(test_heap, 5, v5),
    extract(test_heap, K1, _), K1 = 1,
    extract(test_heap, K2, _), K2 = 3,
    extract(test_heap, K3, _), K3 = 5,
    extract(test_heap, K4, _), K4 = 7,
    extract(test_heap, K5, _), K5 = 9.

:- end_tests(heap_operations).


:- begin_tests(dijkstra_sssp).

test(dijkstra_computes_distances) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, s, a, 4),
    new_arc(g1, s, b, 2),
    new_arc(g1, a, b, 1),
    new_arc(g1, a, c, 5),
    new_arc(g1, b, c, 8),
    new_arc(g1, b, d, 10),
    new_arc(g1, c, d, 2),
    dijkstra_sssp(g1, s),
    distance(g1, s, 0),
    distance(g1, a, 4),
    distance(g1, b, 2),
    distance(g1, c, 9),
    distance(g1, d, 11).

test(dijkstra_marks_source_visited) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, s, a, 1),
    dijkstra_sssp(g1, s),
    visited(g1, s).

test(dijkstra_marks_all_reachable_visited) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, s, a, 1),
    new_arc(g1, a, b, 2),
    dijkstra_sssp(g1, s),
    visited(g1, s),
    visited(g1, a),
    visited(g1, b).

test(dijkstra_sets_previous_correctly) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, s, a, 4),
    new_arc(g1, s, b, 2),
    new_arc(g1, a, c, 3),
    new_arc(g1, b, c, 1),
    dijkstra_sssp(g1, s),
    previous(g1, c, b).

test(dijkstra_source_distance_zero) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, s, a, 5),
    dijkstra_sssp(g1, s),
    distance(g1, s, 0).

:- end_tests(dijkstra_sssp).


:- begin_tests(shortest_path).

test(shortest_path_finds_path) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, s, a, 4),
    new_arc(g1, s, b, 2),
    new_arc(g1, a, c, 3),
    new_arc(g1, b, c, 1),
    shortest_path(g1, s, c, Path),
    %% Shortest: s->b(2)->c(1) = 3
    Path = [arc(g1, s, b, 2), arc(g1, b, c, 1)].

test(shortest_path_direct_arc) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, s, t, 5),
    shortest_path(g1, s, t, Path),
    Path = [arc(g1, s, t, 5)].

test(shortest_path_source_equals_target) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, s, a, 1),
    shortest_path(g1, s, s, Path),
    Path = [].

test(shortest_path_multi_hop) :-
    cleanup,
    new_graph(g1),
    new_arc(g1, a, b, 1),
    new_arc(g1, b, c, 2),
    new_arc(g1, c, d, 3),
    shortest_path(g1, a, d, Path),
    Path = [arc(g1, a, b, 1), arc(g1, b, c, 2), arc(g1, c, d, 3)].

:- end_tests(shortest_path).
