# K8s DCAPT Atlassian DC environments
Helm manifest's and values files to stand up each Atlassian DC product for [DCAPT](https://developer.atlassian.com/platform/marketplace/dc-apps-performance-toolkit-user-guide-jira/) testing.

## Prerequisites
* Provide local storage to each product by provisioning the [local-storage](local-storage/dynamic-storage.yaml) `StorageClass` into K8s test cluster. Ensure that each products's `values.yam` is updated to make use of this `StorageClass`.
```yaml
localHome:
    persistentVolumeClaim:     
      create: true
      storageClassName: "local-home"
      resources:
        requests:
          storage: 200Gi
```