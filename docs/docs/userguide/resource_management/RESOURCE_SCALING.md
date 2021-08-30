# Product scaling
For optimum performance and stability the appropriate resource `requests` and `limits` should be defined for each pod. The number of pods in the product cluster should also be carefully considered. Kubernetes provides means for horizontal and vertical scaling of the deployed pods within a cluster, these approaches are described below.

## Horizontal scaling - adding pods
The Helm charts provision one `StatefulSet` by default. The number of replicas within this `StatefulSet` can be altered either declaratively or imperatively. Note that the Ingress must support cookie-based session affinity in order for the products to work correctly in a multi-node configuration.


=== "Declaratively"
      1. Update `values.yaml` by modifying the `replicaCount` appropriately.
      2. Apply the patch:
      ```shell
      helm upgrade <release> <chart> -f <values file>
      ```

=== "Imperatively"
      ```shell
      kubectl scale statefulsets <statefulsetset-name> --replicas=n
      ```

!!!note "Initial cluster size"
      **Jira**, **Confluence**, and **Crowd** all require manual configuration after the first pod is deployed and before scaling up to additional pods, therefore when you deploy the product only one pod (replica) is created. The initial number of pods that should be started at deployment of each product is set in the `replicaCount` variable found in the values.yaml and should always be kept as 1.
      For details on modifying the `cpu` and `memory` requirements of the `StatfuleSet` see section [Vertical Scaling](#vertical-scaling-adding-resources) below. Additional details on the resource requests and limits used by the `StatfulSet` can be found in [Resource requests and limits](REQUESTS_AND_LIMITS.md).

### Scaling Jira safely
At present there are issues relating to index replication with Jira when immediately scaling up by more than 1 pod at a time. See [Jira and horizontal scaling](../../troubleshooting/LIMITATIONS.md#jira-limitations-and-horizontal-scaling).

To overcome these issue you need to take the following approach:

* Prepare Jira for scaling by providing an index snapshot

  Make sure there's at least one snapshot file in
  `<shared-home>/export/indexsnapshots`. New pods will attempt to use
  these files to replicate issue index which is more reliable than
  copying index from pods directly. If you migrated shared home from an
  existing instance, snapshots should be available. If not, follow
  these steps to generate them before scaling Jira:

  1. Log into the Jira pod. There should be only one at this time
  1. Go to Admin -> System -> Advanced -> Indexing.
  1. There should be no errors on this page. If there are, you need to
  1  perform a full re-index before proceeding.
  1. Go to Index Recovery settings visible on the same page.
  1. Remember current settings
  1. Temporarly change the values: Set "Enable index recovery" to "ON". Under "Schdedule" choose "Advanced" and paste this cron expression into the input field: ~* * * * * ?~
  1. The above step will force the snapshot to be created every minute.
  1. Wait for the snapshot to be created. It will show as an archive in `<shared-home>/export/indexsnapshots`.
  1. Revert the settings to the remembered values but consider keeping the index recovery feature enabled.

* Using either the `declarative` or `impreative` approach scale the cluster by **1 pod only**
!!!warning "1 pod as a time!"
      
      Ensure you only scale up by 1 pod at a time!
  
* Make sure that the new pod is running and has a state of `Running` 
* Log into the Jira instance as the `admin` user via the service URL
* Navigate to `System` > `Troubleshooting and support tools`
* Under the `Instance health` tab make sure that `Cluster Index Replication` has a green tick, for example:   

![img.png](../../assets/images/good_cluster_index_replication.png)

* Having confirmed the index is healthy proceed with adding additional Jira pods to the cluster by following the same steps as above.

## Vertical scaling - adding resources
The resource `requests` and `limits` for a `StatefulSet` can be defined before product deployment or for deployments that are already running within the Kubernetes cluster. Take note that vertical scaling will result in the pod being re-created with the updated values.

### Prior to deployment
Before performing a helm install update the appropriate products `values.yaml` `container` stanza with the desired `requests` and `limits` values i.e. 
```yaml
 container: 
  limits:
    cpu: "4"
    memory: "4G"
  requests:
    cpu: "2"
    memory: "2G"
```

### Post deployment
For existing deployments the `requests` and `limits` values can be dynamically updated either declaratively or imperatively 

=== "Declaratively"
      This the preferred approach as it keeps the state of the cluster, and the helm charts themselves in sync.
      
      1. Update `values.yaml` appropriately
      2. Apply the patch:
      
      ```shell
      helm upgrade <release> <chart> -f <values file>
      ```

=== "Imperatively"
      Using `kubectl edit` on the appropriate `StatefulSet` the respective `cpu` and `memory` values can be modified. Saving the changes will then result in the existing product pod(s) being re-provisioned with the updated values.
