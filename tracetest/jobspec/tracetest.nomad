job "tracetest" {

  datacenters = ["dc1"]

  group "svc" {
    count = 1


    network {

      port "tracetest-ui" {
        to = 11633
      }

      port "tracetest-grpc" {
        static = 21321
      }

    }

    service {
      name = "tracetest-ui"
      tags = [
        "traefik.http.routers.tracetest.rule=Host(`tracetest.localhost`)",
        "traefik.http.routers.tracetest.entrypoints=web",
        "traefik.http.routers.tracetest.tls=false",
        "traefik.enable=true",
      ]

      port = "tracetest-ui"

      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }

    }

    service {
      name = "tracetest-grpc"
      port = "tracetest-grpc"
      tags = [
        "traefik.tcp.routers.tracetest-grpc.rule=HostSNI(`*`)",
        "traefik.tcp.routers.tracetest-grpc.entrypoints=grpc",
        "traefik.enable=true",
      ]        


      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }


    task "svc" {
      driver = "docker"

      config {
        image = "kubeshop/tracetest:v0.8.2"
        image_pull_timeout = "25m"
        args = [
          "-config", 
          "/local/config.yaml"
        ]

        ports = ["tracetest-ui", "tracetest-grpc"]
      }

      restart {
        attempts = 10
        delay    = "15s"
        interval = "2m"
        mode     = "delay"
      }

      resources {
        cpu    = 100
        memory = 512
      }

      template {
        data   = <<EOF
postgresConnString: "host={{ range service "postgres-tracetest" }}{{ .Address }}{{ end }} user=tracetest password=not-secure-database-password  port={{ range service "postgres-tracetest" }}{{ .Port }}{{ end }} sslmode=disable"

poolingConfig:
  maxWaitTimeForTrace: 10s
  retryDelay: 1s

googleAnalytics:
  enabled: true

telemetry:
  dataStores:
    otlp:
      type: otlp
  exporters:
    collector:
      serviceName: tracetest
      sampling: 100 # 100%
      exporter:
        type: collector
        collector:
          endpoint: otelcol-grpc.service.consul:4317

server:
  telemetry:
    dataStore: otlp
    exporter: collector
    applicationExporter: collector
EOF

        // Use noop for now because of chicken-and-egg situation with tracetest and OTel Collector
        // change_mode = "noop"
        // change_mode   = "signal"
        // change_signal = "SIGHUP"
        destination = "/local/config.yaml"
      }
    }
  }
}