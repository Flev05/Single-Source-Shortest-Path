# Prolog Implementation

This directory contains the SWI-Prolog implementation of Dijkstra's Single Source Shortest Path (SSSP) algorithm.

## Implementation Details

### Infinity Handling (inf)

To represent infinite distance during graph initialization, we use the special atom `inf`, which is natively supported by SWI-Prolog arithmetic according to IEEE 754 standard.

### MinHeap Representation

The heap is implemented using Prolog's dynamic knowledge base with the fact:
```
heap_entry(HeapID, Position, Key, Value)
```

Parent-child relationships:
- Left Child: `2 * Position`
- Right Child: `2 * Position + 1`
- Parent: `Position // 2`

### Lazy Initialization

The `previous/3` predicate is only asserted when a valid path is discovered, keeping the knowledge base clean.

## Usage

```bash
swipl sssp.pl
```

```prolog
?- [sssp].
?- new_graph(g1).
?- new_arc(g1, a, b, 4).
?- new_arc(g1, b, c, 2).
?- dijkstra_sssp(g1, a).
?- shortest_path(g1, a, c, Path).
```
