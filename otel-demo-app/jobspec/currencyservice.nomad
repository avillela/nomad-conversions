job "currencyservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "currencyservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 7001
      }
    }

    service {
      name = "currencyservice"
      // provider = "nomad"
      // tags = [
      //   "traefik.http.routers.currencyservice.rule=Host(`currencyservice.localhost`)",
      //   "traefik.http.routers.currencyservice.entrypoints=web",
      //   "traefik.http.routers.currencyservice.tls=false",
      //   "traefik.enable=true",
      // ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "currencyservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-currencyservice"

        ports = ["containerport"]
      }
      env {
        CURRENCY_SERVICE_PORT = "7001"
        // OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_RESOURCE_ATTRIBUTES = "service.name=currencyservice"
      }

      template {
        data = <<EOF
{{ range service "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOF
        destination = "local/env"
        env         = true
      }

      resources {
        cpu    = 55
        memory = 100
      }

    }
  }
}