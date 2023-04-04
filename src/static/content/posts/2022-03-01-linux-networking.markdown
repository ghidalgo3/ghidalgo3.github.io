---
layout: post
title:  "Linux Networking Reference"
date:   2022-03-02 12:34:23 -0400
categories: tools
draft: true
---

# Contents
* TOC
{:toc}

# Introduction
I have spent the last 2 years working on Azure products that relied heavily on different networking features of various Linux distributions. 
I found myself really struggling trying to understand how to connect the "what" and "why" book knowledge of compute networking with the "how" of the Linux networking stack.
Initially I just blamed my ignorance of Linux tools, but soon my opinion changed from blame to empathy for me and for all other developers who, like me, have read a book or two but have not spent much time hands-on-keyboard trying to configure a network.
If you're reading this, I assume that you know _something_ about computer networking but not enough to call yourself a network engineer.
I'm not going to explain what Ethernet is, what IP is, TCP/UDP, HTTP, routing protocols, etc...
I am going to write about the _tools_ available to manipulate the networking system of Linux so that you can reference _how_ to do something.
Along the way, I try to explain the history and trajectory of the network system to motivate why things are the way they are.

# Glossary of linux networking tools, concepts, words you should recognize
1. `iproute2` : A collection of userspace utilities for interacting with the kernel networking system.
1. `ip(8)` : One of the the tools included in the `iproute2` collection. Knowing `ip(8)` will allow you do to like 80% of everything you will ever want to do with kernel networking.
1. `tcpdump(1)` : A command-line packet capture tool.
1. `libpcap` : The library that `tcpdump` and Wireshark depend on.
1. `netlink` : The communication protocol between userspace and the kernel for networking configuration. Prior to netlink, `ioctl(2)` was often used to communicate with the kernel, and I guess creating many dedicated system calls for the networking subsystem was undesirable.
1. `iptables`: One of the kernel IP filtering and processing modules. `iptables` was superceded by `nftables`, if someone is telling to you to use `iptables` kindly tell them to go read about `nftables` and then use `nftables`.
1. `NAPI` : "New API" a kernel networking enhancement that, among other things, reduces kernel interrupt load during periods of high network utilization.  
1. `netfilter` : The FOSS project behind `iptables` and `nftables`.
1. `nftables`: A newer IP filtering and processing module. You can use `nftables` to do very cool packet rewriting, routing, and forwarding things. `nftables` CLI tool is `nft`.
1. `DPDK` : DataPlane Development Kit. One of several kernel bypass technologies that allow userspace to control a NIC for higher performance. This is outside the scope of this article, but you should know what it means.

# What can you do with `ip(8)`
#### Address Resolution Protocol (ARP)
[RFC 826](https://datatracker.ietf.org/doc/html/rfc826)

ARP is the protocol used to discover the physical addresses for IP addresses on the local network.
A host builds an ARP table as it learns the physical addresses of other hosts on the network.
You can interpret that to mean that an entry in the ARP table is in the same layer-2 broadcast domain as the host you are on.

You can examine your ARP table like this:
```
gustavo@ubuntu:~$ ip neighbor
192.168.1.236 dev ens33 lladdr ac:e2:d3:88:a0:61 STALE
192.168.1.254 dev ens33 lladdr 38:a0:67:5a:f1:22 REACHABLE
```


#### View and modify your routing table
You can inspect your routing table with `ip route`:
```
gustavo@ubuntu:~$ ip route
default via 192.168.1.254 dev ens33 proto dhcp metric 100 
169.254.0.0/16 dev ens33 scope link metric 1000 
192.168.1.0/24 dev ens33 proto kernel scope link src 192.168.1.192 metric 100
```

You might think the display order is significant, but it's not.
The _most specific_ route is always chosen, most commonly decided by the longest matching prefix of the address being routed to.

If you don't believe it, you can evaluate what route is chosen for a given address using `ip route get`:
```
gustavo@ubuntu:~$ ip route get 8.8.8.8
8.8.8.8 via 172.20.10.1 dev ens33 src 172.20.10.5 uid 1000
```
This means that traffic to `8.8.8.8` will be forwarded to `172.20.10.1` using device `ens33` with source address `172.20.10.5`.
I'm not sure yet why there is a `uid` associated with this route.

#### View and modify your interfaces
You can use `ip link` to view all the interfaces on your system:
```
ustavo@ubuntu:~$ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 00:0c:29:70:61:d6 brd ff:ff:ff:ff:ff:ff
    altname enp2s1
5: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/none
```
Normally you will see at least 2 interfaces: your `lo` interface for loopback traffic on `127.0.0.1` (or `::1` for IPv6!)

# What can you do with `tcpdump`
There are a few arguments you will always want to pass to tcpdump for a more sane experience:
1. `sudo` : Obviously, you need to be root to capture packets on an interface, lest we tag packets with `uid`s.
1. `-n` : This disables reverse DNS lookups which sometimes blocks `tcpdump`. I don't know why the authors of `tcpdump` thought it a good idea to enable this by default :(
1. `-i` : This selects the interface you want to snoop on. If you don't specify this, `tcpdump` kinda just selects an interface which is usually _okay_ but on systems with multiple interfaces it's definitely not desirable.
1. `-v` : Does a protocol decode. Not strictly required but I usually add this to avoid having to repro the capture because I didn't see the information I was looking for.

For a full explanation of the `expression` argument, you can run `man pcap-filter`.

## Capture 

# What can you do with `nftables`

# Network managers
What are these?

## Special mention to `systemd`

# Network namespaces (Docker)

# Single-root IO Virtualization
What is this, what does it mean for me?

# Scenarios
## Metering (Measurement and Throttling)
## Policy Routing
## Firewalling
## NATing

# FAQ

## If there is an `iproute2`, was there an `iproute`? Why the 2?
Who knows?

## Why are interfaces sometimes named `ethN` and sometimes `ens33` or something like that?
SystemD ? https://systemd.io/PREDICTABLE_INTERFACE_NAMES/
## Some IP address ranges keep being used over and over, why?
Refer to https://www.ietf.org/rfc/rfc3330.txt for all the special blocks,   but notably:
`169.254.0.0/16` : Link-local addresses
`10.0.0.0/8` : Private address space
`172.16.0.0/16`  : Private address space
`192.168.0.0/16` : Private address space
`100.64.0.0/10` : CGNAT address space, https://datatracker.ietf.org/doc/html/rfc6598

# References
iptables https://linux.die.net/man/8/iptables
iproute2 https://wiki.linuxfoundation.org/networking/iproute2
Arch Wiki https://wiki.archlinux.org/title/Network_configuration
tcpdump https://www.tcpdump.org 
numbers next to commands https://superuser.com/questions/297702/what-do-the-parentheses-and-number-after-a-unix-command-or-c-function-mean
NAPI : https://www.usenix.org/legacy/publications/library/proceedings/als01/full_papers/jamal/jamal.pdf
Netfilter https://www.netfilter.org
Policy Routing Book: http://www.policyrouting.org/PolicyRoutingBook/ONLINE/TOC.html