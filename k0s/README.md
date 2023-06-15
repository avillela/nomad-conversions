# k0s in Nomad

This is an unfinished work. Unfortunately, while the k0s job does deploy in Nomad, if you check the logs, you'll notice that the Kubelet fails to start up, and well, without the Kubelet, you don't really have Kubernetes.

This is a work in progress, and if anyone has any insights into this issue, I am all ears!

## Run k0s using Docker

This is based on the official k0s docs for [running k0s with Docker](https://docs.k0sproject.io/v1.27.2+k0s.0/k0s-in-docker/#start-k0s).

```bash
docker run -it --rm \
    --platform linux/amd64 \
    --name k0s --hostname k0s \
    --privileged \
    # -e ETCD_UNSUPPORTED_ARCH=arm64 \
    --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    -v /var/lib/k0s \
    -p 6443:6443 \
    docker.io/k0sproject/k0s:latest

# Try some kubectl commands
docker exec k0s kubectl get ns
docker exec k0s kubectl get svc

# Get kubeconfig file
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
    ```

3. Deploy Jaeger to the cluster

    >**NOTE:** This does not work, due to the Kubelet issue mentioned above. I mean, it creates the Kubernetes resources, but the deployment is perpetually left in a `pending` state.    

    ```bash
    # Run test
    kubectl apply -f k0s/k8s_test/jaeger.yaml
    ```