# k0s in Nomad

## Run k0s using Docker

```bash
docker run -it --platform linux/amd64 \
    --name k0s --hostname k0s \
    --privileged \
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

```bash
export ALLOCATION_ID=$(nomad job allocs -json k0s | jq -r '.[0].ID')
nomad alloc exec $ALLOCATION_ID kubectl get ns

# To add to kubectl
nomad alloc exec $ALLOCATION_ID cat /var/lib/k0s/pki/admin.conf
```