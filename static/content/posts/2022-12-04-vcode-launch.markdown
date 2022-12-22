---
layout: post
title:  "Visual Studio Code launch configurations"
date:   2022-12-04 12:34:23 -0400
categories: tools
---

VSCode supports starting and debugging processes through its launch configuration system.
Launch configurations control what happens when you press F5, and for simple scenarios there are several templates that get the job done.
Multiple times now I've found myself in situations where pressing F5 fails because the process being debugged depends on an external service like a database or an application in a container.
It's trivial to start a database service, but the lost time and focus from such a failure usually derails my motivation.
VSCode launch configurations can support starting all of our process dependencies, here I will describe how to do it in a few different scenarios.

{{<mermaid>}}
graph TD;
  A-->B;
  A-->C;
  B-->D;
  C-->D;
{{</mermaid>}}

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