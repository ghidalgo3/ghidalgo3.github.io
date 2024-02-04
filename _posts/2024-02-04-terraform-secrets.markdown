---
layout: post
title:  "Terraform, please don't be dumb"
date:   2024-02-04 08:34:23 -0400
categories: terraform, aks, tools
---
[Cache invalidation](https://martinfowler.com/bliki/TwoHardThings.html) is one of the hardest things to solve in computer science.
Cloud DevOps is also really hard.
Why terraform decided that you needed to cache cloud provider state is beyond me.

In their words:
> Terraform must store state about your managed infrastructure and configuration. This state is used by Terraform to map real world resources to your configuration, keep track of metadata, and to improve performance for large infrastructures.

Must it?
1. Tracking real-world resources: Your cloud provider is already tracking all your resources buddy, that is how they bill you.
1. Tracking metadata: I assume they mean things like resource properties. This one is tricky in Azure because of [Azure's REST Guidelines](https://github.com/microsoft/api-guidelines/blob/vNext/azure/Guidelines.md#api-versioning). If you use [Azure Resource Templates or Bicep files](https://learn.microsoft.com/en-us/azure/azure-resource-manager/) you are always keenly aware of exactly what properties you are setting in your resource because 1) you must declare an exact `api-version` and 2) the property name matches exactly what the REST API says with no translations to lower_case_underscores. So the problem then becomes: when Terraform creates or updates a resource you don't know exactly what API version the provider used and therefore you don't know exactly what request was sent to Azure and therefore you don't know exactly what your resource actually looks like. This only makes cloud DevOps harder than it needs to be IMO. 
1. Improve performance: Yea maybe, if Terraform's error messages and error recovery were good then I wouldn't have a problem with this one. However when Terraform can't delete a resource because it can't figure out the dependencies between things because it's "intelligently" trying to delete things in reverse topological order, then I really don't care about performance.

# Is that it?
NO! The Azure Terraform provider also stores secrets in its lock file.
It looks like a bearer token, not sure why it does this.
Thankfully GitHub alerted me that I had commited a secret [here](https://github.com/ghidalgo3/ghidalgo3.github.io/commit/d4405e4b50df522dc30ddb534ccba352eee51f5a#diff-af426e3f6e243f3640b78016eeb13738ba1d41e53dc1f46e08bc240308cbccb4) and I immediately went to delete the resources the secrets reference. 

HashiCorp tries to prevent this by asking you to use [remote state](https://developer.hashicorp.com/terraform/language/state/remote) which is just a stepping stone to upselling you to [Terraform Cloud](https://www.hashicorp.com/products/terraform).
Following the classic tactic of selling you a tool that creates a problem that only they have a solution for, I'll keep thinking Terraform is over-engineered.

# Lessons Learned
Deeply review your commit before you push them.
If you don't trust yourself or your team, [use technology](https://microsoft.github.io/code-with-engineering-playbook/continuous-integration/dev-sec-ops/secret-management/recipes/detect-secrets/).

# References
1. [Terraform State](https://developer.hashicorp.com/terraform/language/state)
1. [Should I commit .tfstate files?](https://stackoverflow.com/questions/38486335/should-i-commit-tfstate-files-to-git)

