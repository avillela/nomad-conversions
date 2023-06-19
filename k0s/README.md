# k0s in Nomad

This is an unfinished work. Unfortunately, while the k0s job does deploy in Nomad, if you check the logs, you'll notice that the Kubelet fails to start up, and well, without the Kubelet, you don't really have Kubernetes.

This is a work in progress, and if anyone has any insights into this issue, I am all ears!

## Run k0s using Docker

This is based on the official k0s docs for [running k0s with Docker](https://docs.k0sproject.io/v1.27.2+k0s.0/k0s-in-docker/#start-k0s).

```bash
docker run -it --rm \
    --name k0s --hostname k0s \
    --privileged \
    --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    -v /var/lib/k0s \
    -p 6443:6443 \
    -e ETCD_UNSUPPORTED_ARCH=arm \
    docker.io/k0sproject/k0s:v1.27.2-k0s.0 k0s controller --enable-worker --no-taint

# Check pod and node status
docker exec k0s kubectl get pods -A -w
docker exec k0s kubectl get nodes -w

# Get kubeconfig file so you can run kubectl
docker exec k0s cat /var/lib/k0s/pki/admin.conf
```

## Run k0s in Nomad

1. Deploy the job to Nomad

    ```bash
    nomad job run k0s/jobspec/k0s.nomad
    ```

2. Update your `kubeconfig` to access k0s

    This allows you to use `kubectl` to access your k0s cluster. You'll also need to have `kubectl` installed on your machine. Installation isntructions can be found [here](https://kubernetes.io/docs/tasks/tools/#kubectl).

    ```bash
    export ALLOCATION_ID=$(nomad job allocs -json k0s | jq -r '.[0].ID')

    # Add the k0s cluster to kubeconfig
    nomad alloc exec $ALLOCATION_ID cat /var/lib/k0s/pki/admin.conf > ~/.kube/config

    # Check readiness of k0s cluster (open each in new terminal window)
    kubectl get nodes -w
    kubectl get pods -A -w
    ```

3. Deploy Jaeger to the cluster

    >**NOTE:** This does not work, due to the Kubelet issue mentioned above. I mean, it creates the Kubernetes resources, but the deployment is perpetually left in a `pending` state.    

    ```bash
    # Deploy test app
    kubectl apply -f k0s/k8s_test/jaeger.yaml
    ```

4. Test Jaeger

    Set up port-forwarding

    ```bash
    # Set up port-forwarding
    kubectl port-forward -n opentelemetry svc/jaeger-all-in-one-ui 16686:16686
    ```

    Jaeger should be available at http://localhost:16686.