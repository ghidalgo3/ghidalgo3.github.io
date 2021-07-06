---
layout: post
title:  "Rust Day 1"
date:   2021-06-27 12:34:23 -0400
categories: rust
---

I'm learning Rust to get my systems programing muscle back into shape after living in C# land for a few years.
C# is a very nice language and the tooling ecosystem around it is wonderful, but all the serious systems programming is happening in C/C++ and now Rust.
I will try to document my baby steps into Rust for myself and for anyone else that wants to learn Rust after having programmed in C# for a while.

# Installing Rust
It's 2021, you can't just install a compiler and go write some code; you need a tool that installs other tools.
For Rust that tool is `rustup` and it is installed through a shell script downloaded from the official [Rust website](https://www.rust-lang.org/learn/get-started).
I ran `rustup install stable` on my Mac and got some very nice logs as my Rust tools were updated.
Once you've acquired `rustup`, can you then use `cargo` which is really the equivalent of the `dotnet` CLI command for .NET Core.

Running `cargo [init|new]` is the equivalent to `dotnet new`, and it creates a new Rust "project".
The project file ends in a `.toml` extension and contains build settings and other metadata.

I'd give the tooling tooling a 10/10 compared to other tooling tooling I've had to work with.

# Strings

After the introductory hello world, I wanted to do some more complex string maniplations.
Using my C# brain, I wrote the following:

```rust
fn main() {
    let name = "Gustavo";
    let greeting = get_greeting(name);
    println!("{}", greeting);
}
fn get_greeting(name : String) -> String {
     return format!("Hello {}", name);
}
```
When I ran `cargo build`, I got this error:
```
--> src/main.rs:3:33
  |
3 |     let greeting = get_greeting(name);
  |                                 ^^^^
  |                                 |
  |                                 expected struct `String`, found `&str`
  |                                 help: try using a conversion method: `name.to_string()`
```
Ok, we're not in C# land anymore! Double quoted string literals in Rust are not `String` types, but instead `&str`. 
The & in Rust is similar to the "address of" operator from C which means that string literals are references/pointers to `str` objects. I changed `String` to `&str` in my `get_greetings` function, and then got this error:

```
-> src/main.rs:8:13
  |
8 |      return format!("Hello {}", name);
  |             ^^^^^^^^^^^^^^^^^^^^^^^^^ expected `&str`, found struct `String`
  |
```

`format!` produces a `String`, got it Mr. Compiler I will go appease you.
Changing the return value of the function from `&str` to `String` makes it compile and run.

So what is the difference then between `str`, `&str`, and `String`? First let's name these types:
1. `str` is a _string slice_, which is like a C-style `char[]`. 
1. `&str` is a _reference_ to a string slice.
1. `std::string::String` is a struct that represents a re-sizable sequence of UTF-8 characters.

C#'s `System.String` are immutable sequences of characters and since they are classes they are (almost always) heap allocated and passed by value (reference) between methods.
The closest type Rust has to a `System.String` is `&str` _not_ `std::string::String`.
`std::string::String` is closer to a `System.Text.StringBuilder`,

One more thing, `String` is implicitly convertible to `&str` so for most string manipulation functions it is better to accept `&str` than `String`.

# Conclusion
I don't know if it was a deliberate choice of the Rust designers to make the semantics of `String` different from C# strings or Java strings, but it certainly tripped me up at the beginning.
Once I understood the difference between the 3 common string types, I now know what to use in most of my basic string programs.