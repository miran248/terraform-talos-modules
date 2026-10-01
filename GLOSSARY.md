# Talos cluster provisioning

This project describes and maintains Talos-based Kubernetes clusters whose nodes may span cloud providers and locations.

## Language

### Cluster membership

**Cluster**:
A Kubernetes cluster running on Talos, with a shared control plane and a set of participating nodes. One cluster may contain multiple node pools across providers and locations.
_Avoid_: Pool when referring to the whole cluster.

**Node pool**:
A group of node definitions associated with one cloud provider, one provider location or zone, and one node address family. A pool may contain both control-plane nodes and worker nodes.
_Avoid_: Cluster, worker pool when referring to a pool that includes control-plane nodes.

**Node**:
A Talos machine defined as a member of a cluster, with either a control-plane or worker role. A node definition can exist before its cloud server has been provisioned.
_Avoid_: Server when referring to cluster membership rather than the hosting resource.

**Cloud server**:
The provider-managed compute instance that hosts a node.
_Avoid_: Node when referring specifically to the provider resource.

**Control-plane node**:
A node with the cluster's control-plane role; several such nodes can belong to the same control plane.
_Avoid_: Master, a control plane when referring to an individual node.

**Worker node**:
A node assigned the worker role rather than the control-plane role.
_Avoid_: Worker pool when referring to an individual node.

### Configuration and lifecycle

**Talos fork**:
This project's maintained variant of upstream Talos, used to develop and test changes, including features not yet released upstream.
_Avoid_: Custom image when referring to the source variant rather than an artifact built from it.

**Provider image**:
A bootable Talos image registered with a cloud provider for provisioning cloud servers.
_Avoid_: Custom image when referring specifically to the provider's provisioning artifact.

**Talos installer image**:
A container image containing the Talos version installed on a node during installation or upgrade.
_Avoid_: Custom image when referring specifically to the installation or upgrade artifact.

**Machine configuration**:
The desired Talos configuration for an individual node, including its cluster membership and role.
_Avoid_: Client configuration, which configures access to the cluster rather than the node itself.

**Configuration patch**:
A scoped adjustment to a node's desired machine configuration. Its scope can cover a cluster, a pool, a node role, or an individual node.
_Avoid_: Upgrade when referring only to a configuration adjustment.

**Server provisioning**:
The creation of cloud servers and their supporting cloud resources to host the defined nodes.
_Avoid_: Bootstrap when referring to cloud resource creation.

**Cluster bootstrap**:
The initial establishment of a cluster's control plane on its provisioned nodes.
_Avoid_: Server provisioning, configuration update, upgrade.

### Connectivity

**Node address family**:
The single IPv4 or IPv6 family selected for cluster node connectivity, shared by all pools in a cluster. In IPv6 mode, incidental provider-assigned IPv4 addresses are outside the intended cluster connectivity.
_Avoid_: Dual-stack cluster merely because a host also has an address from the other family.

**Cluster endpoint**:
The shared access address for the cluster's APIs, rather than the address of an arbitrary member node. Qualify it as the Kubernetes API endpoint or Talos API endpoint when the particular API matters.
_Avoid_: Node address when referring to the shared cluster access address.
