---
layout: post
title:  "Can't avoid Kubernetes anymore"
date:   2024-01-25 12:34:23 -0400
categories: kubernetes, tools
---

Time comes for us all, and this time it came for me.
I can't avoid learning Kubernetes anymore so here we go!!!

# Fake News
Kubernetes is so great and fast moving that all of the old documentation for it is now deprecated.
I was reading a book that talked about [ReplicationControllers](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/) but if you click on that link you see that [_actually ReplicaSets are the recommended way of doing this_](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/). I get it, software changes, I'm not mad about that.
I'm mad that I wasn't told ahead of time to check the publish date and ignore anything that's 3+ years old 🤣.

# Pick a cloud, any cloud
You want to run a local kubernetes cluster? 
I hope you don't mind jank because [minikube](https://minikube.sigs.k8s.io/docs/start/) and [kind](https://kind.sigs.k8s.io) are janky. For starters, you can't just `docker build` an image and [expect a local kind cluster to use it](https://iximiuz.com/en/posts/kubernetes-kind-load-docker-image/).
Writing this made me look up that there are [8 ways to do this](https://minikube.sigs.k8s.io/docs/handbook/pushing/#1-pushing-directly-to-the-in-cluster-docker-daemon-docker-env) 🤣.

The minikube team failed here.
By default minikube should look for images built by the local docker host and if it can't find any images then it should look for them in remote container registries.
Of course if you had _just_ pushed an image to docker hub or GCP or Azure or AWS or whatever then you would be perfect!
How dare I assume that I should be able to use the computer I already paid for and not a cloud service...

Fine, I'll play your game Kubernetes. Let's get cloudy.

# I have to have my tools
I installed:
1. [Docker Desktop](https://www.docker.com/products/docker-desktop/): To build Docker images
1. [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli): To interact with the Azure control plane and authenticate.
1. [kubectl](https://kubernetes.io/docs/tasks/tools/): To interact with the k8s control plane.
1. [Terraform](https://developer.hashicorp.com/terraform/install): This is what we use at work and I need to get good at it.
1. [Helm](https://helm.sh/docs/intro/install/): We use this at work so I need to get good at it.
1. [k9s](https://k9scli.io): This is a basically a GUI frontend for `kubectl`. It is not necessary but it makes inspecting clusters a little more fun.

OK enough tooling, let's create a cluster!

## What's in a cluster?
A k8s cluster is a set of machines (k8s calls them _nodes_) running applications (losely defined, a _pod_ is an instance of an application) managed by control plane processes which are usually running in dedicated controller nodes and communicate with "agents" that are running on worker node.

In the following image, we see a cluster with 2 nodes, and a control plane node.
![k8s](https://kubernetes.io/images/docs/kubernetes-cluster-architecture.svg)

When you run `kubectl` to administer your cluster, you are making requests to `kube-api-server` in the control plane.
`kube-api-server` does some validation on your request and stores it in `etcd`, a kind of simple distributed database for your control plane nodes.
Then the control plane and the kubelets (agents) running on the nodes coordinate to instantiate the right kind and number of pods that the cluster should be running.

# Terraforming it up
Since we're in Azure land, let's write a terraform file to deploy an [Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/) cluster.
Basically an AKS cluster is a [VM Scale Set](https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/overview) with the `kubelet` and `kube-proxy` agents configured to talk to a central kubernetes control plane run by the AKS service.
You "own" the worker nodes and Azure "owns" the the control plane nodes.
The documentation puts it like this:

> When you create an AKS cluster, a control plane is automatically created and configured. This control plane is provided at no cost as a managed Azure resource abstracted from the user. You only pay for and manage the nodes attached to the AKS cluster.

Ok let's write this file:

```
```

## Errors
What happens when you get this error?
```
Code="ServiceCidrOverlapExistingSubnetsCidr" Message="The specified service CIDR 10.0.0.0/16 is conflicted with an existing subnet CIDR 10.0.1.0/24" Target="networkProfile.serviceCIDR"
```

[This helpful troubleshooting page](https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/error-code-servicecidroverlapexistingsubnetscidr) doesn't actually address the problem, but here's what I understand: there are 2 address spaces at play here, Azure's and Kubernetes'.
They cannot overlap because otherwise `kube-proxy` [could not configure unambiguous routing rules between pods](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network).
By default (and the error message tells us this but I can't find this actually documented anywhere within Microsoft's documenation), AKS clusters take 10.0.0.0/16.
Not exactly true, I did find it mentioned on [this page](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay?tabs=kubectl#deploy-a-dual-stack-aks-cluster) talking about dual-stack IPv4/6 deployments.
Anyway, I want my virtual network to use 10.0.0.0/16 so AKS needs to bend-the-knee to [RFC1918](https://datatracker.ietf.org/doc/html/rfc1918) with this `network_profile`:

```terraform
network_profile {
    network_plugin = "azure"
    dns_service_ip = "192.168.255.254"
    service_cidrs = [ "192.168.0.0/16" ]
}
```

Here are some more constraints on these address spaces [you oughta know](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay?tabs=kubectl#ip-address-planning).

Sidebar about [this page](https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/error-code-servicecidroverlapexistingsubnetscidr), when your customers encounter this problem the first solution shouldn't be to go and delete the virtual network.
If someone is deploying nodes into a virtual network they are doing that on purpose.
Don't ask them to go delete it and start over, the first solution should have been explaining how to change the cluster service CIDR range.

# Conclusion
Ok that's enough for one day, I now have an AKS cluster with one VM up and running.
Next time I'll actually deploy an application to it an explore the world of `kubectl`, `helm`, and Ingress controllers.


# References
1. [etcd](https://etcd.io)
1. [Kubernetes source code](https://github.com/kubernetes/kubernetes/)
1. [Who talks to whom?](https://www.reddit.com/r/kubernetes/comments/10n7a9t/how_does_control_plane_kubelet_communication_work/)
1. [kube-proxy source code](https://github.com/kubernetes/kubernetes/tree/master/staging/src/k8s.io/kube-proxy)

