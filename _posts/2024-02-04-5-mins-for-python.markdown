---
layout: post
title:  "5-minutes to Python packaging"
date:   2024-02-04 08:34:23 -0400
categories: python, tools
---

Collection of trivial Python package ecosystem tidbits.

# Whath is the module resolution process?
[See here](https://docs.python.org/3/tutorial/modules.html#the-module-search-path).

# What are `site-packages`?
One of the module resolution locations is a `site-packages` directory.
If you don't use a venv, this is basically a global install location for packages on your system.

# How can I find where a package is on disk?
Modules have a `__path__` property with their location on disk:
```
❯ python
Python 3.11.7 (main, Dec  4 2023, 18:10:11) [Clang 15.0.0 (clang-1500.1.0.2.5)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>> import requests
>>> requests.__path__
['/Users/gustavo/code/ghidalgo3.github.io/.venv/lib/python3.11/site-packages/requests']
```
In this case, I am using a `venv` so `site-packages` is local and NOT the sytem python on macOS.

# What is an `__init__.py`?

This file is implicitly executed when a module package is imported for the first time.

# How do I build a Wheel?
Have a "frontend" like [build](https://pypi.org/project/build/) and run it on your `pyproject.toml` file.
For example, run `python -m build` in the directory where a `pyproject.toml` file exists to build a wheel, many other CLI arguments available.

# I'm a repo with several python packages, how do I express a dependency between them without having to build wheels?
More context, I'm used to the .NET model where repos contain several projects, MSBuild understands `ProjectReferences` and building at the top-level understands the topology of the project graph. 
At work, we have repos like [PCTasks](https://github.com/microsoft/planetary-computer-tasks) that contain several python projects and my understanding is that Python doesn't "understand" this dependency "graph".
In that, modifying source code in the same repo doesn't necessarilly mean that it will affect what you want it to affect.

UPDATE: This works the way I want it to work. The trick is to:
1. Use a venv in the repo
1. Install packages as _editable installs_ with `pip install -e`

I confirmed that's actually what happens in the [install](https://github.com/microsoft/planetary-computer-tasks/blob/main/scripts/install) script of planetary-computer-tasks.

# How do I get deterministic `pip installs`?
Use [pip-tools](https://pypi.org/project/pip-tools/) and compile a `requirements.txt`.

# References

1. [Importing regular/module packages](https://docs.python.org/3/reference/import.html#regular-packages)
1. [Editable installations](https://setuptools.pypa.io/en/latest/userguide/development_mode.html)