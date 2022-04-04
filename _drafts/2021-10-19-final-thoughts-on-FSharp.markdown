---
layout: post
title:  "Final thoughts on F#"
date:   2021-10-19 12:34:23 -0400
categories: f#
---

# Introduction
F# is a primarily functional language for the .NET ecosystem.
It is the functional cousin of C# and contains many features that slowly make their way into C# as developers demand more functional programming features out of C#.

I admit to being seduced by the lure of functional programming several times, and with each rehabilitation I find myself wondering "was it worth it?".
In this post I will argue to myself:

1. What are the roadblocks to start using F#?
1. Does F# make borings parts of C# better?
1. Where does F# fall short of C#?
1. What _exactly_ is the interoperability story between F# and C#?
1. What are the tooling gaps for F#?
1. Is F# is worth it? What does that even mean?

This isn't a purely academic exercise, I did write a few thousand lines of F# for a personal project so I'd consider myself intermediately proficient writing F#.

# What are the roadblocks to start using F#?
The answer depends on whether you're using Visual Studio / .NET Framework or .NET Core.
I will not consider Mono or other CLR implementations or IDEs, they are out-of-scope.

If you are using Visual Studio [the IDE], you need to install F# components through the Visual Studio Installer.
The F# component instalation instructions are [easy](https://docs.microsoft.com/en-us/dotnet/fsharp/get-started/install-fsharp#install-f-with-visual-studio), but if you are part of a team and you want to push F# usage then you need to remember to:
1. Make it easy for your teammates to install F# workloads through [.vsconfig](https://devblogs.microsoft.com/setup/configure-visual-studio-across-your-organization-with-vsconfig/) files.
1. Install these workloads on your builders in your CI/CD pipeline.
With the workloads installed, you can create an .fsproj in Visual Studio and you're good to go.

If you are not using Visual Studio [the IDE], and instead you use Visual Studio Code with .NET Core, you don't have to do anything extra to get the F# building in the command-line because the F# compiler and MSBuild props/targets ship with .NET Core, but you will need an [extension](https://github.com/ionide/ionide-vscode-fsharp) for VSCode to get a language server running.
You can then create an fsproj with `dotnet new classlib --language F#`

In either case, your fsproj is just another MSBuild project that can take dependencies on other projects (C# or F#), or be a dependency itself of other projects (C# or F#).
From a purely technical standpoint, putting F# into use is easy.

# Does F# make boring parts of C# better?
What exactly are the boring parts of C#? These are my opinions:

## POCOs
Plain-old-CLR-objects are useful in many situations, here is an idiomatic example with C# 8:
```c#
public class Person
{
	public string Name { get; set; }
	public int Age { get; set; }
}
var person = new Person()
{
	Name = "Dennis",
	Age = 25
}
```
C# 9 does include a new `record` keyword that simplifies POCO creation but given that it requires .NET 5 it will take a while for that syntax to see broad adoption.
Let's see the same POCO with idiomatic F#:
```f#
type Person =
	{ Name : string
	  Age : int }
let person =
	{ Name = "Dennis"
	  Age = 25 }
```
There is only a very small benefit to F# in this case.

## 

# Where does F# fall short of C#?

# What _exactly_ is the interoperability story between F# and C#?

# What are the tooling gaps for F#?

# Is F# is worth it? What does that even mean?

# Conclusion