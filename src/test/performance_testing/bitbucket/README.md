# BB Test infrastructure

> NOTE: Ensure the pre-requisite infrastructure is available and ready
> * RDS instance 
> * EBS volume
> * ELK stack

1. Deploy the NFS server by using the manifests in the [nfs](nfs) directory
2. Test NFS by using the [busybox](busybox) server
3. Deploy Bitbucket using [values.yaml](values.yaml)

> NOTE: Make sure to update the `sharedHome.persistentVolume.nfs.server` IP address with the IP address of the provisioned NFS
> pod in step 1. above.
