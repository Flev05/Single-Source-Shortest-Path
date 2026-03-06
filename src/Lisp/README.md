# Common Lisp Implementation

This directory contains the Common Lisp implementation of Dijkstra's Single Source Shortest Path (SSSP) algorithm using hash tables to simulate a knowledge base.

## Implementation Details

### Knowledge Base (Hash Tables)

Global hash tables with composite list keys:
- `*vertices*` - stores vertices as `(list 'vertex graph-id vertex-id)`
- `*arcs*` - stores arcs as `(list 'arc graph-id u v weight)`
- `*graphs*` - stores graph identifiers
- `*distances*`, `*visited*`, `*previous*` - SSSP state
- `*heaps*` - MinHeap storage

### Infinity Handling

Uses `most-positive-single-float` to represent infinity in arithmetic operations.

### MinHeap

Implemented on dynamic arrays with automatic resizing (capacity doubles when full).

## Usage

```bash
sbcl --script sssp.lisp
```

Or in REPL:
```lisp
(load "sssp.lisp")
(new-graph 'g1)
(new-arc 'g1 'a 'b 4)
(new-arc 'g1 'b 'c 2)
(sssp-dijkstra 'g1 'a)
(sssp-shortest-path 'g1 'a 'c)
```
