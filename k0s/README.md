# k0s in Nomad


Your eyes do not deceive you. You can run Kubernetes on Nomad with k0s! K0s is a lightweight Kubernetes distro. Check it out [here](https://docs.k0sproject.io/v1.27.2+k0s.0/).

If you want to play with this locally on a full-fledged HashiCorp Nomad environment (with Consul and Vault), then you'll need to deploy [Hashiqube](https://github.com/servian/hashiqube) first. I suggest that deploy [my fork of Hashiqube](https://github.com/avillela/hashiqube), as it has all the configs needed to make this work.

This little experiment wouldn't have been possible without the help of [Luiz Aoqui](https://github.com/lgfa29). For real. We did some serious pairing and troubleshooting on this one. The code in this folder based on Luiz's work [here](https://gist.github.com/lgfa29/145cc6063c1f491f1e6b3ed010bbcb45).

## Run k0s using Docker

This is based on the official k0s docs for [running k0s with Docker](https://docs.k0sproject.io/v1.27.2+k0s.0/k0s-in-docker/#start-k0s).

**NOTES:**
* If you are using Docker Desktop as the runtime, starting from 4.3.0 version it's using cgroups v2 in the VM that runs the engine. This means you have to add some extra flags to the above command to get kubelet and containerd to properly work with cgroups v2. More info [here](https://docs.k0sproject.io/v1.27.2+k0s.0/k0s-in-docker/#1-initiate-k0s).
* If you are running a Mac with a Silicon processor, you need to include the environment variable `-e ETCD_UNSUPPORTED_ARCH=arm`, as documented [here](https://docs.k0sproject.io/v1.27.2+k0s.0/troubleshooting/#k0s-controller-fails-on-arm-boxes).

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

# Try some kubectl commands
docker exec k0s kubectl get ns
docker exec k0s kubectl get svc

# Get kubeconfig file
docker exec k0s cat /var/lib/k0s/pki/admin.conf
```

## Running Nomad

If you prefer to run this example locally using the Nomad binary instead of on [Hashiqube](README.md#Running-the-examples), all you need to do is start up Nomad using command below:

```bash
# Assuming you're in the nomad-conversions root directory
nomad agent -dev -config k0s/config/config.hcl
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
