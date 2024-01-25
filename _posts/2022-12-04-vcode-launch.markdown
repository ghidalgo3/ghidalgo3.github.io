---
layout: post
title:  "Slightly complex VSCode launch configurations"
date:   2022-12-04 12:34:23 -0400
categories: tools
draft: true
---

VSCode supports starting and *debugging* processes through its launch configuration system, largely configured with the `tasks.json` and `launch.json` editor configuration files.
Launch configurations control what happens, and in what order, when you press F5 and the green play button in the debug pane.
As a project grows in scope and in team members, I have learned that it is easier to tell other developers "just press F5 and everything will just work" rather than asking them to read README files.

Multiple times now I've found myself in situations with complex launch configurations because the process being debugged depends on an external service like a database, an external application in a container, or a browser connected to the editor.
VSCode launch configurations can support starting all of our process dependencies, here I will describe how I've done it in a few different situtations.

# 1 process + 1 debugger
The easiest case to handle is when pressing F5 does the following:
1. Builds the code
2. Start exactly **one** process with a supported [debug adapter](https://microsoft.github.io/debug-adapter-protocol/)

Your `task.json` will look like this:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "build",
      "command": "dotnet",
      "type": "process",
      "args": [..],
      "problemMatcher": "$msCompile"
    }
  ]
}
```
Where `command` is the CLI tool that builds your project, something like `make`, `maven`, `dotnet`, `cargo`, etc.... 

Then in your `launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "App",
      "type": "coreclr",
      "request": "launch",
      "preLaunchTask": "build",
      "program": "${workspaceFolder}/bin/Debug/net6.0/Blog.dll",
      "args": [],
      "cwd": "${workspaceFolder}",
      "stopAtEntry": false,
    }
  ]
}
```

Note that the value of `preLaunchTask` is the `label` property of the task previously defined.
This tells VSCode to run the `build` task whenever the `App` launch configuration is invoked, which makes sense because you need to build your code before you can run it.

The final bit of magic is the `type` property of the launch configuration which tells VSCode how to debug the process that's about to be launched.
Language extensions usually provide a debug adapter which defines a value for `type`.

{{<mermaid>}}
sequenceDiagram
  actor User
  participant L as launch.json
  participant T as tasks.json

  User->>L: Debug process
  activate L
  L->>T: Build executable
  activate T
  T-->>L: Build finished
  deactivate T
  L-->>User: Launch debugger
  deactivate L
{{</mermaid>}}

That's the simplest scenario I can think of: 1 build, 1 process, 1 debug session.
Let's get more complex!

# 2 processes + 1 debugger
As I write this blog, I have two processes running: 
1. An ASP.NET Core process mostly serving static files 
1. A Hugo process watching for file changes and rebuilding the static assets

To make this work, I will need to define 2 tasks:
1. One that builds the C# code
1. One that starts the Hugo server file watcher

And then I will make a launch configuration that depends on the two tasks and launches the debugger on the C# code. 

Here's the tricky part: the C# build task _terminates_ but the Hugo server task _does not terminate_.
For VSCode, this creates the need to inform the editor if a task is a so-called "background" task that never terminates and what the error messages of this task look like as a regular expression.
The editor could not otherwise determine if the debugger should launch when there is a problem with the background task.
The .NET Core extension conveniently handles this with a `problemMatcher` of type `$msCompile`, but it's common and easy to define our own problem matchers.

Let's take a closer look at the Hugo server output.
I launch the Hugo server with this command: `hugo -d ../wwwroot -w`.
The initial output of this program looks like this:
```
~/code/ghidalgo3.github.io/static ~/code/ghidalgo3.github.io
Start building sites … 
hugo v0.102.3+extended darwin/amd64 BuildDate=unknown

                   | EN  
-------------------+-----
  Pages            | 25  
  Paginator pages  |  0  
  Non-page files   |  0  
  Static files     |  1  
  Processed images |  0  
  Aliases          |  1  
  Sitemaps         |  1  
  Cleaned          |  0  

Watching for changes in /Users/gustavo/code/ghidalgo3.github.io/static/{archetypes,content,themes}
Press Ctrl+C to stop
Watching for config changes in /Users/gustavo/code/ghidalgo3.github.io/static/config.toml, /Users/gustavo/code/ghidalgo3.github.io/static/themes/ananke/config.yaml
```

This is an example of output with no errors.
Then when I edit a file, I see this output:

```
Change detected, rebuilding site.
2022-12-22 13:12:29.779 -0500
Source changed "/Users/gustavo/code/ghidalgo3.github.io/static/content/posts/2022-12-04-vcode-launch.markdown": WRITE
Total in 6 ms
```
Again, no errors.

If Hugo had run into an error, it would produce output like this:
```
Change detected, rebuilding site.
2022-12-26 18:18:43.725 -0500
Source changed "/Users/gustavo/code/ghidalgo3.github.io/static/content/posts/2022-12-04-vcode-launch.markdown": WRITE
ERROR 2022/12/26 18:18:43 Rebuild failed: "/Users/gustavo/code/ghidalgo3.github.io/static/content/posts/2022-12-04-vcode-launch.markdown:123:1": failed to extract shortcode: template for shortcode "fweiuf" not found
Total in 2 ms
```

The line that starts with `ERROR` indicates that the task failed and it helpfully contains a filename, line number, and column number indicating the failure.
Let's see how we can create a task that starts the Hugo server, detects errors, and surfaces them for us:

```json
{
  "label": "Hugo watch",
  "command": "hugo",
  "type": "process",
  "args": [ "-d", "../wwwroot", "-w" ],
  "options": {
    "cwd": "${workspaceFolder}/static"
  },
  "isBackground": true,
  "problemMatcher": {
    "owner": "hugo",
    "fileLocation": "absolute",
    "pattern":[
      {
        "regexp": "ERROR.*\"(.+):(\\d+):(\\d+).*\": (.+)",
        "file": 1,
        "line": 2,
        "column": 3,
        "message": 4,
      }
    ],
    "background": {
      "activeOnStart": true,
      "beginsPattern": "Start building sites",
      "endsPattern": "Watching for config changes in"
    }
  }
}
```


# Starting and debugging multiple processes.
In web applications, the database is usually a separate process from 
Database start scripts fall into two categories: those that terminate and those that don't.
Examples of the ones that do:
1. `systemd` start service calls
1. `SysV` init scripts
1. `Windows Service` service start calls

Examples of the ones that don't:
1. `azurite`

## Launch

# Conclusion

# References
1. https://code.visualstudio.com/docs/editor/debugging