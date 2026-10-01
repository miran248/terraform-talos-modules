mock_provider "talos" {}

variables {
  cluster = {
    MODULE_NAME        = "talos-cluster"
    name               = "endpoint-regression"
    endpoint           = "2001:db8::ffff"
    cluster_endpoint   = "https://[2001:db8::ffff]:6443"
    talos_version      = "v1.15.0-alpha.0"
    kubernetes_version = "v1.36.1"
    machine_secrets = {
      client_configuration = {
        ca_certificate     = "test"
        client_certificate = "test"
        client_key         = "test"
      }
      machine_secrets = {
        cluster = { id = "test", secret = "test" }
        certs = merge(
          { for name in ["etcd", "k8s", "k8s_aggregator", "os"] : name => { cert = "test", key = "test" } },
          { k8s_serviceaccount = { key = "test" } },
        )
        secrets    = { bootstrap_token = "test", secretbox_encryption_secret = "test" }
        trustdinfo = { token = "test" }
      }
    }
    nodes = {
      cp1 = { aliases = ["c1"], patches = [], talos = { machine_type = "controlplane" } }
      cp2 = { aliases = ["c2"], patches = [], talos = { machine_type = "controlplane" } }
      w1  = { aliases = ["w1"], patches = [], talos = { machine_type = "worker" } }
    }
  }
  applies = [{
    nodes = {
      cp1 = { kind = "control-plane", ip = "2001:db8::1" }
      cp2 = { kind = "control-plane", ip = "2001:db8::2" }
      w1  = { kind = "worker", ip = "2001:db8::3" }
    }
  }]
}

run "machine_operations_bypass_shared_endpoint" {
  command = plan

  assert {
    condition = alltrue([
      for key, machine in talos_machine.control_planes :
      machine.endpoint == var.applies[0].nodes[key].ip && machine.node == var.applies[0].nodes[key].ip
    ])
    error_message = "Control-plane maintenance requests must reach the intended machine directly, never the load balancer."
  }

  assert {
    condition = alltrue([
      for key, machine in talos_machine.workers :
      machine.endpoint == var.applies[0].nodes[key].ip && machine.node == var.applies[0].nodes[key].ip
    ])
    error_message = "Worker maintenance requests must reach the intended machine directly, never a control-plane endpoint."
  }

  assert {
    condition     = talos_cluster.this.endpoint == var.cluster.endpoint
    error_message = "Cluster operations must retain the shared endpoint."
  }
}
