# Examples

Provide realistic, copyable compositions using documented public module interfaces and pinned release references. Keep credentials and generated clients out of source control; update examples with breaking or meaningful interface changes.

Keep direct routing aligned with IPv6-only KubeSpan endpoints, `fc00:1::/96` PodCIDR routing, destination-scoped table-`180` rules, KubeSpan/route MTU 1420, and Cilium MTU 1400. Verify with `terraform fmt -check` here.
