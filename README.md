# Gustavo's blog

The blog is a [Hugo](https://gohugo.io) static website, served as static files from an ASP.NET Core web app, hosted in Azure as an [App Service](https://azure.microsoft.com/en-us/products/app-service/web), and written by me.

# How this shit works
Inside of `src/static` is the Hugo website files.
Blog content naturally lives inside of `content`.
Templates live inside of `archetypes`.

When the C# project builds, Hugo runs and dumps its output to the `wwwroot` folder so that everything is served as a [static file](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/static-files?view=aspnetcore-7.0) by ASP.NET. 

To run the blog, run `hugo -d ../wwwroot -w` from the `static` directory