# Adriana's Notes

## Run Tracetest

**THIS IS AN UGLY-ASS KLUDGE.** Here's the deal. When I deploy `tracetest.nomad` and `otel-collector.nomad` each won't start because it's waiting on the other. In order to solve this:
* Run a version of the OTel Collectro jobspec ([`otel-collector-no-tracetest.nomad`](otel-collector-no-tracetest.nomad)) which does not include Tracetest as part of the trace pipeline. This won't cause the collector to err out on startup.
* I set `change_mode = "noop"` in the `template` stanza for [`tracetest.nomad`](tracetest.nomad). This ensures that when I re-run [`otel-collector.nomad`](otel-collector.nomad) (the right version, with tracetest as part of the pipeline), it won't cause [`tracetest.nomad`](tracetest.nomad) to keep restarting.

I'm sure that there's a way less dumb way to do this, but I don't know what it is, so I'm all ears. :)

```bash
nomad job run -detach jobspec/traefik.nomad
nomad job run -detach jobspec/jaeger.nomad
nomad job run -detach jobspec/postgres.nomad
nomad job run -detach jobspec/tracetest.nomad
nomad job run -detach jobspec/otel-collector.nomad
nomad job run -detach jobspec/go-server.nomad
```

Once everything is up and running, run the version of the [OTel Collector jobspec](otel-collector.nomad) that has Tracetest as part of the trace pipeline:

```bash
nomad job stop -purge otel-collector
nomad job run -detach jobspec/otel-collector.nomad
```

## Nuke the jobs

```bash
nomad job stop -purge traefik
nomad job stop -purge jaeger
nomad job stop -purge postgres
nomad job stop -purge tracetest
nomad job stop -purge otel-collector
nomad job stop -purge go-server
```

## Notes

* When setting up tracetest test, reference internal HashiQube IP (need to change this to use Consul + static port)
* `go-server.nomad` needs to start after all the other stuff deploys (though once I change to Consul DNS + static port, should be okayin )