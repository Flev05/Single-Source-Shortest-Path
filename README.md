# Programming Languages Project (2025-2026)

## Single Source Shortest Path

This project implements Dijkstra's Single Source Shortest Path (SSSP) algorithm in two programming languages:
- **Prolog**: `src/Prolog/sssp.pl` (SWI-Prolog implementation)
- **Common Lisp**: `src/Lisp/sssp.lisp` (implementation using hash tables)

## Project Structure

```
Progetto LP/
├── Makefile              # Build and test automation
├── README.md             # This file
├── AGENTS.md             # Guidelines for AI agents
├── .gitignore
├── src/
│   ├── Prolog/
│   │   ├── sssp.pl       # Dijkstra's SSSP in SWI-Prolog
│   │   └── README.md     # Prolog implementation details
│   └── Lisp/
│       ├── sssp.lisp     # Dijkstra's SSSP in Common Lisp
│       └── README.md     # Common Lisp implementation details
└── tests/
    ├── Prolog/
    │   └── test_sssp.pl  # PLUnit tests for Prolog
    └── Lisp/
        └── test_sssp.lisp # Tests for Common Lisp (no external dependencies)
```

## Getting Started

### Requirements

- **Prolog**: [SWI-Prolog](https://www.swi-prolog.org/)
- **Common Lisp**: [SBCL](http://www.sbcl.org/) (or CCL, CLISP)
  - Tests use a built-in lightweight runner (no external dependencies)

### Using Makefile

```bash
make test         # Run all tests
make test-prolog  # Run Prolog tests
make test-lisp    # Run Lisp tests
make run-prolog   # Launch SWI-Prolog REPL
make run-lisp     # Launch SBCL REPL
make clean        # Remove compiled files
```

### Manual Usage

#### Prolog (SWI-Prolog)

Run the program:
```bash
swipl src/Prolog/sssp.pl
```

Load and test:
```prolog
?- [sssp].
?- new_graph(g1).
?- new_arc(g1, a, b, 4).
?- new_arc(g1, b, c, 2).
?- dijkstra_sssp(g1, a).
?- shortest_path(g1, a, c, Path).
```

#### Common Lisp (SBCL)

Run the program:
```bash
sbcl --script src/Lisp/sssp.lisp
```

Or load in REPL:
```lisp
(load "src/Lisp/sssp.lisp")
(new-graph 'g1)
(new-arc 'g1 'a 'b 4)
(new-arc 'g1 'b 'c 2)
(sssp-dijkstra 'g1 'a)
(sssp-shortest-path 'g1 'a 'c)
```

## Testing

### Prolog Tests (PLUnit)

```bash
make test-prolog
```

Or manually:
```prolog
?- [tests/Prolog/test_sssp].
?- run_tests.
```

### Lisp Tests

```bash
make test-lisp
```

The test suite covers:
- Graph interface (new_graph, new_vertex, new_arc, neighbors, etc.)
- Heap operations (insert, extract, modify_key, empty, etc.)
- SSSP algorithm (distances, visited, previous)
- Shortest path reconstruction

## Algorithm Details

### Prolog Implementation
- Uses SWI-Prolog's dynamic knowledge base for graph storage
- MinHeap implemented via dynamic predicates
- Infinity represented using the `inf` atom (IEEE 754 compliant)
- Lazy initialization of `previous` predicate for path reconstruction

### Common Lisp Implementation
- Uses hash tables with composite keys to simulate a knowledge base
- MinHeap implemented on dynamic arrays with automatic resizing
- Infinity represented using `most-positive-single-float`

## License

Academic project for Programming Languages course.
