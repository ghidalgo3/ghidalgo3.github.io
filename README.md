# Gustavo's blog

The blog is a [Hugo](https://gohugo.io) static website, served as static files from an ASP.NET Core web app, hosted in Azure as an [App Service](https://azure.microsoft.com/en-us/products/app-service/web), and written by me.

# How it works
Inside of `src/static` is the Hugo website files.
Blog content naturally lives inside of `content`.
Templates live inside of `archetypes`.

When the C# project builds, Hugo runs and dumps its output to the `wwwroot` folder so that everything is served as a [static file](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/static-files?view=aspnetcore-7.0) by ASP.NET. 
## Writing a new post
Create a new file inside of the `content` folder.
[How to make it a draft](https://gohugo.io/getting-started/usage/#draft-future-and-expired-content).

## Running locally
To run the blog, run `hugo -d ../wwwroot -w` from the `static` directory
Presing F5 also seems to work.

# How to release
Use the VSCode web app deployment feature, this should build and deploy the webapp.