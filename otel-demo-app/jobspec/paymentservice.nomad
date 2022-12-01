job "paymentservice" {
  type        = "service"
  datacenters = ["dc1"]

  group "paymentservice" {
    count = 1

    network {
      mode = "host"

      port "containerport" {
        to = 50051
      }
    }

    service {
      name = "paymentservice"
      // provider = "nomad"
      // tags = [
      //   "traefik.http.routers.paymentservice.rule=Host(`paymentservice.localhost`)",
      //   "traefik.http.routers.paymentservice.entrypoints=web",
      //   "traefik.http.routers.paymentservice.tls=false",
      //   "traefik.enable=true",
      // ]

      port = "containerport"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "5s"
      }
    }

 
    task "paymentservice" {
      driver = "docker"
 
      config {
        image = "otel/demo:v1.1.0-paymentservice"

        ports = ["containerport"]
      }
      env {
        // OTEL_EXPORTER_OTLP_METRICS_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE = "cumulative"
        // OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://otel-collector-grpc.localhost:7233"
        OTEL_SERVICE_NAME = "paymentservice"
        PAYMENT_SERVICE_PORT = "50051"
      }

      template {
        data = <<EOF
{{ range service "ffspostgres-service" }}
DATABASE_URL = "ecto://ffs:ffs@{{ .Address }}:{{ .Port }}/ffs"
{{ end }}

{{ range service "otelcol-grpc" }}
OTEL_EXPORTER_OTLP_METRICS_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOF
        destination = "local/env"
        env         = true
      }

      // resources {
      //   cpu    = 500
      //   memory = 256
      // }

    }
  }
}