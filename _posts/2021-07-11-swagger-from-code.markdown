---
layout: post
title:  "Swagger from C# code"
date:   2021-07-11 12:34:23 -0400
categories: c#
---

# Problem
At work we write a lot of ASP.NET REST controllers.
Some of the controllers have their API documented in the [Azure REST API] specs in the form of a [Swagger] specification, and some are consumed internally by a system that requires us to expose a Swagger specification. This is our problem: say we want to write a controller for `Widget`s that supports CRUD operations. A developer has to:
1. Write the C# code.
2. Write the Swagger JSON necessary.
3. Ensure (erm, try really hard) to make sure the swagger and the C# stay consistent with each other. 
4. Ship the Swagger to the clients.

There are existing tools like [NSwag] and [Swashbuckle] that are almost tailor made for this but they assume you're going to generate perfectly legal OpenAPIv2/3 documents, which I'm not because this internal swagger has some... _customizations_. We can easily adapt a proper Swagger document into our custom format, ultimately we are trying to generate a swagger document at build time from our source code which we will then transform some more (again, at build time!).

# Solution
Thankfully NSwag has a component that does almost exactly what we need: [NSwag.MSBuild]. With this package, we can generate a Swagger document for some or all of the controllers in an assembly, and then we can modify the document to fit our custom Swagger format. Let's see how it works:

First I generate a small project with:
```sh
> dotnet new webapi
```
At this time, this template contains one controller with a GET method on `/WeatherForecast` that returns an object with weather forecast data.

Then I add a dependency on NSwag with

```sh
> dotnet add package NSwag.AspNetCore
> dotnet add package NSwag.MSBuild 
```

This is my `Startup.cs` with the call to `AddSwaggerDocument`, this is **necessary** for the generator to discover controllers in the assembly:
```csharp
public class Startup
{
    public Startup(IConfiguration configuration)
    {
        Configuration = configuration;
    }

    public IConfiguration Configuration { get; }

    public void ConfigureServices(IServiceCollection services)
    {
        services.AddControllers();
        services.AddSwaggerDocument();
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        if (env.IsDevelopment())
        {
            app.UseDeveloperExceptionPage();
        }
        app.UseHttpsRedirection();
        app.UseRouting();
        app.UseAuthorization();
        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllers();
        });
    }
}
```
And finally I add a target in the project file to call the Swagger generator executable. Note that I am on a Mac so I have to call the generator with the property for .NET 5.

```xml
<Target Name="NSwag" AfterTargets="Build">
    <Exec 
    EnvironmentVariables="ASPNETCORE_ENVIRONMENT=Development"
    Command="$(NSwagExe_Net50) aspnetcore2openapi /assembly:$(TargetDir)$(MSBuildProjectName).dll /output:swagger.json" />
</Target>
```

Some nice build output:
```
Microsoft (R) Build Engine version 16.8.0+126527ff1 for .NET
Copyright (C) Microsoft Corporation. All rights reserved.

  Determining projects to restore...
  All projects are up-to-date for restore.
  swaggergen -> /Users/gustavo/code/swaggergen/bin/Debug/net5.0/swaggergen.dll
  NSwag command line tool for .NET Core Net50, toolchain v13.11.3.0 (NJsonSchema v10.4.4.0 (Newtonsoft.Json v12.0.0.0))
  Visit http://NSwag.org for more information.
  NSwag bin directory: /Users/gustavo/.nuget/packages/nswag.msbuild/13.11.3/tools/Net50
  Code has been successfully written to file.
  
  Duration: 00:00:00.8377024

Build succeeded.
    0 Warning(s)
    0 Error(s)

Time Elapsed 00:00:03.55
```

And finally, a `swagger.json` file is produced next to our project file. 
Let's take a look at it:

```json
{
  "x-generator": "NSwag v13.11.3.0 (NJsonSchema v10.4.4.0 (Newtonsoft.Json v12.0.0.0))",
  "swagger": "2.0",
  "info": {
    "title": "My Title",
    "version": "1.0.0"
  },
  "produces": [
    "text/plain",
    "application/json",
    "text/json"
  ],
  "paths": {
    "/WeatherForecast": {
      "get": {
        "tags": [
          "WeatherForecast"
        ],
        "operationId": "WeatherForecast_Get",
        "responses": {
          "200": {
            "x-nullable": false,
            "description": "",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/WeatherForecast"
              }
            }
          }
        }
      }
    }
  },
  "definitions": {
    "WeatherForecast": {
      "type": "object",
      "required": [
        "date",
        "temperatureC",
        "temperatureF"
      ],
      "properties": {
        "date": {
          "type": "string",
          "format": "date-time"
        },
        "temperatureC": {
          "type": "integer",
          "format": "int32"
        },
        "temperatureF": {
          "type": "integer",
          "format": "int32"
        },
        "summary": {
          "type": "string"
        }
      }
    }
  }
}
```
Pretty good! The generator:
1. Found the controller in the assembly.
1. Generated an object in `paths` for each controller method.
1. Generated definitions for the objects the controller returns.

For a very simple controller, that Swagger document is a whopping 141 lines long!
I will grant that it is a full Swagger document with all of the ceremony of Swagger, but still even if it was only 70 lines that would be a huge change to review.
If the author tells me "The swagger is automatically generated from the code", then I'll spend exactly 0 seconds looking at it and instead focus on reviewing the code that produced it.

# Conclusion

Generating Swagger files from C# code is extremely easy with NSwag.
Armed with these tools, you can reduce the amount of time you spend toiling at the Swagger mines.

[Azure REST API]: https://github.com/Azure/azure-rest-api-specs
[swagger]: https://swagger.io/specification/v2/
[NSwag]: https://github.com/RicoSuter/NSwag
[Swashbuckle]: https://github.com/domaindrivendev/Swashbuckle.AspNetCore
[NSwag.MSBuild]: https://github.com/RicoSuter/NSwag/wiki/NSwag.MSBuild