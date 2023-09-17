---
title: Silent-Lang | Array Design
date: 2023-09-15 22:54:44
tags:
- PL
- Silent-Lang
- Technical
- Selected
---

I want arrays in [silent-lang](https://github.com/5eqn/silent-lang) to be as intuitive as possible, this is what happened to my design.

## Array creation

```
let n = input
let initedArray = [0 rep n]
let uninitedArray = [rep n]
let fixedArray = [2, 3, 4]
```

Uninited array begins with random values, they should be treated as non-accessible.

The `rep` keyword (stands for "repeat") is for avoiding ambiguity between value multiplication, while keeping a semantically-clear syntax.

## Array indexing

Same as C, just:

```
let arr = [2, 3, 4]
let _ = print(arr[0])
```

`0` means the first element.

## Array modification

```
let n = input
let arr, x, y = [input rep n], input, input
  upd arr[x <- arr[y], y <- arr[x]], x, y
```

Please note that an instance of array is affine, meaning that:

- After being referenced as a whole (not indexing), it can no longer be used
- Being referenced is not mandatory

For example, this is illegal:

```
let n = input
let arr, x, y = [input rep n], input, input
  upd arr[x <- arr[y]][y <- arr[x]], x, y
```

Reason: after calculating `arr[x <- arr[y]]`, `arr` is no longer referenceable. Please always remember that `let` is *associating a name with contents of specific memory address*, not manipulating memory directly, which is the duty of referencing.

## Array length

I would probably use a struct to represent an array:

```c
struct array {
  int length;
  int *ptr;
}
```

This way, you can refer to the length (capacity) of an array with:

```
let arr = [1, 2, 3]
let _ = print(len(arr)) // 3
```

Just like Golang.

## Array typing

I'd like to add dependently-typed arrays afterwards, but for now I'll just make a simple one:

```
let f = (1 arr: int[]) => arr[0 <- 5]
let _ = print(f([2, 3, 4])[0]) // 5
```

Just like C.

## Not supported

### Array slicing

Slicing might seem convenient, but it coexists with concatenation, which violates the philosophy of silent-lang: view mutations as *silent* functions from state to state, not how to dynamically construct the result. It also introduces great challenge when linear-checking.

### Dynamic-lengthed Array

Once finishing structs in silent-lang, dynamic-lengthed array can be implemented *inside* silent-lang. I want the core language to contain as few features as possible.
