---
layout: post
title:  "My C# project structure"
date:   2023-06-30 12:34:23 -0400
categories: C#
# draft: 
---

Writing C# code involves using `msbuild` as the build system that resolves dependencies, orders projects topologically, compiles your codes, gathers your output files, creates publishable artifacts, etc.
I learned to author `msbuild` project files quite well at Microsoft, and I got a few opinions out of it.
In this post, I will summarize the best practices I have learned working with `msbuild` for C# development since 2016.

# Vocabulary
Words are important, especially with a build system. In one sentence:
> `msbuild` builds _projects_ by sequencing _targets_ which execute _tasks_ with _properties_ and _item groups_ as inputs.

Each word deserves a good definition:
1. Project: The XML file that `msbuild` reads and builds. 
1. Target: A named _step_ in a build. Targets only sequence build actions, they are not the actions themselves.
1. Task: The "functions" that `msbuild` calls during the build. Tasks can be built-in to `msbuild`, code that is evaluated at build time, or calls to arbitrary process.
1. Property: Simple named values that influence the build. All properties are strings ultimately.
1. Item Groups: Named collections of items, often files but not necessarily.

A good example is walking through what happens when you build a C# project. 
Every file of source code is put into the `Compile` item group.
The `Build` target eventually calls the `Csc` task (that's the C# compiler task) and passed every file as an argument to the task.
The property `Configuration` is also passed to the `Csc` task to control release and debug builds.

# Calling MSBuild
If you use Visual Studio, you need to use the `msbuild.exe` that ships with the version of Visual Studio you are using.
If you don't match `msbuild.exe` versions with Visual Studio versions, undefined things will happen when someone or something else tries to build the project on a different machine.
To guarantee this, you need to use the Developer Command Prompt (or Developer PowerShell) for the version of Visual Studio you use.
Calling that program will put the right `msbuild.exe` on your `PATH`, along with a host of other Visual Studio tools..

If you use the `dotnet` CLI, `msbuild` is implicitly invoked when you call `dotnet build`, but you can unleash the beast by calling `dotnet msbuild` instead. 
That command will call the appropriate version of `msbuild` that ships with the .NET SDK version you are using and forward any command line arguments to `msbuild`.

Do one of those two and you should not have any issues.

# Controlling .NET SDK versions
It is important to ensure that developer machines and CI/CD machines all use the same version of the .NET SDK.
That can be controlled by using a `global.json` file.
The full documentation for `global.json` [can be found here](https://learn.microsoft.com/en-us/dotnet/core/tools/global-json), but basically I always roll with something like this:

```json
{
  "sdk": {
    "version": "7.0.102",
    "rollForward": "latestFeature"
  }
}
```
# Put common build settings in a `Directory.Build.props`
Since `msbuild` operates on XML files, you can re-use build settings by `Import`-ing XML files [like this](https://learn.microsoft.com/en-us/visualstudio/msbuild/import-element-msbuild?view=vs-2022).
For along time, this was the only way to organize and re-use build configuration.
In newer versions of `msbuild`, a project's build will search the file system for a file named `Directory.Build.props` and automatically _import_ that file before building the project.
This means that properties and item groups defined this file will be available to any project that needs to know about them.

The full documentation [can be found here](https://learn.microsoft.com/en-us/visualstudio/msbuild/customize-your-build?view=vs-2022), but this is what I roll with:
```xml
<Project>
  <PropertyGroup>
    <Platform Condition=" '$(Platform)' == '' ">x64</Platform>
    <Configuration Condition=" '$(DOTNET_WATCH)' == '1' ">Debug</Configuration>
    <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
    <TreatWarningsAsErrors Condition=" '$(Configuration)' == 'Release' ">true</TreatWarningsAsErrors>
  </PropertyGroup>
</Project>
```
Here's [another good](https://github.com/ClosedXML/ClosedXML/blob/develop/Directory.Build.props) `Directory.Build.props` that I like to reference.

# Put common build targets and tasks in a `Directory.Build.targets`
The sister file to `Directory.Build.props` should define target definitions or redefinitions because it is imported _after_ a project is evaluated.
It is highly likely that you will never need write a custom targets.
With any luck you will never need to understand why or actually write a `Directory.Build.targets`, but in case you do please [read through this](https://learn.microsoft.com/en-us/visualstudio/msbuild/customize-your-build?view=vs-2022#choose-between-adding-properties-to-a-props-or-targets-file), familiarize yourself with the `/pp` command-line flag to `msbuild` and use your favorite text editor to examine massive XML files :).

Here is an example one I had to write last year:
```xml
<Project>
<!-- 
    [REDACTED] uses packages.config instead of PackageReference and they have
    static relative paths in their project files to their assembly references.
    Since we cannot modify their project files, we will tell MSBuild to rewrite
    the HintPath attribute at build time!
-->
  <UsingTask
    TaskName="PackageFolderRedirect"
    TaskFactory="CodeTaskFactory"
    AssemblyFile="$(MSBuildToolsPath)\Microsoft.Build.Tasks.Core.dll" >
    <ParameterGroup>
      <References ParameterType="Microsoft.Build.Framework.ITaskItem[]" Required="true"/>
    </ParameterGroup>
    <Task>
      <Using Namespace="System"/>
      <Using Namespace="System.IO"/>
      <Code Type="Fragment" Language="cs">
<![CDATA[
if (References.Length > 0)
{
  for (int i = 0; i < References.Length; i++)
  {
    ITaskItem item = References[i];
    string path = item.GetMetadata("HintPath");
    if (!string.IsNullOrWhiteSpace(path) && !File.Exists(path))
    {
      string newPath = "..\\" + path;
      Log.LogMessage(MessageImportance.High, "Redirecting HintPath to " + newPath);
      References[i].SetMetadata("HintPath", newPath);
    }
    else
    {
      Log.LogMessage(MessageImportance.Low, "Valid HintPath");
    }
  }
}
]]>
      </Code>
    </Task>
  </UsingTask>

  <Target
    Name="FixHintPath"
    Condition="Exists('$(MSBuildProjectDirectory)/packages.config') == 'true'"
    BeforeTargets="ResolveAssemblyReferences" >
    <PackageFolderRedirect References="@(Reference)" />
  </Target>

</Project>
```

# Why and When to create a new project
Code organization and architecture are imporant things all software engineers should think about.
I've seen code bases where well-intentioned developers used `msbuild` projects to structure code, and this can be problematic if taken too far.
For example, the first team I joined essentially shipped code out of one repo to 4 locations:

1. The backend code.
1. The client code.
1. The integration/unit tests.
1. CLI tools.

This means there were at 4 `msbuild` projects (one for each deployment target) and at least 1 "common" project that housed the shared code.
This N + 1 arrangement is the _simplest_ possible architecture for projects, that is N projects that control deployment specific settings and 1 common library that produces a library assembly.
There is the case where you have no shared assemblies, then you only have one project.

In reality, that team had at least 20 intermediate projects forming their own little internal dependency graph within the repo.
There are many downsides to this including:

1. Long build times if you modify foundational projects.
1. High chance for an intermediate project to introduce some form of [dependency hell](https://en.wikipedia.org/wiki/Dependency_hell).
1. Bloating build output sizes because each intermediate project will copy its assembly and all of its dependencies to its build output. This redundant file copying is often the _primary_ cause for long build times, especially on Window's NTFS.

# Conclusion
That's it for now, I'll come back here and update these as I collect more nuggets of best practices.