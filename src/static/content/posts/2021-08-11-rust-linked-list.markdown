---
layout: post
title:  "Rust Day 2: Linked Lists"
date:   2021-08-11 12:34:23 -0400
categories: rust
---

Today I was inspired to continue learning Rust by implementing what every CS student eventually has to know backwards and forwards to get a job: a singly linked list.
This shouldn't be too hard, my list will support:
1. Appending elements to the list one at a time
1. Iterating over elements
1. Determining the length of the list by iterating from head to tail
1. Deallocating the list
1. Using Rust modules (just to learn how they work)

Every linked list needs a good recursive `linked_list_node` definition with a nice `car` and `cdr` erm I mean `value` and `next`:
```rust
struct LinkedListNode<'a, T> {
    value : T,
    next : &'a LinkedListNode<'a, T>,
}
```
It's obvious to me why `next` has to be a reference to a `LinkedListNode`, but the lifetime parameter `'a` requires some explaining. That will be explained later.
Now obviously we need to support creating an empty list and adding elements to it one at a time.
```rust
pub struct List<'a, T> {
    head : &LinkedListNode<'a, T>
}
impl List {
    fn new() {
        // except Rust doesn't have a null!
        List { head : null }
    }
}
```

Now here is where I ran into my first C#-induced headache, because I would have loved to use `null` to represent a the end of a list.
Rust has no nulls, and some Googling immediately pointed me toward using an `Option` and a [great book](https://rust-unofficial.github.io/too-many-lists/first-layout.html) doing exactly what I'm trying to do!
In short, we can use Rust `enum`s to create a [tagged union](https://en.wikipedia.org/wiki/Tagged_union)(or what F# would call a discriminated union) to define a type that can be one of several values (one of which is Null or Nil) and whose values can themselves be more complex types.
Something like this:
```rust
enum ListNode {
    Empty,
    ListNode(i32, Box<ListNode>)
}
```
I read that like this: A `ListNode` is either the `ListNode::Empty` value, or it is a `ListNode(i32, Box<ListNode>)` which is an `i32` paired with a pointer to a heap-allocated `ListNode`.
# Conclusion
I wouldn't say that starting to write this post was a waste of time because I discovered a great book to read through.
Sometimes starting and failing still results in a victory.
