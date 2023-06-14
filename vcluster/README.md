# vCluster on Nomad


1. Grab the Helm Chart

    ```bash
    # Helm install
    helm repo add loft-sh https://charts.loft.sh
    helm repo update

    helm template vcluser-nomad loft-sh/vcluster-k8s -n vcluster-namespace > vcluster/resources/vcluster.yaml
    ```

2. Mappings

    * Deployment vcluster-nomad maps to ConfigMap vcluster-nomad-coredns
    * ConfigMap vcluser-nomad-init-manifests maps to nothing??
    * Deployment vcluser-nomad-api maps to Service vcluster-nomad-etcd
    * StatefulSet vcluster-nomad-etcd maps to vcluster-nomad-etcd-headless