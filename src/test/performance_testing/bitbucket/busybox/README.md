# NFS test utils
A busybox RC that can be used for testing and debugging the NFS infrastructure found in the [nfs](../nfs) directory. Useful for kicking the tyres before deploying a full blown Atlassian product. Ensure the accompanying PV and PVC are provisioned before the busybox i.e. `nfs-pv.yaml`
and `nfs-pvc.yaml`