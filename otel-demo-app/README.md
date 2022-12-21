# OTel Demo App on Nomad

Please note that at the time of this writing, all Metrics and Traces are being sent to [Lightstep](https://app.lightstep.com). Learn more about how to configure the OTel Collector on Nomad to send OTel data to Lightstep [here](https://medium.com/tucows/just-in-time-nomad-running-the-opentelemetry-collector-on-hashicorp-nomad-with-hashiqube-4eaf009b8382).

For details on how to convert Kubernetes manifests to Nomad Jobspecs, check out my blog post [here](https://medium.com/dev-genius/how-to-convert-kubernetes-manifests-into-nomad-jobspecs-7a58d2fa07a0).

## Gotchas

* If you are using HashiQube, make sure that you allocate enough memory to Docker. I usually allocate 5 CPUs and 12GB RAM
* Unlike Docker Compose, you cannot specify service dependencies in Nomad; however, the jobs are set up so that they will keep trying to restart if there's a service that they depend on that's not up.
* Sometimes if a service keeps restarting (especially every minute or so), it's because it doesn't have enough memory allocated to it. This can also happen because it's waiting for a dependent service to start.

## Deployment Steps

This assumes that you have HashiCorp Nomad, Consul, and Vault running somewhere. For a quick and easy local dev setup of the aforementioned tools, I highly recommend using [HashiQube](https://github.com/avillela/hashiqube).


1. Add endpoints to `/etc/hosts`

    **Only if you're doing local dev **

    ```bash
    # For HashiQube
    127.0.0.1   traefik.localhost
    127.0.0.1   frontend.localhost
    127.0.0.1   otel-demo.localhost
    127.0.0.1   grafana.localhost
    127.0.0.1   jaeger-ui.localhost
    127.0.0.1   prometheus.localhost
    ```

2. Deploy Demo App services

    First, set memory over-subscription per [this article](https://developer.hashicorp.com/nomad/docs/commands/operator/scheduler/set-config#memory-oversubscription), to deal with any memory funny business from services. This is a one-time, cluster-wide setting.

    ```bash
    nomad operator scheduler set-config -memory-oversubscription true
    ```

    Now, deploy the services.

    ```bash
    nomad job run -detach otel-demo-app/jobspec/traefik.nomad
    nomad job run -detach otel-demo-app/jobspec/redis.nomad
    nomad job run -detach otel-demo-app/jobspec/ffspostgres.nomad
    nomad job run -detach otel-demo-app/jobspec/otel-collector.nomad
    nomad job run -detach otel-demo-app/jobspec/adservice.nomad
    nomad job run -detach otel-demo-app/jobspec/cartservice.nomad
    nomad job run -detach otel-demo-app/jobspec/currencyservice.nomad
    nomad job run -detach otel-demo-app/jobspec/emailservice.nomad
    nomad job run -detach otel-demo-app/jobspec/featureflagservice.nomad
    nomad job run -detach otel-demo-app/jobspec/paymentservice.nomad
    nomad job run -detach otel-demo-app/jobspec/productcatalogservice.nomad
    nomad job run -detach otel-demo-app/jobspec/quoteservice.nomad
    nomad job run -detach otel-demo-app/jobspec/shippingservice.nomad
    nomad job run -detach otel-demo-app/jobspec/checkoutservice.nomad
    nomad job run -detach otel-demo-app/jobspec/recommendationservice.nomad
    nomad job run -detach otel-demo-app/jobspec/frontend.nomad
    nomad job run -detach otel-demo-app/jobspec/loadgenerator.nomad
    nomad job run -detach otel-demo-app/jobspec/frontendproxy.nomad
    nomad job run -detach otel-demo-app/jobspec/grafana.nomad
    nomad job run -detach otel-demo-app/jobspec/jaeger.nomad
    nomad job run -detach otel-demo-app/jobspec/prometheus.nomad
    ```

    * Webstore             `http://otel-demo.localhost/`
    * Grafana              `http://otel-demo.localhost/grafana/` or `http://grafana.localhost`
    * Feature Flags UI     `http://otel-demo.localhost/feature/`
    * Load Generator UI    `http://otel-demo.localhost/loadgen/`
    * Jaeger UI            `http://otel-demo.localhost/jaeger/ui/` or `http://jaeger-ui.localhost`
    * Prometheus UI         `http://prometheus.localhost`

## Send Traces to Lightstep

By default, the OTel Demo App’s [OpenTelemetry Collector](https://docs.lightstep.com/otel/quick-start-collector) is configured to send Traces and Metrics to [Jaeger](https://jaeger.io), and [Prometheus](https://prometheus.io), respectively. For this demo, I also configured the Collector to send Traces and Metrics to [Lightstep](https://app.lightstep.com).

If you’d like to send Traces and Metrics to Lightstep, you’ll need to do the following:

1. Get a [Lightstep Access Token](https://docs.lightstep.com/docs/create-and-manage-access-tokens#create-an-access-token). (Make sure that you [sign up](https://app.lightstep.com/signup) for a [Lightstep](https://app.lightstep.com) account first, if you don’t already have one.)
2. Configure Vault by following the instructions [here](https://github.com/avillela/hashiqube#vault-setup).
3. Add your Lightstep Access Token to Vault by running the command:

  ```
  vault kv put kv/otel/o11y/lightstep ls_token="<LS_TOKEN>"
  ```

  Where `<LS_TOKEN>` is your [Lightstep Access Token](https://docs.lightstep.com/docs/create-and-manage-access-tokens#create-an-access-token)

  The OTel Collector job [pulls this value from Vault, into the Collector’s config YAML](https://github.com/avillela/nomad-conversions/blob/cefe9b9b12d84fb47be8aa5fc67b1b221b7b599b/otel-demo-app/jobspec/otel-collector.nomad-with-LS#L125-L128), so that we can also send Traces and Metrics to Lightstep:
  
  ```
  otlp/ls:
    endpoint: ingest.lightstep.com:443
    headers: 
      "lightstep-access-token": "{{ with secret "kv/data/otel/o11y/lightstep" }}{{ .Data.data.ls_token }}{{ end }}"
  ```

4. Run the version of the OTel Collector jobspec that contains the Lightstep configurations by replacing `nomad job run -detach otel-demo-app/jobspec/otel-collector.nomad` with `nomad job run -detach otel-demo-app/jobspec/otel-collector-with-LS.nomad`

## Nuke deployments

```bash
nomad job stop -purge traefik
nomad job stop -purge redis
nomad job stop -purge ffspostgres
nomad job stop -purge otel-collector
nomad job stop -purge adservice
nomad job stop -purge cartservice
nomad job stop -purge currencyservice
nomad job stop -purge emailservice
nomad job stop -purge featureflagservice
nomad job stop -purge paymentservice
nomad job stop -purge productcatalogservice
nomad job stop -purge quoteservice
nomad job stop -purge shippingservice
nomad job stop -purge checkoutservice
nomad job stop -purge recommendationservice
nomad job stop -purge frontend
nomad job stop -purge frontendproxy
nomad job stop -purge loadgenerator
nomad job stop -purge grafana
nomad job stop -purge jaeger
nomad job stop -purge prometheus
```

## Notes

### Communication Between Services

In order for services to communicate between each other, you need to use Consul templating. For example:

```hcl
template {
  data = <<EOF
{{ range service "redis-service" }}
REDIS_ADDR = "{{ .Address }}:{{ .Port }}"
{{ end }}

{{ range service "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}

EOF
  destination = "local/env"
  env         = true
}
```

This pulls the IP and port of a service based on its Consul name, and sets it ato an environment variable.

See reference [here](https://discuss.hashicorp.com/t/i-dont-understand-networking-between-services/24470/3).
