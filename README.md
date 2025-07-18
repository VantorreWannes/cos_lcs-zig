# zig-cos

This repository contains a Zig implementation of a greedy algorithm for finding the longest common subsequence.

## `CosLcsIterator`

The core of this repository is the `CosLcsIterator` found in `src/cos.zig`. This iterator takes two byte slices (`source` and `target`) and iteratively finds the next common item.

The algorithm is greedy: at each step, it finds the pair of matching items with the minimum sum of their indices in the remaining slices and returns that item. This process continues until no more matches can be found.

## Testing

You can run the tests for the `CosLcsIterator` using the following command:
```sh
zig build test
```

## Benchmarking

A benchmark suite is included to test the performance of the `CosLcsIterator`. You can run it with:

```sh
zig build bench
```
