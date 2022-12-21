# Tracetest on Nomad

**Assumption:** You have a Nomad/Vault/Consul HashiCorp environment running in a DC or locally using [HashiQube](https://github.com/avillela/hashiqube) set up. These jobspecs are set up assuming you are running Nomad locally via HashiQube. Please update accordingly for a setup in a Data Center.

## Converstion Process from Helm to Jobspec Template

This conversion was started by using the Tracetest Helm chart output to create the Tracetest jobspecs.

1. Render helm charts:

    ```bash
    helm repo add kubeshop https://kubeshop.github.io/helm-charts
    helm repo update
    helm template tracetest kubeshop/tracetest > tracetest.yaml
    ```

2. Base64 decode k8s secrets:

    ```bash
    # postgrest-password
    echo bEtjeTdlWHRIdg== | base64 -d

    # password
    echo bm90LXNlY3VyZS1kYXRhYmFzZS1wYXNzd29yZA== | base64 -d
    ```

## Deploying Tracetest on Nomad

1. Start up [HashiQube](https://rubiksqube.com/#/) per the instuctions [here](https://github.com/avillela/hashiqube)

2. Update `/etc/hosts`

    Add the following entries:

    ```text
    127.0.0.1  tracetest.localhost
    127.0.0.1  jaeger-ui.localhost
    127.0.0.1  go-server.localhost
    ```

    This will allow you to access various UIs for this example.

3. Deploy to Nomad

    ```bash
    nomad job run -detach jobspec/traefik.nomad
    nomad job run -detach jobspec/jaeger.nomad
    nomad job run -detach jobspec/postgres.nomad
    nomad job run -detach jobspec/tracetest.nomad
    nomad job run -detach jobspec/otel-collector.nomad
    nomad job run -detach jobspec/go-server.nomad
    ```

4. Access the Tracetest and Jaeger UIs

    * Tracetest: `http://tracetest.localhost`
    * Jaeger: `http://jaeger-ui.localhost`

    > **NOTE:** Jaeger is currently disabled. We are sending traces to Lightstep only.

5. Create test in Tracetest

    Create a test from the following CURL command:

    ```bash
    curl http://go-server-svc.service.consul:9000
    ```

## Nukify Jobs

```bash
nomad job stop -purge traefik
nomad job stop -purge jaeger
nomad job stop -purge postgres
nomad job stop -purge tracetest
nomad job stop -purge otel-collector
nomad job stop -purge go-server
```

# Gotchas

When you first run a test in Tracetest, the UI doesn't necessarily refresh the `Trace` and `Test` tabs automagically, so to get around this, you might need to refresh these pages yourself manually until you see the trace diagram.