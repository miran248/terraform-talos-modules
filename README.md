# terraform-talos-modules
This repository contains a collection of opinionated terraform modules for running [talos](https://www.talos.dev) on [hetzner](https://www.hetzner.com).

## modules
1. [network-layout](modules/network-layout) manages global cidrs and private ips
2. [network-zone](modules/network-zone) manages regional / zonal cidrs and private ips
3. [node-pool](modules/node-pool) manages control planes and workers
4. [talos-config](modules/talos-config) manages talos configs for all machines
5. [hcloud](modules/hcloud) manages hcloud networks, servers, load balancers, firewalls, routers
6. [talos-apply](modules/talos-apply) bootstraps cluster and applies configs to running machines

## examples
See [examples](examples) folder.

## overview
The following [mermaid](https://github.com/mermaid-js/mermaid) flowchart outlines the order of operations between different modules for a cluster, spanning two different regions.

```mermaid
%%{init: {'theme': 'neutral' } }%%
flowchart TD
    network-layout --> network-zone-nuremberg(hetzner nuremberg region)
    network-layout --> network-zone-falkenstein(hetzner falkenstein region)
    network-zone-nuremberg --> network-zone-nuremberg-1
    network-zone-nuremberg --> network-zone-nuremberg-3
    network-zone-nuremberg --> network-zone-nuremberg-2
    network-zone-falkenstein --> network-zone-falkenstein-1
    network-zone-falkenstein --> network-zone-falkenstein-2
    network-zone-falkenstein --> network-zone-falkenstein-3
    network-zone-nuremberg-1[network-zone 1] --> node-pool-nuremberg-1
    network-zone-nuremberg-2[network-zone 2] --> node-pool-nuremberg-2
    network-zone-nuremberg-3[network-zone 3] --> node-pool-nuremberg-3
    network-zone-falkenstein-1[network-zone 1] --> node-pool-falkenstein-1
    network-zone-falkenstein-2[network-zone 2] --> node-pool-falkenstein-2
    network-zone-falkenstein-3[network-zone 3] --> node-pool-falkenstein-3
    node-pool-nuremberg-1[node-pool 1] --> talos-config
    node-pool-nuremberg-2[node-pool 2] --> talos-config
    node-pool-nuremberg-3[node-pool 3] --> talos-config
    node-pool-falkenstein-1[node-pool 1] --> talos-config
    node-pool-falkenstein-2[node-pool 2] --> talos-config
    node-pool-falkenstein-3[node-pool 3] --> talos-config
    talos-config --> hcloud-nuremberg(hetzner nuremberg region)
    talos-config --> hcloud-falkenstein(hetzner falkenstein region)
    hcloud-nuremberg --> hcloud-nuremberg-1
    hcloud-nuremberg --> hcloud-nuremberg-2
    hcloud-nuremberg --> hcloud-nuremberg-3
    hcloud-falkenstein --> hcloud-falkenstein-1
    hcloud-falkenstein --> hcloud-falkenstein-2
    hcloud-falkenstein --> hcloud-falkenstein-3
    hcloud-nuremberg-1[hcloud 1] --> talos-apply
    hcloud-nuremberg-2[hcloud 2] --> talos-apply
    hcloud-nuremberg-3[hcloud 3] --> talos-apply
    hcloud-falkenstein-1[hcloud 1] --> talos-apply
    hcloud-falkenstein-2[hcloud 2] --> talos-apply
    hcloud-falkenstein-3[hcloud 3] --> talos-apply
```

..each zone contains
- one network with multiple subnets
- one or more control planes and workers, all without public interface
- one load balancer, handling all incoming requests via ipv4
- one router (with a firewall and optional test client), giving servers access to the internet via ipv4
