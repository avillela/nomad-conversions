# Tracetest on Nomad

**Assumption:** You have a Nomad/Vault/Consul HashiCorp environment running in a DC or locally using [HashiQube](https://github.com/avillela/hashiqube) set up. These jobspecs are set up assuming you are running Nomad locally via HashiQube. Please update accordingly for a setup in a Data Center.

## Converstion Process from Helm to Jobspec Template

This conversion was started by using the Tracetest Helm chart output to create the Tracetest jobspecs.

For details on how to convert Kubernetes manifests to Nomad Jobspecs, check out my blog post [here](https://medium.com/dev-genius/how-to-convert-kubernetes-manifests-into-nomad-jobspecs-7a58d2fa07a0).

Some additional info:

* Rendering the Tracetest Helm charts to Kubernetes YAML manifests:

    ```bash
    helm repo add kubeshop https://kubeshop.github.io/helm-charts
    helm repo update
    helm template tracetest kubeshop/tracetest > tracetest.yaml
    ```

* Base64 decode k8s secrets

    I do this so that I can find out the credentials to pass to Postgres when defining the `postgres.nomad` job. Right now, they're hard-coded. You will want to use Vault to store these credentials in a real-life scenario.

    ```bash
    # postgres password
    echo bEtjeTdlWHRIdg== | base64 -d

    # password
    echo bm90LXNlY3VyZS1kYXRhYmFzZS1wYXNzd29yZA== | base64 -d
    ```

## Deploying Tracetest on Nomad

Please note that this example sends traces to both Lightstep and Jaeger. In order to send traces to Lightstep, you will need:

* A Lightstep Account. You can create a free account [here](https://app.lightstep.com/signup/developer?signup_source=docs)
* A [Lightstep Access Token](https://docs.lightstep.com/docs/create-and-manage-access-tokens)

> **NOTE:** Jaeger is currently disabled from the OTel pipeline (need to fix a connectivity bug). We are sending traces to Lightstep only.

1. Start up [HashiQube](https://rubiksqube.com/#/) per the instuctions [here](https://github.com/avillela/hashiqube)

2. Set up Vault

    Follow the instructions [here](https://github.com/avillela/hashiqube#vault-setup). You will need this to add your Lightstep Access Token to Vault, so that you can send traces to Lightstep.

3. Add your Lightstep Access Token to Vault

    ```bash
    vault kv put kv/otel/o11y/lightstep ls_token="<LS_TOKEN>"
    ```

    Where `<LS_TOKEN>` is your [Lightstep Access Token](https://docs.lightstep.com/docs/create-and-manage-access-tokens)

4. Update `/etc/hosts`

    Add the following entries:

    ```text
    127.0.0.1  tracetest.localhost
    127.0.0.1  jaeger-ui.localhost
    127.0.0.1  go-server.localhost
    ```

    This will enable you to access various endpoints in this example.

5. Deploy to Nomad

    ```bash
    cd tracetest
    nomad job run -detach jobspec/traefik.nomad
    nomad job run -detach jobspec/jaeger.nomad
    nomad job run -detach jobspec/postgres.nomad
    nomad job run -detach jobspec/tracetest.nomad
    nomad job run -detach jobspec/otel-collector.nomad
    nomad job run -detach jobspec/go-server.nomad
    ```

6. Access the Tracetest and Jaeger UIs

    * Tracetest: `http://tracetest.localhost`
    * Jaeger: `http://jaeger-ui.localhost`

## Tracetest setup

Now that you've installed Tracetest, let's configure and run a test.

1. Configure Tracetest
    
    ```bash
    tracetest configure --endpoint http://tracetest.localhost --analytics=false
    ```

    This creates a `config.yml` file in the folder from which you run the `tracetest configure` command.

    > **NOTE:** There's already a `config.yml` file in this repo, so running the above command will overwrite it.

2. Run the sample test

    ```bash
    tracetest test run --definition tests/go-server-test.yml
    ```

    Sample output:

    ```bash
    ✔ Go Server Example (http://tracetest.localhost/test/QUQB0jc4g/run/1/test)
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
