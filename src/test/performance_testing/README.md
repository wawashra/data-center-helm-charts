# K8s DCAPT Atlassian DC environments
Helm manifest's and values files to stand up each Atlassian DC product for [DCAPT](https://developer.atlassian.com/platform/marketplace/dc-apps-performance-toolkit-user-guide-jira/) testing.

## Prerequisites
1. Ensure that the EFS/EBS CSI drivers are installed in the K8s cluster
2. Deploy Ingress controller and certificate issuer using the instructions [here](https://github.com/atlassian-labs/data-center-helm-charts/blob/master/docs/examples/ingress/INGRESS_NGINX.md)
2. Provide local storage to each product by provisioning the [local-storage](local-storage/dynamic-storage.yaml) `StorageClass` into K8s test cluster. Ensure that each products's `values.yam` is updated to make use of this `StorageClass`.
```yaml
localHome:
    persistentVolumeClaim:     
      create: true
      storageClassName: "local-home"
      resources:
        requests:
          storage: 200Gi
```